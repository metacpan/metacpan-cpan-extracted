use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

#=======================================================
package XML::Pastor::Generator;

use Data::Dumper;
use IO::File;
use File::Path;
use File::Spec;
use Class::Accessor;
use XML::Pastor::Util qw(mergeHash module_path);

our @ISA = qw(Class::Accessor);

#--------------------------------------------
sub new {
	my $proto 	= shift;
	my $class	= ref($proto) || $proto;
	my $self = {@_};	
	return bless $self, $class;
}

#--------------------------------------------
# Generate Perl code from a given schema model (produced by the Parser) by the
# argument 'model'.
#
# Understands several modes of functioning => generate, eval, return
# 
# mode = 'offline' : Generate perl code and write it to one or more module files.
# mode = 'eval'     : Generate perl code and 'evaluate' it in situ without writing out to any file.
# mode = 'return'   : Generate perl code and return the resulting string to the caller.
# 
# Understands also two styles:
# style = 'single'	: Generate one big chunk of code with all the packages in it. 
#						Note that this is the forced case when mode is 'eval' or 'return'
# style = 'multiple': Generate one chunk of code for each class and write it out to multiple 
#						module files within the 'destination' directory.
#----------------------------------------------------------------------
sub generate {
	my $self 	= shift;
	my $args	= {@_};
	my $model	= $args->{model} or die "Pastor: Code generation requires a 'model'!\n";
	my $mode	= $args->{mode};
	if ( ($mode =~ /eval/) || ($mode =~ /return/)) {
		$args->{style} = "single";	# force single module generation
	}
	my $style	= $args->{style};
	my $destination		= $args->{destination} || '/tmp/lib/perl/';
	my $verbose	= $self->{verbose} || 0;
	
	# If 'destination' doesn't end with a trailing slash, add one.
	if ($destination && ($destination !~ /\/$/) ) {
		$destination .= '/';
	}
	$args->{destination}= $destination;

	my $class_prefix = $args->{class_prefix} || '';	
	while (($class_prefix) && ($class_prefix !~ /::$/)) {
		$class_prefix .= ':';
	}
	$args->{metaModule} 		= $class_prefix . "Pastor::Meta"; 

	
	print STDERR "\nGenerating code...\n" if ($verbose >=2);
	if ($style =~ /single/) {
		$self->_generateSingle(%$args);
	}else {
		$self->_generateMultiple(%$args);		
	}
}

#--------------------------------------------
# Generate a single chunk of code, putting all the classes (packages) into that
# chunk. Then write to a module file if requested 
# or otherwise evaluate it or just return it (depending on the 'mode')
sub _generateSingle {
	my $self 	= shift;
	my $args	= {@_};
	my $model	= $args->{model};
	my $mode	= $args->{mode};
	my $class_prefix = $args->{class_prefix};
	my $module	= $args->{module} || $class_prefix;		
	my $code	= $self->_fabricatePrelude(@_);	
	my $destination		= $args->{destination} || '/tmp/lib/perl/';
	my $verbose	= $self->{verbose} || 0;

	foreach my $items ($model->type(), 	$model->element()) {
		foreach my $key (sort keys %$items) {
			$code	.= $self->_fabricateCode(@_, object=>$items->{$key});
		}
	}
	
	$code .= $self->_fabricateHeaderModuleCode(@_);
	$code .= $self->_fabricateMetaModuleCode(@_);
	
	# Perl modules must return TRUE
	$code .= "\n\n1;\n";
	
	print STDERR "\n****** CODE STARTS *******" . $code . "\n***** CODE ENDS *****\n" if ($verbose >=9);
	
	if ($mode =~ /eval/) {
		# evaluate the code
		eval $code;
		$@ and die "$@\n";		
	}elsif ($mode =~ /return/) {
		# just return the code		
		return $code;
	}else { 
		# generate module
		my $file = module_path(module => $module, destination => $destination);
		$self->_writeCode(@_, file=>$file, code=>$code);	
	}
	return $self;		
}

