
package XML::Pastor::Schema::Model;
use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

use Data::Dumper;
use Class::Accessor;

use XML::Pastor::Schema::Object;
use XML::Pastor::Schema::NamespaceInfo;

use XML::Pastor::Util qw(mergeHash);

our @ISA = qw(Class::Accessor);

XML::Pastor::Schema::Model->mk_accessors( qw(type element group attribute attributeGroup defaultNamespace namespaces namespaceCounter));

sub new {
	my $proto 	= shift;
	my $class	= ref($proto) || $proto;
	my $self = {@_};
	
	unless ($self->{type}) {
		$self->{type} = {};
	}
	unless ($self->{element}) {
		$self->{element} = {};
	}

	unless ($self->{group}) {
		$self->{group} = {};
	}
	
	unless ($self->{attribute}) {
		$self->{attribute} = {};
	}
	
	unless ($self->{attributeGroup}) {
		$self->{attributeGroup} = {};
	}
	
	unless ($self->{namespaces}) {
		$self->{namespaces} = {};
	}

	unless ($self->{namespaceCounter}) {
		$self->{namespaceCounter} = 0
	}
	
	return bless $self, $class;
}

#-------------------------------------------------------
sub xml_item {
	my $self 	= shift;
	my $name	= shift;
	my $nsUri	= shift;
	my $verbose = 0;
	
	if (!$nsUri && $self->defaultNamespace) {
		$nsUri = $self->defaultNamespace()->uri();
	}
	
	my $key = $nsUri ? "$name|$nsUri" : $name;
	
	print STDERR "Model item: name = '$name',   key = '$key'\n" if ($verbose >= 9);
	my $item;
	foreach my $hname (qw(element type group attribute attributeGroup)) {
		my $items = $self->{$hname};
		$item = $items->{$key};
		last if defined($item);
	}

	print STDERR "Found item: name = '$name'\n" if (defined ($item) && ($verbose >= 9));
		
	return $item;
	
}

#-------------------------------------------------------
sub xml_item_class {
	my $self 	= shift;
	my $item = $self->xml_item(@_);
	
	return undef unless (defined($item));
	return $item->class || ($item->definition && $item->definition->class);		
}

#-------------------------------------------------------
sub add {
	my $self = shift;
	my $args = {@_};
	my $field;
	my $newItem;
	
	
	unless (defined($field)) {
		$newItem = $args->{object} || $args->{item} || $args->{node};
		SWITCH: {
			UNIVERSAL::isa($newItem, "XML::Pastor::Schema::Type")			and do {$field="type"; last SWITCH;};
			UNIVERSAL::isa($newItem, "XML::Pastor::Schema::Element")		and do {$field="element"; last SWITCH;};
			UNIVERSAL::isa($newItem, "XML::Pastor::Schema::Group")			and do {$field="group"; last SWITCH;};	
			UNIVERSAL::isa($newItem, "XML::Pastor::Schema::Attribute")		and do {$field="attribute"; last SWITCH;};
			UNIVERSAL::isa($newItem, "XML::Pastor::Schema::AttributeGroup")	and do {$field="attributeGroup"; last SWITCH;};			
		}		
	}

	unless (defined($field)) {
		foreach my $arg (qw(type element group attribute attributeGroup)) {
			if (defined ($args->{$arg})) {
				$field = $arg;
				$newItem = $args->{$field};
				last;
			}
		}
	}

	
	unless ( defined($field) ) {
		return undef;
	}
	
	my $items 	= $self->{$field};
	my $key 	= UNIVERSAL::can($newItem, "key") ? $newItem->key() : (UNIVERSAL::can($newItem, "name") ? $newItem->name : '_anonymous_'); 
	if (defined(my $oldItem=$items->{$key})) {
		unless (UNIVERSAL::can($oldItem, 'isRedefinable') && $oldItem->isRedefinable() ) {
			die "Pastor : $field already defined : '$key'\\n"; 
		}
	}
	$newItem->isRedefinable(1) if ($args->{operation} !~ /redefine/i) && UNIVERSAL::can($newItem, 'isRedefinable');
	$items->{$key} = $newItem;	
	
}

