package XML::DOM2::DOM::Element;

=head1 NAME

XML::DOM2::DOM::Element - A library of DOM (Document Object Model) methods for XML Elements.

=head1 DESCRIPTION

Provides all the DOM method for XML Elements

=head1 METHODS

=cut

use base "XML::DOM2::DOM::NameSpace";

use strict;
use Carp;

=head2 $element->getFirstChild()

=head2 $element->firstChild()

  Returns the elements first child in it's children list

=cut
sub getFirstChild ($) {
    my $self=shift;

    if (my @children=$self->getChildren) {
        return $children[0];
    }
    return undef;
}
*firstChild=\&getFirstChild;

=head2 $element->getLastChild()

=head2 $element->lastChild()

  Returns the elements last child in it's children list

=cut
sub getLastChild ($) {
	my $self=shift;

	if (my @children=$self->getChildren) {
		return $children[-1];
	}

	return undef;
}
*lastChild=\&getLastChild;

=head2 $element->getChildIndex( @children )

  Return the array index of this element in the parent or the passed list (if there is one).

=cut
sub getChildIndex ($;@) {
    my ($self,@children)=@_;

    unless (@children) {
        my $parent=$self->getParent();
        @children=$parent->getChildren();
        return undef unless @children;
    }

    for my $index (0..$#children) {
        return $index if $children[$index] == $self;
    }

    return undef;
}

=head2 $element->getChildAtIndex( $index )

  Return the element at the specified index (the index can be negative).

=cut
sub getChildAtIndex ($$;@) {
    my ($self,$index,@children)=@_;

    unless (@children) {
        my $parent=$self->getParent();
        @children=$parent->getChildren();
        return undef unless @children;
    }

    return $children[$index];
}

=head2 $element->getNextSibling()

=head2 $element->nextSibling()

  Return the next element to this element in the parents child list.

=cut
sub getNextSibling ($) {
    my $self=shift;

    if (my $parent=$self->getParent) {
        my @children=$parent->getChildren();
        my $index=$self->getChildIndex(@children);
        if (defined $index and scalar(@children)>$index) {
            return $children[$index+1];
        }
    }
    return undef;
}
*nextSibling=\&getNextSibling;

=head2 $element->getPreviousSibling()

=head2 $element->previousSibling()

  Return the previous element to this element in the parents child list.

=cut
sub getPreviousSibling ($) {
    my $self=shift;

    if (my $parent=$self->getParent) {
        my @children=$parent->getChildren();
        my $index=$self->getChildIndex(@children);
        if ($index) {
            return $children[$index-1];
        }
    }

    return undef;
}
*previousSibling=\&getPreviousSibling;

=head2 $element->getChildren()

=head2 $element->getChildElements()

=head2 $element->getChildNodes()

  Returns all the elements children.

=cut
sub getChildren ($) {
    my $self=shift;
    if ($self->{'children'}) {
		return @{$self->{'children'}};
	}
    return ();
}
*getChildElements=\&getChildren;
*getChildNodes=\&getChildren;

=head2 $element->getChildrenByName( $name )

  Returns all the elements children with that tag name (including namespace prefix).

=cut
sub getChildrenByName
{
	my ($self, $name) = @_;
	if(defined($self->{'child'}->{$name})) {
		if(wantarray) {
			return @{$self->{'child'}->{$name}};
		} else {
			return $self->{'child'}->{$name}->[0];
		}
	}
}

=head2 $element->hasChildren()

=head2 $element->hasChildElements()

=head2 $element->hasChildNodes()

  Returns 1 if this element has children.

=cut
sub hasChildren ($) {
    my $self=shift;

    if (exists $self->{'children'}) {
        if (scalar @{$self->{'children'}}) {
            return 1;
        }
    }

    return 0;
}
*hasChildElements=\&hasChildren;
*hasChildNodes=\&hasChildren;

=head2 $element->getParent()

=head2 $element->getParentElement()

