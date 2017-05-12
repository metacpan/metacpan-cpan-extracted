use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

#======================================================================
package XML::Pastor::Schema::Parser;

use Cwd;
use File::Spec;
use LWP::UserAgent;
use URI;
use URI::file;
use Class::Accessor;
use Data::HashArray;

use XML::LibXML;
use XML::Pastor::Stack;
use XML::Pastor::Schema;

use XML::Pastor::Util  qw(getAttributeHash sprint_xml_element);
use Scalar::Util qw(reftype);

our @ISA = qw(Class::Accessor);
XML::Pastor::Schema::Parser->mk_accessors(qw(model contextStack counter verbose));

#------------------------------------------------------------
sub new () {
	my $proto 	= shift;
	my $class	= ref($proto) || $proto;
	my $self = {@_};
	
	unless ($self->{model}) {
		$self->{model} = XML::Pastor::Schema::Model->new();
	}

	unless ($self->{contextStack}) {
		$self->{contextStack} = XML::Pastor::Stack->new();
	}
	
	return bless $self, $class;
}

#------------------------------------------------------------
# Parser context gets changed (by a PUSH on the stack) each time a new 
# schema file is processed (via includes and such). The context keeps track of 
# the parser state for that file.
# This method will return the top-most context for the parser.
#------------------------------------------------------------
sub context {
	my $self 	= shift;
	return $self->contextStack()->peek();
}


#------------------------------------------------------------
# Parse one or more schemas and create a schema model (internal Pastor 
# structure that represents the object model of the schemas.
#
# ARGUMENTS : 
# 	schema	: A single file name or an array of schema file names to be processed.  
#				If you give an array, the result is the same as parsing them one after the other
#			  They all accumulate in the parser 'model'.
# 
#------------------------------------------------------------
sub parse { &process;}

#------------------------------------------------------------
# An alias for 'process'. See Process.
#------------------------------------------------------------
sub processSchema { &process;}

#------------------------------------------------------------
sub process {		
	my $self 	= shift;	
	$self->_process(@_);		
}

#------------------------------------------------------------
# Called internally when an 'include' element is encountered in a schema.
#------------------------------------------------------------
sub includeSchema() {
	my $self=shift;
	
	$self->_process(@_, operation=>"include");
}

#------------------------------------------------------------
# Called internally when an 'import' element is encountered in a schema.
#------------------------------------------------------------
sub importSchema() {
	my $self=shift;
	
	$self->_process(@_, operation=>"import");		
#	die "Pastor : Schema IMPORT functionality not yet supported!\n";
}

#------------------------------------------------------------
# Called internally when an 'redefine' element is encountered in a schema.
#------------------------------------------------------------
sub redefineSchema() {
	my $self=shift;
	
	$self->_process(@_, operation=>"redefine");
}



#------------------------------------------------------------
# Parse a given schema into a LibXML DOM tree. 
#------------------------------------------------------------
sub parseToDom() {
	my $self 	= shift;
	my $args	= {@_};
	my $verbose	= $self->verbose || 0;
		
	my $schema_url 	= $args->{schema_url};
	my $schema_str	= $args->{schema_str};
	
	unless ( defined($schema_url) || defined ($schema_str) ) {
		die "Pastor: Parse Schema : Undefined schema !\n";
	}
	
	if (defined($schema_url)) {		
		print STDERR "Pastor : Fetching schema : '$schema_url' ...\n" if ($verbose >= 2);				
		my $ua = LWP::UserAgent->new;
  		$ua->agent("Pastor/0.1 ");

	  	# Create a request
  		my $req = HTTP::Request->new(GET => $schema_url);

		# Pass request to the user agent and get a response back
		my $res = $ua->request($req);

	  	# Check the outcome of the response
  		unless ($res->is_success) {
  			die "Pastor: Schema Parser : cannot GET from URL '$schema_url' : " . $res->status_line . "\n";
	  	}
  		
    	$schema_str = $res->content;
	}
						
	print STDERR "Pastor : Parsing schema ...\n" if ($verbose >= 2);
			
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_string($schema_str);
	
	print STDERR "Pastor : Parsing ended\n" if ($verbose >= 2);
	return $doc;			
}