#-------------------------------------------------------
sub addNamespaceUri {
	my $self = shift;
	my $uri	 = shift;
	my $verbose = $self->{verbose} || 0;
	
	return undef unless(defined($uri));
	
	my $nsh  = $self->namespaces();
	
	print STDERR "*** Adding Namespace URI to the schema model => '$uri'\n" if ($verbose >= 5);
	
	if (exists ($nsh->{$uri})) {
		# URI is already in use 
		my $ns = $nsh->{$uri};
		$ns->usageCount($ns->usageCount+1);
		return $ns;
	}else {
		# URI is not already there
		my $nsPfx     = undef;
		my $classPfx  = undef;
		my $id		  = 0;
		
		# The counter serves for id purposes.
		my $nsc = $self->namespaceCounter();
		
		if ($nsc) {
			# There is at least one other target namespace alreday in there
			$id			= $nsc+1;
			$nsPfx 		= "ns" . sprintf("%03d", $id);
			$classPfx 	= $nsPfx;
		}
		
		
		# Add the URI to the namspace hash
		my $ns = XML::Pastor::Schema::NamespaceInfo->new(uri=> $uri, id => $id, usageCount=>1, nsPrefix => $nsPfx, classPrefix => $classPfx);
		$nsh->{$uri} = $ns;
		
		# This is the first namespace that is declared. Make it the default.
		unless ($nsc) {
			$self->defaultNamespace($ns);
		}
		
		# Increment the id counter
		$self->namespaceCounter( $self->namespaceCounter + 1);
		
		return $ns;
	}	
	
	
}

#-------------------------------------------------------
sub getItem {
	my $self = shift;
	my $args = {@_};
	my $field;
	my $itemName;
		
	unless (defined($field)) {
		foreach my $arg (qw(type element group attribute attributeGroup)) {
			if (defined ($args->{$arg})) {
				$field = $arg;
				$itemName = $args->{$field};
				last;
			}
		}
	}

	unless ( defined($field) ) {
		return undef;
	}
	
	my $items 	= $self->{$field};
	return $items->{$itemName};
}

#------------------------------------------------------------------
sub dump {
	my $self = shift;
	my $d	 = Data::Dumper->new([$self]);
	$d->Sortkeys(1);
	
#	$d->Deepcopy(1);
#	$d->Terse(1);	 
	return $d->Dump();
}

#------------------------------------------------------------------
sub resolve {
	my $self 	= shift;
	my $opts	= {@_};
	my $verbose = $opts->{verbose} || 0;
	
	print "\n==== Resolving schema model ... ====\n" if ($verbose >= 3);
	
	$self->_resolve($opts);
}

#------------------------------------------------------------------
sub _resolve {
	my $self 		= shift;
	my $opts		= shift;
	my $hashList 	= [$self->group(), $self->attributeGroup, $self->type(), $self->element()];
			
	foreach my $items (@$hashList) {
		foreach my $name (sort keys %$items) {
			$self->_resolveObject($items->{$name}, $opts);			
			
		}
	}
}

#------------------------------------------------------------------
sub _resolveObject {
	my $self 		= shift;
	my $object		= shift;
	my $opts		= shift;
	my $verbose		= $opts->{verbose} || 0;
	
	$self->_resolveObjectRef($object, $opts);	
	$self->_resolveObject($object->definition(), $opts)  if ($object->definition());
	
	$self->_resolveObjectAttributes($object, $opts);	
	$self->_resolveObjectElements($object, $opts);	
	
	$self->_resolveObjectClass($object, $opts);
	$self->_resolveObjectBase($object, $opts);
	
	return $object;	
}