#--------------------------------------------
# Generate a multiple 'modules' of code, one for each class.
# Then write the code to module files within the 'destination' directory 
sub _generateMultiple {
	my $self 			= shift;
	my $args			= {@_};
	my $model			= $args->{model};
	my $class_prefix	= $args->{class_prefix}; 	
	my $module 			= $args->{module} || $class_prefix;
	my $metaModule		= $args->{metaModule};
	 
	my $types	= $model->type();
	my $destination		= $args->{destination} || '/tmp/lib/perl/';
	
	foreach my $items ($model->type(), 	$model->element()) {
		foreach my $key (sort keys %$items) {
			my $object 	= $items->{$key};
			my $code	= $self->_fabricateCode(@_, object=>$object);
			$code 	   	.= "\n\n__END__\n\n";
			$code		.=$self->_fabricatePod(@_, object=>$object);
		
			my $file = module_path(module => $object->class(), destination => $destination);	
			$self->_writeCode(@_, file=>$file, code=>$code);
		}
	}

	# META mdoule
	my $code = $self->_fabricateMetaModuleCode(@_);
	my $file = module_path(module => $metaModule, destination => $destination);				
	$self->_writeCode(@_, file=>$file, code=>$code);
	
	
	# HEADER module
	if ($module) {
		# Generate the module with all the 'use' statements for different modules.
		my $code = $self->_fabricateHeaderModuleCode(@_);
		
		my $file = module_path(module => $module, destination => $destination);				
		$self->_writeCode(@_, file=>$file, code=>$code);
	}
	
	return $self;		
}


#--------------------------------------------
# Fabricate the code for the module that will 'use' all the generated classes.
#--------------------------------------------
sub _fabricateHeaderModuleCode {
	my $self 			= shift;
	my $args			= {@_};
	my $model			= $args->{model};
	my $style			= $args->{style};
	my $class_prefix	= $args->{class_prefix}; 	
	my $module 			= $args->{module} || $class_prefix;
	my $metaModule		= $args->{metaModule}; 
	my $code;
		
	# get ride of any trailing columns.
	while ($module =~ /:$/) {
		$module =~ s/:$//;
	}
	$code  = _fabricatePrelude(@_) unless ($style =~ /single/i);
	$code .= "\n\npackage $module;\n";
	
	# USE
	unless ($style =~ /single/i) {
		foreach my $items ($model->type(), 	$model->element()) {
			foreach my $name (sort keys %$items) {
				my $object 	= $items->{$name};
				my $class	= $object->class();			
				$code .= "\nuse $class;"
			}
		}
		
		$code .= "\n\nuse $metaModule;"  if ($metaModule);
	}

	# EPILOGUE
	unless ($style =~ /single/i) {
		# Perl modules must return TRUE				
		$code .= "\n\n1;\n";
	}
	
	return $code;		
}


#--------------------------------------------
# Fabricate the first prelude stub of code for each module.
# Needed only in the begining of each physical module file.
sub _fabricatePrelude {
	my $self 	= shift;
	my $code = "";
	
	$code .= "\n#PASTOR: Code generated by XML::Pastor/" . XML::Pastor->version() . " at '" . localtime() . "'\n";
	$code .= "\nuse utf8;";
	$code .= "\nuse strict;";	
	$code .= "\nuse warnings;";
	$code .= "\nno warnings qw(uninitialized);";

	$code .= "\n\nuse XML::Pastor;\n\n";	
	return $code;	
}

#--------------------------------------------
# Fabricate the code for the META module.
#--------------------------------------------
sub _fabricateMetaModuleCode {
	my $self 			= shift;
	my $args			= {@_};
	my $model			= $args->{model};
	my $style			= $args->{style};
	my $module			= $args->{metaModule};
	my $isa				= [qw(XML::Pastor::Meta)];
	my $code			= "";
		
	
	$code  = _fabricatePrelude(@_) unless ($style =~ /single/i);
	
	$code .= "\n\npackage $module;\n";
	
	# ISA		
	$code .= "\n\nour " .  '@ISA=qw(' . join (' ', @$isa) . ");";
	
	# Model	
	$code .= "\n\n$module->Model( " ;		
	$code .= _dumpObject($model);
	$code =~ s/\n$//;
	$code .=" );";	

	# EPILOGUE		
	unless ($style =~ /single/i) {
		# Perl modules must return TRUE
		$code .= "\n\n1;\n";
	}

	return $code;		
}