#------------------------------------------------------------
# Parse a schema or an array of schemas into a Pastor schema model.
# Recurse if given an array. 
# see 'parse' for more details.
#------------------------------------------------------------
sub _process {
	my $self 	= shift;
	my $args	= {@_};
	my $verbose = $self->verbose;
	
	# We need a schema to process. Otherwise why are we here?
	defined($args->{schema}) or die "Pastor: Process Schema : Undefined schema!\n";

	# If the given 'schema' argument is an ARRAY, then
	# recurse on each of the items one by one.
	my $schema = $args->{schema};	
	if (ref($schema) =~ /ARRAY/) {
		foreach my $s (@$schema) {
			$args->{schema} = $s;
			$self->_process(%$args);
		}
		return $self->model();
	}
	
	print STDERR "Pastor : Processing schema : '$args->{schema}' ...\n" if($verbose >= 2);
	
	# By default the 'operation' is 'process', but it could have been 
	# 'include' for example.
	unless (defined($args->{operation})) {
		$args->{operation} = "process";
	}
	
	# chdir into the directory of the schema
	# TODO : How to handle HTTP or FTP URLs.
	$schema = $args->{schema};
	my $schema_url;
	my $file_possible;
SWITCH:	for ($schema) {
		# A URL
		/^(http|https|ftp|file):/i		and do { $schema_url = URI->new($schema); last SWITCH; };	
		
		# An XSD string
		/<\//							and do { $schema_url = undef; $args->{schema_str} = $schema; last SWITCH; };   
		
		# A file name
		OTHERWISE:						do { $schema_url = URI->new($schema); $file_possible=1; last SWITCH; };
	}
	
	if ( defined($schema_url) && defined($self->context()) && defined($self->context()->schema_url)) {
		$schema_url = $schema_url->abs($self->context()->schema_url);
	}elsif (defined($schema_url) && $file_possible) {
		$schema_url = $schema_url->abs(URI::file->cwd);
	}
	
	$args->{schema_url} = $schema_url;
	
	# Push a new CONTEXT on the stack.
	my $context = XML::Pastor::Schema::Context->new(%$args);		
	$self->contextStack->push($context);
	
	# Parse the schema into a DOM tree.
	my $schema_doc = $self->parseToDom(%$args);
	
	# Now start processing each node of the schema, starting from the ROOT element.	
	#_print_xml_doc($schema_doc);
	$self->_processNode($schema_doc);
	
	# Pop the context from the stack.	
	$self->contextStack->pop();
	
	print STDERR "Pastor : Process ENDED : '$args->{schema}' ...\n" if($verbose >= 2);		

	# return our resulting "model"
	return $self->model();	
}


#------------------------------------------------------------
# This routine is the heart of the parsing process. 
#
# It will "process" an element that is encountered in the
# schema and then it will recurse in order to process its children. 
#
# Keeps track of the parser state with a 'nodeStack' that holds the
# previously created model objects (Attribute, Element, ComplexType, SimpleType, Group, ...). 
# On the top of the stack will appear the object that was most recently created. 
#------------------------------------------------------------
sub _processNode {
	my $self=shift;
	my $node=shift;
	my $verbose = $self->verbose;
	
	# If we are given a DOM document, instead of an ELEMENT, then
	# just recurse with the ROOT element.
	if 	(UNIVERSAL::isa($node, "XML::LibXML::Document")) {
		return $self->_processNode($node->documentElement());
	}
	
	# We only process DOM elements here, nothing else means much to us.
	unless (UNIVERSAL::isa($node, "XML::LibXML::Element")) {
		return 0;
	}
	
	my $context 	= $self->context();
	my $model		= $self->model();
	my $nodeStack	= $context->nodeStack();
	my $obj			=undef;
	
	# TODO : Namespaces 
	my $name		= $node->localName;

	if ($verbose >= 10) {
		my $attribs = getAttributeHash($node);
		print STDERR "  $name ($attribs->{name})\n" ;	
	}
	
	# If the element name matches any string below, we'll do the corresponding action.
	SWITCH: for ($name){ 	# iterator = $_ (we'll do pattern matching on it)
		/^all$/				and do {	last SWITCH;};		
		/^annotation$/		and do {	last SWITCH;};	
		/^appinfo$/			and return 0;		# ignore children as well		
		/^attribute$/		and do { 	$obj=$self->_processAttribute($node);		last SWITCH;};
		/^attributeGroup$/	and do { 	$obj=$self->_processAttributeGroup($node);	last SWITCH;};
		/^choice$/			and do {	last SWITCH;};
		/^complexContent$/	and do {	last SWITCH;};		
		/^complexType$/		and do {	$obj=$self->_processComplexType($node);		last SWITCH;};
		/^documentation$/	and do { 	$obj=$self->_processDocumentation($node);	last SWITCH;};	
		/^element$/			and do {	$obj=$self->_processElement($node);			last SWITCH;};
		/^extension$/		and do {	$obj=$self->_processExtension($node);		last SWITCH;};		
		/^enumeration$/		and do {	$obj=$self->_processEnumeration($node);		last SWITCH;};
		/^field$/			and do {	return 0;};	# ignore children as well
		/^group$/			and do {	$obj=$self->_processGroup($node);			last SWITCH;};		
		/^import$/			and do {	$obj=$self->_processImport($node);			last SWITCH;};				
		/^include$/			and do {	$obj=$self->_processInclude($node);			last SWITCH;};		
		/^key$/				and do {	return 0;};	# ignore children as well			
		/^keyref$/			and do {	return 0;};	# ignore children as well
		/^list$/			and do {	$obj=$self->_processList($node);			last SWITCH;};		
		/^redefine$/		and do {	$obj=$self->_processRedefine($node);		last SWITCH;};						
		/^restriction$/		and do {	$obj=$self->_processRestriction($node);		last SWITCH;};
		/^schema$/			and do {	$obj=$self->_processSchemaNode($node);		last SWITCH;};
		/^selector$/		and do {	return 0;};	# ignore children as well	
		/^sequence$/		and do {	last SWITCH;};
		/^simpleContent$/	and do {	$obj=$self->_processSimpleContent($node);	last SWITCH;};		
		/^simpleType$/		and do {	$obj=$self->_processSimpleType($node);		last SWITCH;};
		/^unique$/			and do {	return 0;};		
		/^union$/			and do {	$obj=$self->_processUnion($node);		last SWITCH;};		
		OTHERWISE: 					{	$obj=$self->_processOtherNodes($node);};
	}
	
	# If the above created a model object, push it on the node stack within the current
	# context.	
	if (defined($obj)) {
		$nodeStack->push($obj);		
	}
	
	# RECURSE into children.
	my @children = grep {UNIVERSAL::isa($_, "XML::LibXML::Element")} $node->childNodes();
	foreach my $child (@children) {
		$self->_processNode($child);		
	}
	
	# CLEAN UP
	if (defined($obj)) {
		$self->_fixNameSpaces($obj, $node, ['type', 'base', 'ref']);
		
		# 'Union' must be post-processed
		if (UNIVERSAL::isa($obj, "XML::Pastor::Schema::Union")) {
			$self->_postProcessUnion($obj, $node);
		}

		# 'List' must be post-processed
		if (UNIVERSAL::isa($obj, "XML::Pastor::Schema::List")) {
			$self->_postProcessList($obj, $node);
		}
		
		$nodeStack->pop();
	}
	return 1;
}