#------------------------------------------------------------------
sub _resolveObjectRef {
	my $self 		= shift;
	my $object		= shift;
	my $opts		= shift;
	my $verbose		= $opts->{verbose} || 0;
	
	return $object unless ( UNIVERSAL::can($object, "ref") && $object->ref() );
	
	print STDERR "  Resolving REFERENCES for object '" . $object->name . "' ...\n" if ($verbose >= 6);
	
	my $field 	= undef;
		
	SWITCH: {
		UNIVERSAL::isa($object, "XML::Pastor::Schema::Type")			and do {$field="type"; last SWITCH;};
		UNIVERSAL::isa($object, "XML::Pastor::Schema::Element")			and do {$field="element"; last SWITCH;};
		UNIVERSAL::isa($object, "XML::Pastor::Schema::Group")			and do {$field="group"; last SWITCH;};	
		UNIVERSAL::isa($object, "XML::Pastor::Schema::Attribute")		and do {$field="attribute"; last SWITCH;};
		UNIVERSAL::isa($object, "XML::Pastor::Schema::AttributeGroup")	and do {$field="attributeGroup"; last SWITCH;};			
	}		

	print STDERR "   Reference is $field\n" if ($verbose >=9);
	
	my $hash 	= $self->{$field};	
	my $refKey	= $object->refKey;
	
	print STDERR "   Resolving reference for '$refKey'\n" if ($verbose >=9);
	
	my $def		= $hash->{$refKey};
	$object->definition($def);
	
	return $def;
}


#------------------------------------------------------------------
sub _resolveObjectClass {
	my $self 		= shift;
	my $object		= shift;
	my $opts		= shift;
	my $verbose		= $opts->{verbose} || 0;
	$opts->{object} = $object;
	
	my $class_prefix = $opts->{class_prefix} || '';
	while (($class_prefix) && ($class_prefix !~ /::$/)) {
		$class_prefix .= ':';
	}
		
	print STDERR "  Resolving CLASS for object '" . $object->name . "' ... \n" if ($verbose >= 6);
	
	if (UNIVERSAL::can($object, "metaClass")) {
		$object->metaClass($class_prefix . "Pastor::Meta");
	}
	
	
	if (UNIVERSAL::isa($object, "XML::Pastor::Schema::Type")) {
		print "   object '" . $object->name . "' is a Type. Resolving class...\n" if ($verbose >= 7);
		$object->class($self->_typeToClass($object->name(), $opts));
	}elsif (UNIVERSAL::isa($object, "XML::Pastor::Schema::Element") && ($object->scope() =~ /global/)) {
		print "   object '" . $object->name . "' is a global element. Resolving class...\n" if ($verbose >= 7);
		my $uri = UNIVERSAL::can($object, 'targetNamespace') ? $object->targetNamespace : "";
		my $pfx = $uri ? $self->namespaceClassPrefix($uri) : ""; 
		$object->class($class_prefix. $pfx . $object->name());
	}elsif(UNIVERSAL::can($object, "type") && UNIVERSAL::can($object, "class")) {
		print "   object '" . ($object->name || ''). "' 'can' type() and class(). TYPE='". ($object->type() || '') . "' CLASS='" . ($object->class() || '') . "' Resolving class...\n"  if ($verbose >= 7);
		
		$object->class($self->_typeToClass($object->type(), $opts));		
	}	

	if (UNIVERSAL::can($object, "itemType") && UNIVERSAL::can($object, "itemClass") && $object->itemType) {
		print "   object '" . $object->name . "' 'can' itemType() and itemClass(). Resolving class...\n" if ($verbose >= 7); 							
		$object->itemClass($self->_typeToClass($object->itemType, $opts));
	}

	if (UNIVERSAL::can($object, "memberTypes") && UNIVERSAL::can($object, "memberClasses") && $object->memberTypes) {
		print "   object '" . $object->name . "' 'can' memberTypes() and memberClasses(). Resolving class...\n" if ($verbose >= 7); 							
		my @mbts = split ' ', $object->memberTypes;
		$object->memberClasses([map {$self->_typeToClass($_, $opts);} @mbts]);
	}

	
	if (UNIVERSAL::can($object, "baseClasses")) {
		print "   object '" . $object->name . "' 'can' baseClasses(). Resolving class...\n" if ($verbose >= 7); 							
		
		if  (UNIVERSAL::can($object, "base") && $object->base()) {
			
			$object->baseClasses([$self->_typeToClass($object->base(), $opts)]);					
		}elsif (UNIVERSAL::isa($object, "XML::Pastor::Schema::Element") 
				&& $object->type() && ($object->scope() =~ /global/)){
			$object->baseClasses([$self->_typeToClass($object->type(), $opts), "XML::Pastor::Element"]);
		}elsif ( UNIVERSAL::isa($object, "XML::Pastor::Schema::SimpleType")) {
			my $isa = $opts->{simple_isa};
			$isa = ( (ref($isa) =~ /ARRAY/) ? $isa : ($isa ? [$isa] : []));
			$object->baseClasses([@$isa, "XML::Pastor::SimpleType"]);								
		}elsif ( UNIVERSAL::isa($object, "XML::Pastor::Schema::ComplexType")) {
			my $isa = $opts->{complex_isa};
			$isa = ( (ref($isa) =~ /ARRAY/) ? $isa : ($isa ? [$isa] : []));
			$object->baseClasses([@$isa, "XML::Pastor::ComplexType"]);			
		}
	}
	
	
	return $object;
}