=head2 $element->getParentNode()

  Returns the object of the parent element.

=cut
sub getParent ($) {
    my $self=shift;

    if ($self->{'parent'}) {
        return $self->{'parent'};
    }

    return undef;
}
*getParentElement=\&getParent;
*getParentNode=\&getParent;

=head2 $element->setParent( $element )

=head2 $element->setParentElement( $element )

$element->setParent($parent);

Sets the parent node, used internaly.

=cut
sub setParent ($$) {
    my ($self,$parent) = @_;

	if(ref($parent) or not defined($parent)) {
		$self->{'parent'} = $parent;
		return 1;
	}

    return undef;
}
*setParentElement=\&setParent;

=head2 $element->getParents()

=head2 $element->getParentElements()

=head2 $element->getParentNodes()

=head2 $element->getAncestors()

  Return a list of the parents of the current element, starting from the immediate parent. The
  last member of the list should be the document element.

=cut
sub getParents {
    my $self=shift;

    my $parent = $self->getParent;
    return undef unless $parent;

    my @parents;
    while ($parent) {
        push @parents,$parent;
        $parent=$parent->getParent;
    }

    return @parents;
}
*getParentElements=\&getParents;
*getParentNodes=\&getParents;
*getAncestors=\&getParents;

=head2 $element->isAncestor( $node )

  Returns true if the current element is an ancestor of the descendant element.

=cut
sub isAncestor ($$) {
    my ($self,$descendant)=@_;

    my @parents=$descendant->getParents();
    foreach my $parent (@parents) {
        return 1 if $parent==$self;
    }

    return 0;
}

=head2 $element->isDescendant( $node )

  Return true if the crrent element is the descendant of the ancestor element.

=cut
sub isDescendant ($$) {
    my ($self,$ancestor)=@_;

    my @parents=$self->getParents();
    foreach my $parent (@parents) {
        return 1 if $parent==$ancestor;
    }

    return 0;
}

=head2 $element->getSiblings()

  Returns a list of sibling elements.

=cut
sub getSiblings ($) {
    my $self=shift;

    if (my $parent=$self->getParent) {
        return $parent->getChildren();
    }

    return wantarray?():undef;
}

=head2 $element->hasSiblings()

  Returns true if the elements has sibling elements.

=cut
sub hasSiblings ($) {
    my $self=shift;

    if (my $parent=$self->getParent) {
        my $siblings=scalar($parent->getChildren);
        return 1 if $siblings>=2;
    }

    return undef;
}

=head2 $element->getElementName()

=head2 $element->getElementType()

=head2 $element->getType()

=head2 $element->getTagName()

=head2 $element->getTagType()

=head2 $element->getNodeName()

=head2 $element->getNodeType()

  Return a string containing the name (i.e. the type, not the Id) of an element.

=cut
sub getElementName ($) {
    my $self=shift;

	return $self->name;
}
*getType=\&getElementName;
*getElementType=\&getElementName;
*getTagName=\&getElementName;
*getTagType=\&getElementName;
*getNodeName=\&getElementName;
*getNodeType=\&getElementName;

=head2 $element->getElementId()

  Return a string containing the elements Id (unique identifier string).

=cut
sub getElementId ($) {
    my $self=shift;

    if (exists $self->{id}) {
        return $self->{id};
    }

    return undef;
}

=head2 $element->getAttribute( $attributeName )

  Returns the specified attribute in the element, will return a
  serialised string instead of posible attribute object if serialise set.

=cut
sub getAttribute
{
    my ($self, $name) = @_;
	my $attribute = $self->{'attributes'}->{''}->{$name};
	return $attribute;
}

=head2 $element->getAttributes( $serialise, $ns )

  Returns a list of attributes in various forms.