#------------------------------------------------------------
# This routine is called whenever an 'attribute' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processAttribute {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();
	
	# Create an "Attribute" schema model object and set all fields with the 
	# attributes of this node.
	my $obj	 	= XML::Pastor::Schema::Attribute->new()->setFields(getAttributeHash($node));
	
	# Fix-up the scope and the name of the newly created object.
	$self->_fixUpObject($obj, $node);	
	
	# All attributes must have a name.
	unless ($obj->name()) {
		die "Pastor : Attribute must have a name!\n";
	}
	
	if ($obj->scope() =~ /local/io) {			
		# local attribute. Add it to the attribute list of the corresponding 
		# ComplexType or AttributeGroup that is closest to the top of the node stack in
		# the current context. 
		if (my $host=$context->findNode(class=>["XML::Pastor::Schema::ComplexType", 
												"XML::Pastor::Schema::AttributeGroup"])) {
			my $attribs=$host->attributes();
			my $attribInfo=$host->attributeInfo();						
			push @$attribs, $obj->name();						
			$attribInfo->{$obj->name()} = $obj;
		}else {
			# An 'orphan' attribute. What is it doing here? 
			die "Pastor : Attribute '" . $obj->name . "' found where unexpected!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";
		}
	}else {
		# Global attribute. Add it to the model.
		$self->model()->add(object=>$obj, operation=>$context->operation());
	}
	
	# Return the model object to be pushed on the node stack of the current context. 	
	return $obj;	
}

#------------------------------------------------------------
# This routine is called whenever an 'attributeGroup' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processAttributeGroup {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();	
	
	# Create an "AttributeGroup" schema model object and set all fields with the 
	# attributes of this node.
	my $obj	 	= XML::Pastor::Schema::AttributeGroup->new()->setFields(getAttributeHash($node));

	# Fix-up the scope and the name of the newly created object.	
	$self->_fixUpObject($obj, $node);	
	
	unless ($obj->name()) {
		die "Pastor : Attribute Group must have a name!\n" . sprint_xml_element($node) . "\n";
	}
		
	if ($obj->scope() =~ /local/io) {
		# Local scope.Add it to the attribute list of the corresponding 
		# ComplexType that is closest to the top of the node stack in
		# the current context. 
		if (my $host=$context->findNode(class=>["XML::Pastor::Schema::ComplexType",  "XML::Pastor::Schema::AttributeGroup"])) {
			my $attribs=$host->attributes();
			my $attribInfo=$host->attributeInfo();						
			push @$attribs, $obj->name();						
			$attribInfo->{$obj->name()} = $obj;
		}else {
			# An 'orphan' attribute group. What is it doing here? 			
			die "Pastor : Element '" . $obj->name . "' found where unexpected!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";	
		}		
	}else {
		# Global attribute group. Add it to the model.
		$self->model()->add(object=>$obj, operation=>$context->operation());
	}
	
	# Return the model object to be pushed on the node stack of the current context. 	
	return $obj;	
}