#------------------------------------------------------------------
sub _resolveObjectAttributes {
	my $self 		= shift;
	my $object		= shift;
	my $opts		= shift;
	my $verbose		= $opts->{verbose} || 0;

	return undef unless (UNIVERSAL::can($object, "attributes"));
	print STDERR "  Resolving ATTRIBUTES for object '" . $object->name . "' ...\n" if ($verbose >= 6);
	
	my $attributes 	= $object->attributes();
	my $attribInfo 	= $object->attributeInfo();
	my $newAttribs	= [];
				
	foreach my $attribName (@$attributes) {
		my $attrib = $attribInfo->{$attribName};
		$self->_resolveObject($attrib, $opts);
		
		unless (UNIVERSAL::isa($attrib, "XML::Pastor::Schema::Attribute")) {
			my $a= (UNIVERSAL::can($attrib, "definition") && $attrib->definition()) || $attrib;
			push @$newAttribs, @{$a->attributes()} 		if UNIVERSAL::can($a, "attributes");
			mergeHash($attribInfo,$a->attributeInfo())	if UNIVERSAL::can($a, "attributeInfo");
		}else {
			push @$newAttribs, $attribName;
		}		
	}	
	
	$object->attributes($newAttribs);
	return $object;
}

#------------------------------------------------------------------
sub _resolveObjectElements {
	my $self 		= shift;
	my $object		= shift;
	my $opts		= shift;
	my $verbose		= $opts->{verbose} || 0;

	return undef unless (UNIVERSAL::can($object, "elements"));

	print STDERR "  Resolving ELEMENTS for object '" . $object->name . "' ...\n" if ($verbose >= 6);
	
	my $elements 	= $object->elements();
	my $elemInfo 	= $object->elementInfo();
	my $newElems	= [];
				
	foreach my $elemName (@$elements) {
		my $elem = $elemInfo->{$elemName};
		$self->_resolveObject($elem, $opts);
		
		unless (UNIVERSAL::isa($elem, "XML::Pastor::Schema::Element")) {
			my $e= (UNIVERSAL::can($elem, "definition") && $elem->definition()) || $elem;			
			push @$newElems, @{$e->elements()} 		if UNIVERSAL::can($e, "elements");
			mergeHash($elemInfo,$e->elementInfo()) 	if UNIVERSAL::can($e, "elementInfo");
		}else {
			push @$newElems, $elemName;
		}		
	}	
	
	$object->elements($newElems);
	return $object;
}