#--------------------------------------------
# Fabricate the code for one given class (type).
# Can work in 'single' or 'multiple' style (knows to distinguish them).
# Will create code in a separate 'package' section for the class.
sub _fabricateCode {
	my $self 	= shift;
	my $args	= {@_};
	my $object	= $args->{object} or die "Pastor: _fabricateCode: Need a type!\n";
	my $style	= $args->{style};	
	my $class	= $object->class();		
	my $isa		= $object->baseClasses()  || [];	
	my $verbose	= $self->{verbose} || 0;
	my $code	= "";
	
	print STDERR "\nFabricating code for class '$class' ..." if ($verbose >= 3);

	# PRELUDE
	$code .= $self->_fabricatePrelude(@_) unless ($style =~ /single/i);

	# package	
	$code .= "\n\n#================================================================";
	$code .= "\n\npackage $class;\n";

	# use
	# in "single" style, we won't need the use clauses because all packages will be in one module.
	unless ($style =~ /single/i) {	
		my $uses = $self->_calculateUses($object, {@_});	
		foreach my $use (sort keys %$uses) {
			next if $use eq $class;	# We won't be using ourselves!
			$code .= "\nuse $use;";
		}	
	}
	
	# ISA		
	$code .= "\n\nour " .  '@ISA=qw(' . join (' ', @$isa) . ");";

	# mk_accessors			
	my $accessors = [];
	if (UNIVERSAL::can($object, "attributes")) {
		my $attribPfx = "";
		$attribPfx = $object->attributePrefix() if (UNIVERSAL::can($object, "attributePrefix"));
		my $fields = [map {$attribPfx . $_} @{$object->attributes()}]; 
		push @$accessors, @$fields;
	}
	if (UNIVERSAL::can($object, "elements")) {
		push @$accessors, @{$object->elements()};
	}
	if ( scalar(@$accessors) ) {
		$code .= "\n\n$class". '->mk_accessors( qw(' . join (' ', @$accessors) . "));";
	}

	
	# Attribute accessor aliases
	if (UNIVERSAL::can($object, "attributes")) {
		my $attributes = $object->attributes(); 
		my $attribPfx 	= (UNIVERSAL::can($object, "attributePrefix")) ? $object->attributePrefix() : "";
		
		if (scalar(@$attributes) && $attribPfx) {
			$code .= "\n\n# Attribute accessor aliases\n";
			my $elementInfo	= (UNIVERSAL::can($object, "effectiveElementInfo")) ? $object->effectiveElementInfo() : {};		
			foreach my $attribute (@$attributes) {
				next if defined($elementInfo->{$attribute});		# Attribute/Element name conflict. No alias possible
				my $field = $attribPfx . $attribute;
				next if ($field eq $attribute);					# No attribute prefix. No need for an alias.
				$code .= "\nsub $attribute { &" . $field . '; }';
			}		
						
		}
		
	}
	
	
	# XmlSchemaInfo	
	if (UNIVERSAL::isa($object, "XML::Pastor::Schema::Element")) {
		$code .= "\n\n$class->XmlSchemaElement( " ;		
	}else {		
		$code .= "\n\n$class->XmlSchemaType( " ;
	}
	$code .= _dumpObject($object);
	$code =~ s/\n$//;
	$code .=" );";	


	# EPILOGUE		
	unless ($style =~ /single/i) {
		# Perl modules must return TRUE
		$code .= "\n\n1;\n";
	}

	return $code;
}	