#------------------------------------------------------------
# This routine is called whenever an 'element' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processElement {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();		
	
	# Create an "Element" schema model object and set all fields with the 
	# attributes of this node.
	my $obj	 	= XML::Pastor::Schema::Element->new()->setFields(getAttributeHash($node));

	# Fix-up the scope and the name of the newly created object.		
	$self->_fixUpObject($obj, $node);	
	unless ($obj->name()) {
		die "Pastor : Element must have a name!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";	
	}
		
	if ($obj->scope() =~ /local/io) {			
		# local element. 
		# Add it to the element list of the corresponding 
		# ComplexType that is closest to the top of the node stack in
		# the current context. 
		if (my $host=$context->findNode(class=>["XML::Pastor::Schema::ComplexType", "XML::Pastor::Schema::Group"])) {
			my $elems=$host->elements();
			my $elemInfo=$host->elementInfo();						
			push @$elems, $obj->name();						
			$elemInfo->{$obj->name()} = $obj;
		}else {
			# An 'orphan' element. What is it doing here? 						
			die "Pastor : Element '" . $obj->name . "' found where unexpected!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";	
		}
	}else {
		# Global element. Add it to the model.
		$self->model()->add(object=>$obj,operation=>$context->operation());
	}
	
	# Return the model object to be pushed on the node stack of the current context. 	
	return $obj;	
}

#------------------------------------------------------------
# This routine is called whenever a 'group' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processGroup {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();		
	
	# Create an "Group" schema model object and set all fields with the 
	# attributes of this node.
	my $obj	 	= XML::Pastor::Schema::Group->new()->setFields(getAttributeHash($node));

	# Fix-up the scope and the name of the newly created object.			
	$self->_fixUpObject($obj, $node);	
	unless ($obj->name()) {
		die "Pastor : Group must have a name!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";	
	}
		
	if ($obj->scope() =~ /local/io) {			
		# local scope.
		# Add it to the element list of the corresponding 
		# ComplexType that is closest to the top of the node stack in
		# the current context. 		
		if (my $host=$context->findNode(class=>"XML::Pastor::Schema::ComplexType")) {
			my $elems=$host->elements();
			my $elemInfo=$host->elementInfo();						
			push @$elems, $obj->name();						
			$elemInfo->{$obj->name()} = $obj;
		}else {
			# An 'orphan' group. What is it doing here? 									
			die "Pastor : Element '" . $obj->name . "' found where unexpected!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";	
		}
	}else {
		# Global group. Add it to the model.
		$self->model()->add(object=>$obj,operation=>$context->operation());
	}
	
	# Return the model object to be pushed on the node stack of the current context. 
	return $obj;	
}


#------------------------------------------------------------
# This routine is called whenever an 'documentation' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processDocumentation {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);
	my $value	= $attribs->{value};
	
	# Find the top-most SimpleType model object closest to the top of the node-stack 
	# of the current context. This will become our 'host' object.
	if (my $host=$context->findNode(class=>"XML::Pastor::Schema::Object")) {
		# If this is the first enumeration. Create the array. 
		unless (defined($host->documentation())) {
			$host->documentation(Data::HashArray->new());
		}
		
		# Create the nex documentation
		my $doc = XML::Pastor::Schema::Documentation->new();
		$doc->setFields($attribs);
		$doc->text($node->textContent());
		
		my $docs = $host->documentation;
		push @$docs, $doc;		
	}else {
		# What is an 'documentation' doing outside the scope of a 'Schema::Object'?
		die "Pastor : Documentation found where unexpected!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";;	
	}
	
	# Nothing will get pushed on the node-stack.	
	return undef;
}

#------------------------------------------------------------
# This routine is called whenever an 'enumeration' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processEnumeration {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);
	my $value	= $attribs->{value};
	
	# Find the top-most SimpleType model object closest to the top of the node-stack 
	# of the current context. This will become our 'host' object.
	if (my $host=$context->findNode(class=>"XML::Pastor::Schema::SimpleType")) {
		# If this is the first enumeration. Create the hash. 
		unless (defined($host->enumeration())) {
			$host->enumeration({})
		}
		# register this enumeration value.  
		my $enums=$host->enumeration();
		$enums->{$value}=1;
	}else {
		# What is an 'enumeration' doing outside the scope of a 'SimpleType'?
		die "Pastor : Enumeration found where unexpected!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";;	
	}
	
	# Nothing will get pushed on the node-stack.	
	return undef;
}



#------------------------------------------------------------
# This routine is called whenever an 'extension' element is encountered 
# in the schema being processed.
#
# Extension is easy. We don't create any object to be pushed on the node stack.
# It is effectively ignored except for its attributes which are copied onto
# the Complex or Simple Type object that is closest to the top of the node stack.
#------------------------------------------------------------
sub _processExtension {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);

	# in the schema being processed.	
	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::ComplexType", "XML::Pastor::Schema::SimpleType"])) {
		$host->setFields($attribs);
		$host->derivedBy("extension");
	}else {
		die "Pastor : Extension found where unexpected!\n" . sprint_xml_element($node->parentNode()) . "\n";	
	}
	
	# Nothing will get pushed on the node-stack.	
	return undef;	
}