=cut
sub getAttributes
{
    my ($self, $serialise, $ns) = @_;
	my @names = $self->getAttributeNamesNS($ns);
	my %attributes;
	my @attributes;
	foreach my $nsr (@names) {
		my ($sns, $name) = @{$nsr};
		my $attribute;
		if($sns) {
			$attribute = $self->getAttributeNS($sns, $name, $serialise);
		} else {
			$attribute = $self->getAttribute($name, $serialise);
		}
		if(not defined($attribute)) {
			die "Something is very wrong with the attributes";
		}
		if(not ref($attribute)) {
			die "An attribute should always be an object: ($name:$attribute) ".$self->name."\n";
		}
		if($serialise <= 1) {
			$attributes{$attribute->name} = $attribute;
		} else {
			push @attributes, $attribute->serialise_full;
		}
    }
	if($serialise <= 1) {
	    return wantarray ? %attributes : \%attributes;
	} elsif($serialise == 2) {
		return wantarray ? @attributes : \@attributes;
	} else {
		return join(' ', @attributes);
	}
}

=head2 $element->getAttributeNames()

  Returns a list of attribute names, used internaly.

=cut
sub getAttributeNames
{
    my ($self, $ns) = @_;
	my $prefix = $ns ? $ns->ns_prefix : '';
	warn "The prefix is undefined!" if not defined($prefix);
	my @names;
	foreach my $name (keys(%{$self->{'attributes'}->{$prefix}})) {
		push @names, $name;
	}
    return wantarray ? @names : \@names;
}

=head2 $element->getAttributeNamesNS( $namespace )

  Returns a list of attribute names, used internaly.

=cut
sub getAttributeNamesNS
{
	my ($self, $ns) = @_;
	# Default Namespace
	my @names;

	# Get all other name spaces
	my @ns = $ns ? ($ns) : $self->getAttributeNamespaces;

	foreach my $sns (@ns) {
		if(defined($sns)) {
			foreach my $name ($self->getAttributeNames($sns)) {
				push @names, [ $sns, $name ];
			}
		} else {
			warn "One of the name spaces is not defined\n";
		}
	}
	return @names;
}

=head2 $element->getAttributeNamespaces()

  Returns a list of attribute names, used internaly.

=cut
sub getAttributeNamespaces
{
	my ($self) = @_;
	return map { $_ ne '' ? $self->document->getNamespace($_) : '' } keys(%{$self->{'attributes'}});
}

=head2 $element->hasAttribute( $attributeName )

  Returns true if this element as this attribute.

=cut
sub hasAttribute
{
	my ($self, $name) = @_;
	return 1 if exists( $self->{'attributes'}->{''}->{$name} );
}

=head2 $element->hasAttributeNS( $namespace, $attributeName )

  Returns true if this attribute in this namespace is in this element.

=cut
sub hasAttributeNS
{
    my ($self, $ns, $name) = @_;
	my $prefix = $ns->ns_prefix;
    return 1 if exists( $self->{'attributes'}->{$prefix}->{$name} );
}

=head2 $element->hasAttributes()

  Return true is element has any attributes

=cut

sub hasAttributes
{
	my ($self) = @_;
	return 1 if $self->{'attributes'} and keys(%{ $self->{'attributes'} })
}

=head2 $element->setAttribute( $attribute, $value )

  Set an attribute on this element, it will accept serialised strings or objects.

=cut
sub setAttribute
{
    my ($self, $name, $value) = @_;
	confess "Name is not defined" if not $name;
	my $existing = $self->getAttribute($name);
	# This ensures that ids are updated in a sane way.
	if ($name eq "id" and $self->document and defined($value)) {
		# Set the new id
		if($self->document->addId($value, $self)) {
			if($existing) {
				# Remove the old id
				my $oldvalue = $existing->serialise;
				$self->document->removeId($oldvalue);
			}
		} else {
			$self->error('setAttribute', "Id '$value' already exists in document, unable to modify attribute");
			return undef;
		}
	}

	# Some elements can't contain attributes
	$self->{'attributes'}->{''}->{$name} = $self->_get_attribute_object( $name, $value, undef, $existing );
	return 1;
}