#--------------------------------------------
# Figure out the classes that need to be 'used' by a given class.
# This is needed to create the 'use' stubs in code generation. 
sub _calculateUses {
	my $self 	= shift;
	my $object	= shift; 
	my $opts	= shift;
	my $result 	= {};
	
	if (UNIVERSAL::can($object, "class") && $object->class()) {
		my $class = $object->class();
		
		# Consider the class as 'used' unless it starts with XML::Pastor which is handled differently
		# But XML::Pastor::Test::* are used for testing purposes. 
		SWITCH: {
			(($class =~ /^XML::Pastor::/) && 
			($class !~ /^XML::Pastor::Test/))				and do {last SWITCH;};
			OTHERWISE:										{ $result->{$class}=1; last SWITCH;}			
		}		
		
	}

	if (UNIVERSAL::can($object, "itemClass") && $object->itemClass()) {
		my $class = $object->itemClass();
		
		# Consider the class as 'used' unless it starts with XML::Pastor which is handled differently
		# But XML::Pastor::Test::* are used for testing purposes. 
		SWITCH: {
			(($class =~ /^XML::Pastor::/) && 
			($class !~ /^XML::Pastor::Test/))				and do {last SWITCH;};
			OTHERWISE:										{ $result->{$class}=1; last SWITCH;}			
						
		}		
		
	}

	if (UNIVERSAL::can($object, "baseClasses") && $object->baseClasses()) {
		my $isa = $object->baseClasses();
		foreach my $class (@$isa) {		
			# Consider the class as 'used' unless it starts with XML::Pastor which is handled differently
			# But XML::Pastor::Test::* are used for testing purposes. 
			SWITCH: {
				(($class =~ /^XML::Pastor::/) && 
				($class !~ /^XML::Pastor::Test/))				and do {last SWITCH;};
				OTHERWISE:										{ $result->{$class}=1; last SWITCH;}							
			}		
		}
	}

	if (UNIVERSAL::can($object, "memberClasses") && $object->memberClasses()) {
		my $mbcs = $object->memberClasses();
		foreach my $class (@$mbcs) {		
			# Consider the class as 'used' unless it starts with XML::Pastor which is handled differently
			# But XML::Pastor::Test::* are used for testing purposes. 
			SWITCH: {
				(($class =~ /^XML::Pastor::/) && 
				($class !~ /^XML::Pastor::Test/))				and do {last SWITCH;};
				OTHERWISE:										{ $result->{$class}=1; last SWITCH;}			
				
			}		
		}
	}
	
	
	if (UNIVERSAL::can($object, "definition") && $object->definition()) {
			mergeHash($result, $self->_calculateUses($object->definition(), $opts));
	}

	if (UNIVERSAL::can($object, "attributeInfo")) {
		foreach my $attrib  (values %{$object->attributeInfo()} ){
			mergeHash($result, $self->_calculateUses($attrib, $opts));
		}
	}

	if (UNIVERSAL::can($object, "elementInfo")) {
		foreach my $elem  (values %{$object->elementInfo()} ){
			mergeHash($result, $self->_calculateUses($elem, $opts));
		}
	}
	
	return $result;
}

#--------------------------------------------
# Fabricate the POD for one given class (type).
#--------------------------------------------
sub _fabricatePod {
	my $self 	= shift;
	my $args	= {@_};
	my $object	= $args->{object} or die "Pastor: _fabricatePod: Need a type!\n";
	my $style	= $args->{style};	
	my $class	= $object->class();		
	my $isa		= $object->baseClasses()  || [];	
	my $verbose	= $self->{verbose} || 0;
	my $pod	= "";
	
	print STDERR "\nFabricating POD for class '$class' ..." if ($verbose >= 3);

	# NAME	
	$pod .= "\n\n=head1 NAME\n\nB<$class>  -  A class generated by L<XML::Pastor> . \n";

	# DESCRIPTION
	if (defined $object->documentation) {
		$pod .= "\n\n=head1 DESCRIPTION\n";
		foreach my $doc (@{$object->documentation}) {
			my $text = $doc->text;
			$text =~ s/^\s+//;	# chop leading space.
			$pod .= "\n" . $text . "\n";
		}
	}
	
	
	# ISA
	$pod .= "\n\n=head1 ISA\n\nThis class descends from " . join(', ', map {"L<$_>"} @$isa) . ".\n";
	
	# CODE GENERATION
	$pod .= "\n\n=head1 CODE GENERATION\n\nThis module was automatically generated by L<XML::Pastor> version " . $XML::Pastor::VERSION . " at '" . localtime() . "'\n";
	
	# ATTRIBUTE Accessors			
	if (UNIVERSAL::can($object, "attributes") && scalar(@{$object->attributes})) {
		my $attributes = $object->attributes();
		my $attribPfx = "";
		$attribPfx = $object->attributePrefix() if (UNIVERSAL::can($object, "attributePrefix"));
		my $attribInfo = $object->effectiveAttributeInfo();
		my $elementInfo = UNIVERSAL::can($object, 'effectiveElementInfo') ? $object->effectiveElementInfo() : {};
		
		$pod .= "\n\n=head1 ATTRIBUTE ACCESSORS\n";
		$pod .= "\n=over\n";
		
		foreach my $attribute_name (sort @$attributes) {
			my $accessor    = $attribPfx . $attribute_name;
			my $attrib  	= $attribInfo->{$attribute_name};
			next unless (defined $attrib);
			
			$pod .= "\n=item B<$accessor>()";
			
			# Attribute accessor alias (if there is no conflict with an element name)
			unless (exists($elementInfo->{$attribute_name})) {
				$pod .= ", B<$attribute_name>()";
			}	 
			
			my $aclass		= $attrib->class;
			if (defined $aclass) {			
				$pod .= "      - See L<$aclass>.";
			}
			
			$pod .= "\n";
		}
		$pod .= "\n=back\n";				
	}
	
	
	# CHILD ELEMENT accessors
	if (UNIVERSAL::can($object, "elements") && scalar(@{$object->elements})) {
		my $elementInfo = $object->effectiveElementInfo();

		$pod .= "\n\n=head1 CHILD ELEMENT ACCESSORS\n";
		$pod .= "\n=over\n";
				
		foreach my $accessor (sort @{$object->elements()}) {
			my $element = $elementInfo->{$accessor};
			next unless (defined $element);

			$pod .= "\n=item B<$accessor>()";
			my $aclass		= $element->class;
			if (defined $aclass) {			
				$pod .= "      - See L<$aclass>.";
			}
			
			$pod .= "\n";
			
		}
		$pod .= "\n=back\n";	
	}
	
	# SEE ALSO		
	my @see_also = (@$isa, 'XML::Pastor', 'XML::Pastor::Type', 'XML::Pastor::ComplexType', 'XML::Pastor::SimpleType');
	@see_also  = map {"L<$_>"} @see_also;
	
	$pod .= "\n\n=head1 SEE ALSO\n\n";
	$pod .= join (", ", @see_also);
	$pod .= "\n";
	
	# EPILOGUE		
	$pod .= "\n\n=cut\n";
	
	 		
	return $pod;
}	