#------------------------------------------------------------
# This routine is called whenever a 'union' element is encountered 
# in the schema being processed.
#
#------------------------------------------------------------
sub _processUnion {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			

	# Create a "Union" schema model object and set all fields with the 
	# attributes of this node.
	my $obj	 	= XML::Pastor::Schema::Union->new()->setFields(getAttributeHash($node));

    $self->_fixMemberTypesNameSpace($obj, $node);	# Patch by IKEGAMI

	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::SimpleType"])) {
		$host->base("Union|http://www.w3.org/2001/XMLSchema");
		$host->derivedBy("union");		
	}else {
		die "Pastor : 'union' found where unexpected!\n" . sprint_xml_element($node->parentNode()) . "\n";	
	}		
		
	# This object will get pushed on the node-stack.	
	return $obj;	
}

#------------------------------------------------------------
sub _postProcessUnion {
	my $self 	= shift;
	my $obj 	= shift;	
	my $node 	= shift;	
	my $context = $self->context();			
	
	# in the schema being processed.	
	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::SimpleType"])) {
		$host->setFields(%$obj);
	}
	return $obj;		
}


#------------------------------------------------------------
# This routine is called whenever a 'list' element is encountered 
# in the schema being processed.
#
#------------------------------------------------------------
sub _processList {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			

	# Create a "List" schema model object and set all fields with the 
	# attributes of this node.
	my $obj	 	= XML::Pastor::Schema::List->new()->setFields(getAttributeHash($node));

	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::SimpleType"])) {
		$host->base("List|http://www.w3.org/2001/XMLSchema");
		$host->derivedBy("list");				
	}else {
		die "Pastor : 'list' found where unexpected!\n" . sprint_xml_element($node->parentNode()) . "\n";	
	}		
	
	# This object will get pushed on the node-stack.	
	return $obj;	
}

#------------------------------------------------------------
sub _postProcessList {
	my $self 	= shift;
	my $obj 	= shift;	
	my $node 	= shift;	
	my $context = $self->context();			
	
	# in the schema being processed.	
	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::SimpleType"])) {
		$host->setFields(%$obj);
	}
	return $obj;		
}

#------------------------------------------------------------
# This routine is called whenever an 'include' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processInclude {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);	
	my $schemaLocation = $attribs->{schemaLocation};

	# "inlude" element must be a child of the schema element. It can't be deeper. 
	unless (UNIVERSAL::isa($context->topNode(), "XML::Pastor::Schema")) {
		die "Pastor : Schema INCLUDE must be global!\n" . sprint_xml_element($node) . "\n";
	}
	
	# Just call the method that does the inclusion. 	
	$self->includeSchema(schema=>$schemaLocation);
	
	# Nothing will get pushed on the node-stack.	
	return undef;
}

#------------------------------------------------------------
# This routine is called whenever an 'import' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processImport {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);	
	my $schemaLocation = $attribs->{schemaLocation};

	# "import" element must be a child of the schema element. It can't be deeper. 
	unless (UNIVERSAL::isa($context->topNode(), "XML::Pastor::Schema")) {
		die "Pastor : Schema IMPORT must be global!\n";
	}
	
	# Just call the method that does the import. 		
	$self->importSchema(schema=>$schemaLocation);
	
	# Nothing will get pushed on the node-stack.
	return undef;
}

#------------------------------------------------------------
# This routine is called whenever an 'redfine' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processRedefine {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);	
	my $schemaLocation = $attribs->{schemaLocation};

	# "redefine" element must be a child of the schema element. It can't be deeper. 
	unless (UNIVERSAL::isa($context->topNode(), "XML::Pastor::Schema")) {
		die "Pastor : Schema REPLACE must be global!\n" . sprint_xml_element($node) . "\n";
	}
	
	# Just call the method that does the redefine. 			
	$self->redefineSchema(schema=>$schemaLocation);
	
	# Nothing will get pushed on the node-stack.
	return undef;
}

#------------------------------------------------------------
# This routine is called whenever an 'restriction' element is encountered 
# in the schema being processed.
#
# "Restriction" is easy. We don't create any object to be pushed on the node stack.
# It is effectively ignored except for its attributes which are copied onto
# the Complex or Simple Type object that is closest to the top of the node stack.
#------------------------------------------------------------
sub _processRestriction {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);
	
	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::SimpleType", "XML::Pastor::Schema::ComplexType"])) {
		$host->setFields($attribs);
		$host->derivedBy("restriction");
	}else {
		die "Pastor : Restriction found where unexpected!\n" . sprint_xml_element($node->parentNode()) . "\n";	
	}
	return undef;
}


#------------------------------------------------------------
# This routine is called whenever an 'schema' element is encountered 
# in the schema being processed.
#
# Normally this should occur only once and first in a given schema file. 
#------------------------------------------------------------
sub _processSchemaNode {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();			
	my $obj	 	= XML::Pastor::Schema->new()->setFields(getAttributeHash($node));
			
	if ($context->nodeStack->count()) {
		die "Pastor : Schema elements cannot be nested!\n";
	}
	
	my $nsUri = undef;
	if ($obj->targetNamespace) {
		# Schema defines a targetNamspace. It's easy.
		$nsUri = $obj->targetNamespace();
	}else{
		# This schema doesn't define a targetNamespace itself. It probably means its included. 
		# But perhaps we can get it from the previous schema.
		my $cstack= $self->contextStack;
		if ($cstack->count > 1) {
			# Lucky, we've got one.
			my $prevContext = $cstack->[1];	# This is the one before the top. Becuase a push is actually unshift.
			$nsUri = $prevContext->targetNamespace();
		}else {
			# Hmmm. This is a truely no-namespace schema.
			$nsUri = "";
		}
		
	}

	$context->targetNamespace($nsUri);	
	$self->model->addNamespaceUri($nsUri);
	
	return $obj;
}