sub _get_attribute_object
{
	my ($self, $name, $value, $ns, $existing) = @_;
	if(not $self->_can_contain_attributes) {
		$self->error('setAttribute', "This Element can not contain attributes. (".$self->getElementName.")");
		return undef;
	}
	# undef means delete attribute
	return $self->removeAttribute($name) if not defined($value);
	my $result;
	# This is to handle attributes handled by objects
	if($self->_has_attribute($name)) {
		$result = $existing;
		if(not $result) {
			# Create a new attribute
			$result = $self->_attribute_handle( $name, name => $name, namespace => $ns, owner => $self );
			
		}
		croak "Unable to setAttribute, _attribute_handle does not exist (".ref($self).":$name)" if not ref($result);
		$result->deserialise($value);
	}
	return $result;
}

=head2 $element->removeAttribute( $name )

  Remove a single attribute from this element.

=cut
sub removeAttribute
{
	my ($self, $name) = @_;
	if($self->hasAttribute($name)) {
		my $attribute = delete($self->{'attributes'}->{''}->{$name});
		$attribute->delete;
	}
}

=head2 $element->removeAttributeNS( $namespace, $name )

  Remove a single attribute from this element.

=cut
sub removeAttributeNS
{
    my ($self, $ns, $name) = @_;
    if($self->hasAttributeNS($ns, $name)) {
        my $attribute = delete($self->{'attributes'}->{$ns->ns_prefix}->{$name});
		$attribute->delete;
    }
}

=head2 $element->getAttributeNS( $namespace, $name )

  Returns an attributes namespace in this element.

=cut
sub getAttributeNS
{
	my ($self, $ns, $name) = @_;
	if(not ref($ns)) {
		confess "You must give ns methods the name space object, not just the URI or Prefix (skipped)";
	}
	my $prefix = $ns->ns_prefix;
	$prefix = '' if not $prefix;
	if($self->{'attributes'}->{$prefix}->{$name}) {
		return $self->{'attributes'}->{$prefix}->{$name};
	}
}

=head2 $element->setAttributeNS( $namespace, $name, $value )

  Sets an attributes namespace in this element.

=cut
sub setAttributeNS
{
	my ($self, $ns, $name, $value) = @_;
	if(not ref($ns)) {
		confess "You must give ns methods the name space object, not just the URI or Prefix (skipped)";
	}
	my $prefix = $ns->ns_prefix;
	$self->{'attributes'}->{$prefix}->{$name} = $self->_get_attribute_object($name, $value, $ns);
	if(not $self->{'attributes'}->{$prefix}->{$name}) {
		warn "setAttributeNS was unable to set the attribute ";
	}
}

=head2 $element->cdata( $text )

  Rerieve and set this elements cdata (non tag cdata form)

=cut
sub cdata
{
	my ($self, $text) = @_;
	if($self->hasChildren()) {
		$self->error(value => "Unable to get cdata for element with children, xml error!");
		return;
	}
	if(defined($text)) {
		if(ref($text) =~ /CDATA/) {
			$self->{'cdata'} = $text;
		} else {
			$self->{'cdata'} = XML::DOM2::Element::CDATA->new($text, notag => 1);
		}
	}
	return $self->{'cdata'};
}

=head2 $element->hasCDATA()

  Return true if this element has cdata.

=cut
sub hasCDATA ($) {
	my $self=shift;
	return exists($self->{'cdata'});
}

=head2 $element->document()

  Return this elements document, returns undef if no document available.

=cut
sub document
{
	my ($self) = @_;
	return $self->{'document'} if ref($self->{'document'});
	if($self->getParent) {
		return $self->getParent->document;
	} else {
		confess "Where you expecting an orphaned element ".$self->localName."\n";
		return undef;
	}
}

=head2 $element->insertBefore( $node, $childNode )

=head2 $element->insertChildBefore( $node, $childNode )

=head2 $element->insertNodeBefore( $node, $childNode )