#------------------------------------------------------------------
sub _resolveObjectBase {
	my $self 		= shift;
	my $object		= shift;
	my $opts		= shift;
	my $verbose		= $opts->{verbose} || 0;

	return undef unless (UNIVERSAL::can($object, "base") && $object->base());
	print STDERR "  Resolving BASE for object '" . $object->name . "' ...\n" if ($verbose >= 6);
	
	
	my $base 		= $object->base();
	my $types		= $self->type();
	my $baseType 	= $types->{$base};
	
	
	return undef unless ($baseType);
	$self->_resolveObject($baseType, $opts);
	

	if (UNIVERSAL::can($object, "xAttributes")) {
		my $xattribs	= [];
		my $xattribInfo	= {};
		
		if (UNIVERSAL::can($baseType, "effectiveAttributes")) {
			push @$xattribs, @{$baseType->effectiveAttributes()};
			mergeHash ($xattribInfo, $baseType->effectiveAttributeInfo());
		}
		
		push @$xattribs, @{$object->attributes()};		
		mergeHash ($xattribInfo, $object->attributeInfo());		
		
		print ' ' . scalar(@$xattribs) . ' attributes. ' if ($verbose >=5);
		
		if (@$xattribs) {
			$object->xAttributes($xattribs);
			$object->xAttributeInfo($xattribInfo);
		}
	}

	if (UNIVERSAL::can($object, "xElements")) {
		my $xelems		= [];
		my $xelemInfo	= {};
		
		if (UNIVERSAL::can($baseType, "effectiveElements")) {
			push @$xelems, @{$baseType->effectiveElements()};
			mergeHash ($xelemInfo, $baseType->effectiveElementInfo());
		}
		
		push @$xelems, @{$object->elements()};		
		mergeHash ($xelemInfo, $object->elementInfo());		

#		print ' ' . scalar(@$xelems) . ' elements. ';
		if (@$xelems) {
			$object->xElements($xelems);
			$object->xElementInfo($xelemInfo);
		}
	}
		
	return $object;
}

#------------------------------------------------------------------
sub _typeToClass {
	my $self 		= shift;
	my $type		= shift;
	my $opts		= shift;
	my $object		= $opts->{object};
	my $isNonType	= $opts->{isNonType} || 0;
	my $typePfx 	= $isNonType ?  "" : "Type::";
	my $verbose		= 0;
		
	return undef unless (defined($type)); 

	my $class_prefix = $opts->{class_prefix} || "";
	while (($class_prefix) && ($class_prefix !~ /::$/)) {
		$class_prefix .= ':';
	}

	my $builtin_prefix 	= "XML::Pastor::Builtin::";
	if (($type =~ /^Union$/i) || ($type =~ /^List$/i)) {
		# This one is put by the parser. So we don't have a URI for it.
		return $builtin_prefix . ucfirst($type);		
	}elsif (!$type) {
		# No type declaration, assume string
		return $builtin_prefix . "string";		
	}elsif ($type =~ /www.w3.org\/.*\/XMLSchema$/) {
		# Builtin type
		my ($localType)		= split /\|/, $type;				
		return $builtin_prefix . $localType;
	}elsif ($type =~ /\|/) {
		# Type with a namespace. 
		my ($localType, $uri)	= split /\|/, $type;
		my $pfx = $self->namespaceClassPrefix($uri);		
		
		my $retval = $class_prefix . $pfx . $typePfx . $localType; ;
		print STDERR "_typeToClass: from '$type'   to    '$retval'\n" if ($verbose >=9);
		
		return $retval;
		#die "Pastor: Namespaces not yet supported!\n";
	}else {
		# Regular type.
		my $uri = UNIVERSAL::can($object, 'targetNamespace') ? $object->targetNamespace : "";
		my $pfx = $uri ? $self->namespaceClassPrefix($uri) : ""; 
		return $class_prefix . $pfx . $typePfx . $type;		
	}
}


#-------------------------------------------------------
sub namespaceClassPrefix {
	my $self 	= shift;
	my $uri		= shift;
	
	my $ns = $self->namespaces->{$uri};
	my $pfx = defined($ns) ? ($ns->classPrefix() || "") : "";
	while (($pfx) && ($pfx !~ /::$/)) {
		$pfx .= ':';
	}
	
	return $pfx;
}

1;

__END__

=head1 NAME

B<XML::Pastor::Schema::Model> - Class representing an internal W3C schema model (info set) for L<XML::Pastor>.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<Class::Accessor>. 

=head1 SYNOPSIS

  my $model = XML::Pastor::Schema::Model->new();
  
  $model->add(object->$object1);
  $model->add(object->$object2);
  $model->add(object->$object3);
  
  $model->resolve();