#------------------------------------------------------------
# This routine is called whenever an 'simpleType' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processSimpleContent {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();				
	
	# if this is a local definition, then our host element/attribute must be of this type
	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::ComplexType", 
											])) {
		$host->setFields({isSimpleContent=>1});
	}

	# Nothing to add to the model.

	# Nothing will get pushed on the node-stack.
	return undef;

}


#------------------------------------------------------------
# This routine is called whenever an 'simpleType' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processSimpleType {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();				
	
	# Create an "SimpleType" schema model object and set all fields with the 
	# attributes of this node.	
	my $obj	 	= XML::Pastor::Schema::SimpleType->new()->setFields(getAttributeHash($node));

	# Fix-up the scope and the name of the newly created object.	
	$self->_fixUpObject($obj, $node);	
	unless ($obj->name()) {
		die "Pastor : SimpleType must have a name!\n";
	}

	# if this is a local definition, then our host element/attribute must be of this type
	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::Attribute", 
											"XML::Pastor::Schema::Element", 
											"XML::Pastor::Schema::Union", 
											"XML::Pastor::Schema::List", 											
											])) {
		if ( 	UNIVERSAL::isa($host, "XML::Pastor::Schema::Attribute") ||
     			UNIVERSAL::isa($host, "XML::Pastor::Schema::Element") ) {			
			$host->setFields({type=>$obj->name()});
     	}elsif (UNIVERSAL::isa($host, "XML::Pastor::Schema::Union")) {
			my $mbt=$host->memberTypes;
			$mbt .= ' ' if ($mbt);
			$mbt .= $obj->name();	
			$host->memberTypes($mbt);
     	}elsif (UNIVERSAL::isa($host, "XML::Pastor::Schema::List")) {
     		$host->itemType($obj->name);
     	}
	}

	# SimpleTypes are always added to the model, regardless of local or global scope.
	$self->model()->add(object=>$obj, operation=>$context->operation());
	
	# Return the model object to be pushed on the node stack of the current context. 	
	return $obj;
}

#------------------------------------------------------------
# This routine is called whenever an 'complexType' element is encountered 
# in the schema being processed.
#------------------------------------------------------------
sub _processComplexType {
	my $self 	= shift;
	my $node 	= shift;	
	my $context = $self->context();				
	
	# Create an "ComplexType" schema model object and set all fields with the 
	# attributes of this node.		
	my $obj	 	= XML::Pastor::Schema::ComplexType->new()->setFields(getAttributeHash($node));

	# Fix-up the scope and the name of the newly created object.		
	$self->_fixUpObject($obj, $node);	
	unless ($obj->name()) {
		die "Pastor : ComplexType must have a name!\n";
	}
	
	# if this is a local definition, then our host element must be of this type
	if (my $host=$context->findNode(class=>["XML::Pastor::Schema::Element"])) {
		$host->setFields({type=>$obj->name()});
	}

	# ComplexTypes are always added to the model, regardless of local or global scope.	
	$self->model()->add(object=>$obj, %$context);
	
	# Return the model object to be pushed on the node stack of the current context. 		
	return $obj;	
}

#------------------------------------------------------------
# This routine is called whenever any other (unidentified) element is encountered 
# in the schema being processed.
#
# One type of such elements are those who just have a 'value' attribute. In that 
# case we treat it as just an attribute of the top-most object in the nodeStack.
# 
# Any other element will cause a FATAL error as it is unrecognized.
#------------------------------------------------------------
sub _processOtherNodes {
	my $self 	= shift;
	my $node 	= shift;	
	my $name	= $node->localName();
	my $context = $self->context();			
	my $attribs	= getAttributeHash($node);	
	my $value 	= $attribs->{value};
	
	if (defined($value)) {
		# Element with a 'value' attribute
		unless ($context->nodeStack()->count()) {
			die "Pastor : Element '$name' unexpected as root element in schema!\n";
		}elsif (UNIVERSAL::isa($context->topNode(), "XML::Pastor::Schema")) {
			die "Pastor : Element '$name' cannot be global in schema!\n" . sprint_xml_element($node) . "\n";;	
		}else {
			# Just set the value as a field in the host object
			if (my $host=$context->findNode(class=>"XML::Pastor::Schema::Object")) {
				# Multiplicity is allowed.
				my $oldValue = $host->{$name};
				
				if (defined($oldValue)) {
					my $rt =reftype($oldValue);
					unless (defined($rt) and (reftype($oldValue) eq 'ARRAY')) {
						$oldValue = [$oldValue];
						$host->setFields({$name=>$oldValue});									
					}
					push @$oldValue, $value;					
				}else {
					$host->setFields({$name=>$value});				
				}
				
			}else {
				die "Pastor : Don't know what to do with element '$name'\n" . sprint_xml_element($node->parentNode() || $node) . "\n";				
			}
		}		
	}else {
		die "Pastor : Unexpected element '$name' in schema!\n" . sprint_xml_element($node->parentNode() || $node) . "\n";	
	}	
	
	# Nothing will get pushed on the node-stack.
	return undef;
}