=head2 $element->insertElementBefore( $node, $childNode )

  Inserts a new element just before the referenced child.

=cut
sub insertBefore
{
	my ($self, $newChild, $refChild) = @_;
	return $self->appendElement($newChild) if not $refChild;
	my $index = $self->findChildIndex($refChild);
	return 0 if $index < 0; # NO_FOUND_ERR
	return $self->insertAtIndex($newChild, $index);
}
*insertChildBefore=\&insertBefore;
*insertNodeBefore=\&insertBefore;
*insertElementBefore=\&insertBefore;

=head2 $element->insertAfter( $node, $childNode )

=head2 $element->insertChildAfter( $node, $childNode )

=head2 $element->insertElementAfter( $node, $childNode )

=head2 $element->insertNodeAfter( $node, $childNode )

Inserts a new child element just after the referenced child.

=cut
sub insertAfter
{
	my ($self, $newChild, $refChild) = @_;
	return $self->appendElement($newChild) if not $refChild;
	my $index = $self->findChildIndex($refChild);
	return 0 if $index < 0; # NO_FOUND_ERR
	return $self->insertAtIndex($newChild, $index+1);
}
*insertChildAfter=\&insertAfter;
*insertNodeAfter=\&insertAfter;
*insertElementAfter=\&insertAfter;

=head2 $element->insertSiblingAfter( $node )

  Inserts the child just after the current element (effects parent).

=cut
sub insertSiblingAfter
{
	my ($self, $newChild) = @_;
	return $self->getParent->insertAfter($newChild, $self) if $self->getParent;
	return 0;
}

=head2 $element->insertSiblingBefore( $node )

  Inserts the child just before the current element (effects parent).

=cut
sub insertSiblingBefore
{
    my ($self, $newChild) = @_;
    return $self->getParent->insertBefore($newChild, $self) if $self->getParent;
    return 0;
} 

=head2 $element->replaceChild( $newChild, $oldChild )

  Replace an old child with a new element, returns old element.

=cut
sub replaceChild
{
	my ($self, $newChild, $oldChild) = @_;
	# Replace newChild if it is in this list of children already
	$self->removeChild($newChild) if $newChild->getParent eq $self;
	# We need the index of the node to replace
	my $index = $self->findChildIndex($oldChild);
	return 0 if($index < 0); # NOT_FOUND_ERR
	# Replace and bind new node with it's family
	$self->removeChildAtIndex($index);
	$self->insertChildAtIndex($index);
	return $oldChild;
}

=head2 $element->replaceElement( $newElement )

=head2 $element->replaceNode( $newElement )

  Replace an old element with a new element in the parents context; element becomes orphaned.

=cut
sub replaceElement
{
	my ($self, $newElement) = @_;
	return $self->getParent->replaceChild($newElement, $self);
}
*replaceNode=\&replaceElement;

=head2 $element->removeChild( $child )

  Remove a child from this element, returns the orphaned element.

=cut
sub removeChild
{
	my ($self, $oldChild) = @_;
	my $index = $self->findChildIndex($oldChild);
	return 0 if(not defined $index or $index < 0); # NOT_FOUND_ERR
	return $self->removeChildAtIndex($index);
}

=head2 $element->removeElement()

=head2 $element->removeNode()

  Removes this element from it's parent; element becomes orphaned.

=cut
sub removeElement
{
	my ($self) = @_;
	return $self->getParent->removeChild($self);
}
*removeNode=\&removeElement;

=head2 $element->appendChild( $node )

=head2 $element->appendElement( $node )

=head2 $element->appendNode( $node )

  Adds the new child to the end of this elements children list.

=cut
sub appendChild
{
	my ($self, $element) = @_;
	return $self->insertAtIndex( $element, scalar($self->getChildren) || 0 );
}
*appendElement=\&appendChild;
*appendNode=\&appendChild;

=head2 $element->cloneNode( $deep )

=head2 $element->cloneElement( $deep )

  Clones the current element, deep allows all child elements to be cloned.
  The new element is an orphan with all the same id's and atributes as this element.