#--------------------------------------------
# Dump the data for a given "schema type". 
# Note the use of "Deepcopy"  and "Terse" 
# in order to avoid having references in the dumped structure. 
# So we have a clean structure with eventual duplication of data but witout references.
sub _dumpObject {
	my $object = shift;
	my $d	 = Data::Dumper->new([$object]);
	$d->Sortkeys(1);	
	$d->Deepcopy(1);
	$d->Terse(1);	 
	return $d->Dump();
}

#--------------------------------------------
# Write a chunk of code onto a given file.
# Used for writing out the code to the output module files.
# Works for both 'single' and 'multiple' style
sub _writeCode {
	my $self 	= shift;
	my $args	= {@_};
	my $code	= $args->{code} || "";
	my $file	= $args->{file} or die "Pastor : Generator : _writeCode : requires a file name\n";
	my $verbose	= $self->{verbose} || 0;
	
	print STDERR "\nWriting module '$file' ..." if ($verbose >=2);
	my ($volume,$directories,$filebase) = File::Spec->splitpath( $file );
	File::Path::mkpath($volume.$directories);
	my $handle  = IO::File->new($file, "w") or die "Pastor : Generator : _writeCode : Can't open file : $file\n";
	
	print $handle $code;
	$handle->close();
}	


1;

__END__

=head1 NAME

B<XML::Pastor::Generator> - Module used internally by L<XML::Pastor> for generating Perl code from a schema model.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<Class::Accessor>. 

=head1 SYNOPSIS

  my $parser = XML::Pastor::Schema::Parser->new();
  
  my $model = $parser->parse(schema => '/tmp/schema.xsd');
  
  my $generator = XML::Pastor::Generator->new();
  
  $generator->generate (
                        model => $model,
                        mode => 'offline',
                        style => 'multiple'
                        );
  

=head1 DESCRIPTION

B<XML::Pastor::Generator> is used internally by L<XML::Pastor> for generating Perl code from a schema model (L<XML::Pastor::Schema::Model>) that was produced by 
L<XML::Pastor::Schema::Parser> and properly I<resolve>d prior to code generation.

In 'I<offline>'  mode, it is possible to generate a single module with all the generated clasess or multiple modules
one for each class. The typical use of the offline mode is during a 'make' process, where you have a set of XSD schemas and you
generate your modules to be later installed by the 'make install'. This is very similar to Java Castor's behaviour. 
This way your XSD schemas don't have to be accessible during run-time and you don't have a performance penalty.

Perl philosophy dictates however, that There Is More Than One Way To Do It. In 'I<eval>' (run-time) mode, the XSD schema is processed at 
run-time giving much more flexibility to the user. This added flexibility has a price on the other hand, namely a performance penalty and 
the fact that the XSD schema needs to be accessible at run-time. Note that the performance penalty applies only to the code genereration (pastorize) phase; 
the generated classes perform the same as if they were generated offline.

=head1 METHODS

=head2 CONSTRUCTORS
 
=head4 new() 

  XML::Pastor::Generator->new(%fields)