#------------------------------------------------------------
# This routine is called for most newly created model objects. 
#
# It fixes the 'scope' of the given object by looking at the nodeSstack. 
# If we are just within a "schema" element, then we are in "global" context.
# Othewise we must be in local context. 
#
# It also autogenerates a name for objects when there isn't one already given
# as an attribute. This is handy for elements with a 'ref' attribute what without a name.
#
# It is also handy for ComplexTypes that are anonymously defined locally. Since
# we globalize type definitions in all cases. We need distunguashible names for them.
#
#------------------------------------------------------------
sub _fixUpObject {
	my $self	= shift;
	my $obj		= shift;
	my $node	= shift;
	my $context	= $self->context();
	
	unless ($context->nodeStack()->count() || UNIVERSAL::isa($obj, "XML::Pastor::Schema")) {
		die "Pastor Unexpected root element '" . $obj->name() . "' in schema. This may not be a real XSD schema!" 
	}
	
	if (UNIVERSAL::isa($context->topNode(), "XML::Pastor::Schema")) {
		# If we are immediatly underneath a schema element, 
		# this means we are in a global scope		
		$obj->scope("global") 
	}else {		
		# Otherwise we are in LOCAL context.
		$obj->scope("local");
		if ($obj->ref() && !$obj->name()) {
			# No name but this a reference.
			# Just set the name to the reference.
			$obj->name($obj->ref());
			$obj->nameIsAutoGenerated(1);
		}elsif (!$obj->name() && 
					(
					$context->findNode(class=>"XML::Pastor::Schema::Union") ||
					$context->findNode(class=>"XML::Pastor::Schema::List")					
					)
				) 
			{
			# This is a union/list item. Just use the auto-incrementer.
			unless (defined($self->counter)) {
				$self->counter(0);
			}
			$self->counter($self->counter + 1);
			my $name = "item_" . sprintf("%04d", $self->counter);
			my $path = $context->namePath(separator=>"_");						
			$name 	 = $path . "_" . $name if ($path);
			
			$obj->name($name);
			$obj->nameIsAutoGenerated(1);			
		}elsif (!$obj->name()) {
			# No name, no reference, not union/list member. Out of luck.
			# Set the name to the concationation of all non-autogenerated 
			# names in the context (bottom to top) with an underscore separator.
			$obj->name($context->namePath(separator=>"_"));
			$obj->nameIsAutoGenerated(1);			
		}
	}
	
	if (UNIVERSAL::can($obj, 'targetNamespace')) {
		$obj->targetNamespace($context->targetNamespace) if ($context->targetNamespace);
	}	
	
	$self->_fixNameSpaces($obj, $node, ['name'], localize => 1); 
	return $obj;
}

#------------------------------------------------------------
# This routine is called for most newly created model objects. 
#
# It fixes the name space URI on given fields of the object. 
# for example "xs:string" will become "string|http://www.w3.org/2001/XMLSchema".
#
# This way, we don't deal with the namespace prefix but the NS URI itself.
#
#------------------------------------------------------------
sub _fixNameSpaces {
	my $self	= shift;
	my $obj		= shift;
	my $node	= shift;
	my $fields	= shift;
	my $opts	= {@_};
	my $localize= $opts->{localize} || 0;
	my $context	= $self->context();
	my $verbose	= 0;
	
	foreach my $field (@$fields) {
		my $uri = undef;
		my $v	=$obj->{$field};
		print STDERR "Fixing up namespaces for '$field' ('$v')...\n" if ($verbose >=9);	
		
		if ($v && ($v =~ /\|/)) {
			# Do nothing. There is already a namespace in there.
		}elsif ($v && ($v =~ /:/o)) {
			# There is a namesapce prefix in there.
			my ($prefix, $local) = split /:/, $v, 2;
			$uri = $node->lookupNamespaceURI($prefix);
			if ($uri) {
				if ($localize) {
					$obj->{$field} = $local;
					$obj->{targetNamespace} = $uri;
				}else {
					$obj->{$field} = "$local|$uri";
				}
			}
		}elsif ($v) {
			if ($localize) {
				$obj->{targetNamespace} = $context->targetNamespace();
			}elsif (my $uri = $context->targetNamespace()) { 
				$obj->{$field} = "$v|$uri";
			}
		}	
	}
	return $obj;
}	