=cut
sub cloneNode
{
	my ($self, $deep) = @_;
	my $clone = XML::DOM2::Element->new($self->localName);
	foreach my $key (keys(%{$self})) {
		if($key ne 'children' and $key ne 'parent') {
			$clone->{$key} = $self->{$key};
		}
	}
	# We need to clone the children if deep is specified.
	if($deep) {
		foreach my $child ($self->getChilden) {
			my $childClone = $child->cloneNode($deep);
			$clone->appendChild($childClone);
		}
	}
	return $clone;
}
*cloneElement=\&cloneNode;

=head2 $element->findChildIndex( $child )

  Scans through children trying to find this child in the list.

=cut
sub findChildIndex
{
	my ($self, $refChild) = @_;
	my $index;
	foreach my $child ($self->getChildren) {
        return $index if $child eq $refChild;
        $index++;
    } 
	return -1;
}

=head2 $element->insertAtIndex( $node, $index )

  Adds the new child at the specified index to this element.

=cut
sub insertAtIndex
{
	my ($self, $newChild, $index) = @_;
	confess "Unable to insertAtIndex no index defined" if not defined($index);
	my $id = $newChild->getElementId();
	if($self->document) {
		if($id && not $self->document->addId($id, $newChild)) {
			$self->error($id => "Id already exists in document");
	        return undef;
		}
		$self->document->addElement($newChild);
	} else {
		warn("Unable to insert element ".$self->getElementName." not document defined");
		return 0;
	}
	# Remove the child from other documents and nodes
	$newChild->getParent->removeChild($newChild) if $newChild->getParent;

	# This index supports the getChildrenByName function
	if($self->{'child'}->{$newChild->name}) {
		push @{$self->{'child'}->{$newChild->name}}, $newChild;
	} else {
		$self->{'child'}->{$newChild->name} = [ $newChild ];
	}

	# Set in new parent
	splice @{$self->{'children'}}, $index, 0, $newChild;
    $newChild->setParent($self);
	return 1;
}

=head2 $element->removeChildAtIndex( $index )

  Removed the child at index and returns the now orphaned element.

=cut
sub removeChildAtIndex
{
	my ($self, $index) = @_;
	my $oldChild = splice @{$self->{'children'}}, $index, 1;
	my $id = $oldChild->getElementId();
	$self->document->removeId($id) if($id);
	$self->document->removeElement($oldChild);
	$oldChild->setParent(undef);
	if(not $self->hasChildren) {
		delete $self->{'childen'};
	}
	return $oldChild;
} 

=head2 $element->createChildElement( $name, %options )

=head2 $element->createElement( $name, %options )

Not DOM2, creates a child element, appending to current element.

The advantage to using this method is the elements created
with $document->createElement create basic element objects or
base objects (those specified in the XML base class or it's kin)
Elements created with this could offer more complex objects back.

Example: an SVG Gradiant will have stop elements under it, creating
stop elements with $document->createElement will return an XML::DOM2::Element
create a stop element with $element->createChildElement and it will
return an SVG2::Element::Gradiant::Stop object (although both would
output the same xml) and it would also prevent you from creating invalid
child elements such as a group within a text element.

$element->createChildElement($name, %opts);

=cut

sub createChildElement
{
	my ($self, $name, %opts) = @_;
	my $element = $self->_element_handle($name, %opts, document => $self->document() );
	if(ref($element) =~ /CDATA/) {
		$self->cdata( $element );
	} else {
		$self->appendChild($element);
	}
	return $element;
}
*createElement=\&createChildElement;

=head1 AUTHOR

Martin Owens, doctormo@postmaster.co.uk

=head1 SEE ALSO

perl(1), L<XML::DOM2>, L<XML::DOM2::Element>

L<http://www.w3.org/TR/1998/REC-DOM-Level-1-19981001/level-one-core.html> DOM at the W3C

=cut

return 1;