=head1 DESCRIPTION

B<XML::Pastor::Schema::Model> is used internally by L<XML::Pastor> for representinng the parsed information set 
of a group of W3C schemas. 

A B<model> is produced typically by parsing with the L<XML::Pastor::Schema::Parser/parse()> method. However, it is theoratically 
possible to produce it by other means. 

A B<model> contains information about all the I<type, element, attribute, group, and attribute group> definitions that come from the set of 
schemas that constitute the I<source> of the model. This includes all global and implicit types and elements.

Once produced, you can't do much with a model except B<resolve> it. Resolving the model means things such as resolving all references (such as 
those pointing to global elements or groups) and computing the Perl class names that correspond to each generated class. See L</resolve()> for more 
details.

Once resolved, the model is then ready to be used for code generation. 

=head1 METHODS

=head2 CONSTRUCTORS
 
=head4 new() 

  XML::Pastor::Schema::Model->new(%fields)

B<CONSTRUCTOR>.

The new() constructor method instantiates a new object. It is inheritable. 
  
Any -named- fields that are passed as parameters are initialized to those values within
the newly created object. 

The B<new()> method will create the I<type>, I<element>, I<attribute>, I<group>, and I<attributeGroup> fields 
if it is not passed values for those fields.

.

=head2 ACCESSORS
 
=head4 type() 

A hash of all (global and implicit) type definitions (simple or complex) that are obtained from the processed W3C schemas.
The hash key is the name of the B<type> and the value is an object of type L<XML::Pastor::Schema::SimpleType> or L<XML::Pastor::Schema::ComplexType>, 
depending on whether this is a simple or complex type.

A straight forward consequence is that simple and complex types cannot have name collisions among each other. This conforms with the W3C specifications.

Note that this hash is obtained from a merge of all the information coming from the various W3C schemas. So it represents information coming from all the concerned schemas.

Note that each item of this hash later becomes a generated class under the "Type" subtree when code generation is performed  

=head4 element() 

A hash of all global elements obtained from the W3C schemas. The hash key is the name of the global element and the value is an object
of type L<XML::Pastor::Schema::Element>.

Note that this hash is obtained from a merge of all the information coming from the various W3C schemas. So it represents information coming from all the concerned schemas.

Note that each item of this hash later becomes a generated class when code generation is performed. 

=head4 attribute() 

A hash of all global attributes obtained from the W3C schemas. The hash key is the name of the global attribute and the value is an object
of type L<XML::Pastor::Schema::Attribute>.

Note that this hash is obtained from a merge of all the information coming from the various W3C schemas. So it represents information coming from all the concerned schemas.

Note that no code generation is perfomed for the items in this hash. They are used internally by the "type" hash once the referenes to them are resolved.

=head4 group() 

A hash of all global groups obtained from the W3C schemas. The hash key is the name of the global group and the value is an object
of type L<XML::Pastor::Schema::Group>.

Note that this hash is obtained from a merge of all the information coming from the various W3C schemas. So it represents information coming from all the concerned schemas.

Note that no code generation is perfomed for the items in this hash. They are used internally by the "type" hash once the referenes to them are resolved.

=head4 attributeGroup() 

A hash of all global attribute groups obtained from the W3C schemas. The hash key is the name of the global attribute group and the value is an object
of type L<XML::Pastor::Schema::AttributeGroup>.

Note that this hash is obtained from a merge of all the information coming from the various W3C schemas. So it represents information coming from all the concerned schemas.

Note that no code generation is perfomed for the items in this hash. They are used internally by the "type" hash once the referenes to them are resolved.

.

=head2 OTHER METHODS

=head4 add()

	$model->add(object=>$object);
	
Add a schema object to the model (to the corresponding hash). 
Aliases of 'object' are 'item' and 'node'. So the following are equivalent to the above:

	$model->add(item=>$object);
	$model->add(node=>$object);
	
In the above, the actual hash where the object will be placed is deduced from the type of the object.
Possible types are descendents of:

=over