#------------------------------------------------------------
# Taken from the patch by IKEGAMI on RT bug report #44760: Namespaces broken for xs:union memberTypes
#------------------------------------------------------------
sub _fixMemberTypesNameSpace {
	my $self        = shift;
    my $obj         = shift;
    my $node        = shift;
    my $opts        = {@_};
    my $localize= $opts->{localize} || 0;
    my $context     = $self->context();
    my $verbose     = $self->verbose || 0;

    my @mbts = split ' ', $obj->memberTypes;
    print STDERR "Fixing up namespaces for 'memberTypes' ('@mbts')...\n" if ($verbose >=9); 
    foreach my $mbt (@mbts) {
    	if ($mbt && ($mbt =~ /\|/)) {
          # Do nothing. There is already a namespace in there.
        }elsif ($mbt && ($mbt =~ /:/o)) {
          # There is a namesapce prefix in there.
          my ($prefix, $local) = split /:/, $mbt, 2;
          my $uri = $node->lookupNamespaceURI($prefix);
          if ($uri) {
            $mbt = "$local|$uri";
          }
       }elsif ($mbt) {
          if (my $uri = $context->targetNamespace()) { 
             $mbt = "$mbt|$uri";
          }
       }       
    }
    $obj->memberTypes(join ' ', @mbts);
    return $obj;
}      


1;

__END__

=head1 NAME

B<XML::Pastor::Schema::Parser> - Module for parsing a W3C XSD schema into an internal schema model.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<Class::Accessor>. 

=head1 DESCRIPTION

B<XML::Pastor::Schema::Parse> is used internally by L<XML::Pastor> for parsing a W3C schema into an
internal schema model (L<XML::Pastor::Schema::Model>). 

The parsing is done with the L</parse()> method. The schema is not parsed directly. Instead, L<XML::LibXML> is used
to first parse the schema into a DOM tree (since the W3C schema is itself represented in XML). Then, the DOM tree 
hence obtained is traversed recursively in order to construct the B<schema model> which is somewhat like a parse-tree. 

For more information on the B<schema model> produced, please refer to L<XML::Pastor::Schema::Model>.

=head1 METHODS

=head2 CONSTRUCTORS
 
=head4 new() 

  XML::Pastor::Schema::Parser->new(%fields)

B<CONSTRUCTOR>.

The new() constructor method instantiates a new object. It is inheritable. 
  
Any -named- fields that are passed as parameters are initialized to those values within
the newly created object. 

The B<new()> method will create a I<model> and a I<contextStack> if it is not passed values for those fields.

.

=head2 ACCESSORS
 
=head4 contextStack() 

A stack (of type L<XML::Pastor::Stack>) that keeps track of the current context. Every time a new schema
is opened for parsing (as a result of I<include> or I<redefine> statements), a new context is pushed on the stack.

Each context is of type L<XML::Pastor::Schema::Context>. Basically, the context keeps track of the DOM nodes that are 
being processed before they are inserted into the I<model>.

=head4 counter() 

A simple integer counter that keeps track of the count that is attributed to implicit nodes (typically simple types) that need
to be named. Whenever such a node needs to be named, the counter is used to generate a unique name before being incremented.
  
=head4 model() 

The schema model (of type L<XML::Pastor::Schema::Model>) that is currently being constructed. The I<model> is the result of the
parsing operation and it is the internal reprsentation (information set) of a series of schemas that are related to each other
(via I<include>s or similar means).

=head2 OTHER METHODS

=head4 parse()
   
  $model = $parser->parse(%options);

B<OBJECT METHOD>.

This method accomplishes the major role of this module. Namely, it parses a W3C XSD schema
into an internal structure called a B<schema model>. 

Example:

  my $parser = XML::Pastor::Schema::Parser->new();
  my $model  = $parser->parse(schema=>'/tmp/schemas/country.xsd');
  
The W3C schema, which is in XML itself, is not parsed directly. Instead, it is parsed first into a DOM tree with 
the help of L<XML::LibXML>. Then, a recursive algorithm is used for constructing a B<schema model> which is an
internal structure.

For more information on the B<schema model> produced, please refer to L<XML::Pastor::Schema::Model>.

OPTIONS

=over 

=item schema

This is the file name or the URL to the B<W3C XSD schema> file to be processed. Experimentally, it can also be a string
containing schema XSD. 

Be careful about the paths that are mentioned for any included schemas though. If these are relative, they
will be taken realtive to the current schema being processed. In the case of a schema string, the resolution
of relative paths for the included schemas is undefined.

Currently, it is also possible to pass an array reference to this parameter, in which case the schemas will be processed in order
and merged to the same model for code generation. Just make sure you don't have name collisions in the schemas though.

=back


.

=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any. 
Note that, although some testing was done prior to releasing the module, this should still be considered alpha code. 
So use it at your own risk.

Note that there may be other bugs or limitations that the author is not aware of.

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>


=head1 COPYRIGHT

  Copyright (C) 2006-2007 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

See also L<XML::Pastor>, L<XML::Pastor::ComplexType>, L<XML::Pastor::SimpleType>

And if you are curious about the implementation, see L<XML::Pastor::Schema::Model>, L<XML::Pastor:Generator>


=cut