B<CONSTRUCTOR>.

The new() constructor method instantiates a new B<XML::Pastor::Genertor> object. It is inheritable.
  
Any -named- fields that are passed as parameters are initialized to those values within
the newly created object. 

.

=head2 OTHER METHODS

=head4 generate()

	$generator->generate(%options);
	
This is the heart of the module. This method will generate Perl code (either in a single module or multiple modules) and
either write the code to module file(s) on disk or evaluate the generated code according to the parameters passed.

The Perl code will be generated from the B<model> (L<XML::Pastor::Schema::Model>) that is passed as an argument. All the 
I<type> and I<element> definitions found in the model will have a corresponding generated Perl class. 

In L</offline> mode, the generated classes will either all be put in one L</single> big code block, or 
in L</multiple> module files (one for each class) depending on the L</style> parameter. Again in L</offline> mode, the 
generated modules will be written to disk under the directory prefix given by the L</destination> parameter.

B<OPTIONS>

This method expects the following parameters: 

=over 

=item model

This is an object of type L<XML::Pastor::Schema::Model> that corresponds to the internal representation (info set)
of the parsed schemas. The model must have been previously I<resolve>d (see L<XML::Pastor::Schema::Model/resolve()>) 
before being passed to this method. 

=item mode

This parameter effects what actuallly will be done by the method. Either offline code generation, or run-time
code evaluation, or just returning the generated code.

=over

=item offline 

B<Default>.

In this mode, the code generation is done 'offline', that is, similar to Java's Castor way of doing things, the generated code 
will be written to disk on module files under the path given by the L</destination> parameter.

In 'I<offline>'  mode, it is possible to generate a single module with all the generated clasess or multiple modules
one for each class, depending on the value of the L</style> parameter. 

The typical use of the I<offline> mode is during a 'B<make>' process, where you have a set of XSD schemas and you
generate your modules to be later installed by 'B<make install>'. This is very similar to Java Castor's behaviour. 
This way your XSD schemas don't have to be accessible during run-time and you don't have a performance penalty.

  # Generate MULTIPLE modules, one module for each class, and put them under destination.  
  my $generator = XML::Pastor::Generator->new();	  
  $generator->generate(	
  			mode =>'offline',
  			style => 'multiple',
			model=>$model, 
			destination=>'/tmp/lib/perl/', 							
			);  

=item eval 

In 'I<eval>' (run-time) mode, the XSD schema is processed at 
run-time giving much more flexibility to the user. In this mode, no code will be written to disk. Instead, the generated code 
(which is necessarily a L</single> block) will be evaluated before returning to the caller. 

The added flexibility has a price on the other hand, namely a performance penalty and 
the fact that the XSD schema needs to be accessible at run-time. Note that the performance penalty applies only to the code genereration (pastorize) phase; 
the generated classes perform the same as if they were generated offline.

Note that 'I<eval>' mode forces the L</style> parameter to have a value of 'I<single>';

  # Generate classes in MEMORY, and EVALUATE the generated code on the fly.  
  my $generator = XML::Pastor::Generator->new();	    
  $pastor->generate(	
    		mode =>'eval',
			model=>$model, 
			);  

=item return 

In 'I<return>'  mode, the XSD schema is processed but no code is written to disk or evaluated. In this mode, the method
just returns the generated block of code as a string, so that you may use it to your liking. You would typically be evaluating 
it though.

Note that 'I<return>' mode forces the L</style> parameter to have a value of 'I<single>';

=back

=item style

This parameter determines if L<XML::Pastor> will generate a single module where all classes reside (L</single>), or 
multiple modules one for each class (L</multiple>).

Some modes (such as L</eval> and L</return>)force the style argument to be 'I<single>'.

Possible values are :

=over 

=item single 

One block of code containg all the generated classes will be produced. 

=item multiple 

A separate piece of code for each class will be produced. 

=back


=item destination

This is the directory prefix where the produced modules will be written in I<offline> mode. In other modes (I<eval> and I<return>), it is ignored.

Note that the trailing slash ('/') is optional. The default value for this parameter is '/tmp/lib/perl/'.

=item module

This parameter has sense only when generating one big chunk of code (L</style> => L</single>) in offline L</mode>. 

It denotes the name of the module (without the .pm extension) that will be written to disk in this case. 


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

And if you are curious about the implementation, see L<XML::Pastor::Schema::Parser>, L<XML::Pastor::Schema::Model>

=cut