=item L<XML::Pastor::Schema::Type>	(where L<XML::Pastor::Schema::SimpleType> and L<XML::Pastor::Schema::ComplexType> descend.)

=item L<XML::Pastor::Schema::Element>

=item L<XML::Pastor::Schema::Group>

=item L<XML::Pastor::Schema::Attribute>
		
=item L<XML::Pastor::Schema::AttributeGroup>

=back
	
One can also pass the name of the hash that one would like the object to be added. Examples:

	$model->add(type=>$object);
	$model->add(element=>$object);
	$model->add(group=>$object);
	$model->add(attribute=>$object);
	$model->add(attributeGroup=>$object);
	
In this case, the type of the object is not taken into consideration.

Normally, when a schema object is already defined within the model, it is an error to attempt to add it
again to the model. This means that the object is defined twice in the W3C schema. However, this rule
is relaxed when the object within the sceham is marked as I<redefinable> (see L<XML::Pastor::Schema::Object/isRedefinable()>). 
This is typically the case when we are in a I<redefine> block (when a schema is included wit the redefine tag). 

=head4 xml_item($name, [$nsUri])

Returns the Schema Model item for a given name, and optionally, a namespace URI. If namespace URI is omitted, then
the default namespace URI for the model is used.

This method does a search on the different hashes kept by the model (element, type, group, attribute, attributeGroup) in that order, and 
will return the first encountred item.
 
=head4 xml_item_class($name, [$nsUri])

Returns the class name of a Schema Model item for a given name, and optionally, a namespace URI. If namespace URI is omitted, then
the default namespace URI for the model is used.

This is in fact a shortcut for:
   $model->xml_item($name)->class();

 
=head4 resolve()
   
  $model->resolve(%options);

B<OBJECT METHOD>.

This method will I<resolve> the B<model>. In other words, thhis method will prepare the produced model to be
processed for code gerenartion.

Resolving a model means: resolving references to global objects (elements and attributes); replacing
group and attributeGroup references with actual contents of the referenced group; computing the Perl class 
names of the types and elements to be generated; and figuring out the inheritance relationships between classes.

The builtin classes are known to the method so that the Perl classes for them will not be generated but rather referenced 
from the L<XML::Pastor::Builtin> module.

OPTIONS 

=over

=item class_prefix

If present, the names of the generated classes will be prefixed by this value. 
You may end the value with '::' or not, it's up to you. It will be autocompleted. 
In other words both 'MyApp::Data' and 'MyApp::Data::' are valid. 

=item complex_isa

Via this parameter, it is possible to indicate a common ancestor (or ancestors) of all complex types that are generated by B<XML::Pastor>.
The generated complex types will still have B<XML::Pastor::ComplexType> as their last ancestor in their @ISA, but they will also have the class whose  
name is given by this parameter as their first ancestor. Handy if you would like to add common behaviour to all your generated classes. 

This parameter can have a string value (the usual case) or an array reference to strings. In the array case, each item is added to the @ISA array (in that order) 
of the generated classes.

=item simple_isa

Via this parameter, it is possible to indicate a common ancestor (or ancestors) of all simple types that are generated by B<XML::Pastor>.
The generated simple types will still have B<XML::Pastor::SimpleType> as their last ancestor in their @ISA, but they will also have the class whose  
name is given by this parameter as their first ancestor. Handy if you would like to add common behaviour to all your generated classes. 

This parameter can have a string value (the usual case) or an array reference to strings. In the array case, each item is added to the @ISA array (in that order) 
of the generated classes.

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

If you are curious about the implementation, see L<XML::Pastor::Schema::Parser>, L<XML::Pastor::Generator>

If you really want to dig in, see L<XML::Pastor::Schema::Attribute>, L<XML::Pastor::Schema::AttributeGroup>,
L<XML::Pastor::Schema::ComplexType>, L<XML::Pastor::Schema::Element>, L<XML::Pastor::Schema::Group>,
L<XML::Pastor::Schema::List>, L<XML::Pastor::Schema::SimpleType>, L<XML::Pastor::Schema::Type>, 
L<XML::Pastor::Schema::Object>

=cut
