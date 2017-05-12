package XML::Mini::Element;
use strict;
$^W = 1;

use XML::Mini;
use XML::Mini::TreeComponent;
use XML::Mini::Element::Comment;
use XML::Mini::Element::DocType;
use XML::Mini::Element::Entity;
use XML::Mini::Element::CData;

use vars qw ( $VERSION @ISA );
push @ISA, qw ( XML::Mini::TreeComponent );
$VERSION = '1.38';

sub new
{
    my $class = shift;
    my $name = shift;
    
    my $self = {};
    bless $self, ref $class || $class;
    
    $self->{'_attributes'} = {};
    $self->{'_numChildren'} = 0;
    $self->{'_numElementChildren'} = 0;
    $self->{'_children'} = [];
    $self->{'_avoidLoops'} = $XML::Mini::AvoidLoops;
    
    if ($name)
    {
	$self->name($name);
    } else {
	return XML::Mini->Error("Must pass a name to create a new Element.");
    }

    return $self;
}

sub name
{
    my $self = shift;
    my $name = shift;
    
    if (defined $name)
    {
	$self->{'_name'} = $name;
    }
    
    return $self->{'_name'};
}

sub attribute
{
    my $self = shift;
    my $name = shift || return undef;
    my $primValue = shift;
    my $altValue = shift;
    
    my $value = (defined $primValue) ? $primValue : $altValue;
    
    if (defined $value)
    {
	$self->{'_attributes'}->{$name} = $value;
    } else {
    	$self->{'_attributes'}->{$name} = ''
		unless (defined $self->{'_attributes'}->{$name});
    }
    
    if (defined $self->{'_attributes'}->{$name})
    {
	return $self->{'_attributes'}->{$name};
    }
    
    return undef;
}

sub text
{
    my $self = shift;
    my $primValue = shift;
    my $altValue = shift;
    
    my $setTo = (defined $primValue) ? $primValue : $altValue;
    
    if (defined $setTo)
    {
	$self->createNode($setTo);
    }
    
    my @contents;
    
    foreach my $child (@{$self->{'_children'}})
    {
	my $value = $child->getValue();
	if (defined $value)
	{
	    push @contents, $value;
	}
    }
    
    if (scalar @contents)
    {
	my $retStr = join(' ', @contents);
	return $retStr;
    }
    
    return undef;
}

sub numeric
{
    my $self = shift;
    my $primValue = shift;
    my $altValue = shift;
    
    my $setTo = (defined $primValue) ? $primValue : $altValue;
    
    if (defined $setTo)
    {
	return XML::Mini->Error("Must pass a NUMERIC value to Element::numeric() to set ($setTo)")
	    unless ($setTo =~ m/^\s*[Ee\d\.\+-]+\s*$/);
	
	$self->text($setTo);
    }
    
    
    my @contents;
    foreach my $child (@{$self->{'_children'}})
    {
	my $value = $child->getValue();
	if (defined $value)
	{
	    push @contents, $value if ($value =~ /^\s*[Ee\d\.\+-]+\s*$/);
	}
    }
    
    if (scalar @contents)
    {
	my $retStr = join(' ', @contents);
	return $retStr;
    }
    
    return undef;
}

sub comment
{
    my $self = shift;
    my $contents = shift;
    
    my $newEl = XML::Mini::Element::Comment->new();
    $newEl->text($contents);
    
    $self->appendChild($newEl);
    
    return $newEl;
}

sub header 
{
    my $self = shift;
    my $name = shift;
    my $attribs = shift; # optional
    
    unless (defined $name)
    {
    	return XML::Mini->Error("XML::Mini::Element::header() must pass a NAME to create a new header");
    }
    
    my $newElement = XML::Mini::Element::Header->new($name);
    $self->appendChild($newElement);
    
    return $newElement;
}


sub docType
{
    my $self = shift;
    my $definition = shift;
    
    my $newElement = XML::Mini::Element::DocType->new($definition);
    $self->appendChild($newElement);
    
    return $newElement;
}

sub entity
{
    my $self = shift;
    my $name = shift;
    my $value = shift;
    
    my $newElement = XML::Mini::Element::Entity->new($name, $value);
    $self->appendChild($newElement);
    
    return $newElement;
}

sub cdata
{
    my $self = shift;
    my $contents = shift;
    my $newElement = XML::Mini::Element::CData->new($contents);
    $self->appendChild($newElement);
    
    return $newElement;
}

# Note: the seperator parameter remains officially undocumented
# since I'm not sure it will remain part of the API
sub getValue {
    my $self = shift;
    my $seperator = shift || ' ';
    
    my @valArray;
    my $retStr = '';
    
    foreach my $child ( @{$self->{'_children'}})
    {
	my $value = $child->getValue();
	if (defined $value)
	{
	    push @valArray , $value;
	}
    }
    
    if (scalar @valArray)
    {
	$retStr = join($seperator, @valArray);
    }
    
    return $retStr;
}

sub getElement {
	my $self = shift;
	my $name = shift;
	my $elementNumber = shift || 1;
	
	return XML::Mini->Error("Element::getElement() Must Pass Element name.")
		unless defined ($name);
	
	if ($XML::Mini::Debug)
	{
		XML::Mini->Log("Element::getElement() called for $name on " . $self->{'_name'} );
	}
	
	
	########## getElement needs to search the calling element's children ONLY
	########## or else it is impossible to retrieve the nested element of the same name:
	########## <nested>
	##########  <nested>
	##########    The second nested element is inaccessible if we return $self...
	##########  </nested>
	########## <nested>
	#if ($XML::Mini::CaseSensitive)
	#{
		#return $self if ($self->{'_name'} =~ m/^$name$/);
	#} else {
		#return $self if ($self->{'_name'} =~ m/^$name$/i);
	#}
	
	return undef unless $self->{'_numChildren'};
	
	my $foundCount = 0;
	#* Try each child (immediate children take priority) *
	for (my $i = 0; $i < $self->{'_numChildren'}; $i++)
	{
		my $childname = $self->{'_children'}->[$i]->name();
		if ($childname)
		{
		    if ($XML::Mini::CaseSensitive)
		    {
		    	if ($name =~ m/^$childname$/)
			{
				$foundCount++;
				return $self->{'_children'}->[$i] if ($foundCount == $elementNumber);
			}
		    } else {
		    	if ($name =~ m/^$childname$/i)
			{
				$foundCount++;
				return $self->{'_children'}->[$i] if ($foundCount == $elementNumber);
			}
			    
		    }
		    
		} #/* end if child has a name */
		
	} #/* end loop over all my children */
	
	#/* Now, Use beautiful recursion, daniel san */
	for (my $i = 0; $i < $self->{'_numChildren'}; $i++)
	{
		my $theelement = $self->{'_children'}->[$i]->getElement($name, $elementNumber);
		if ($theelement)
		{
			
			XML::Mini->Log("Element::getElement() returning element " . $theelement->name())
				if ($XML::Mini::Debug);
			
			return $theelement;
		}
	}
	
	#/* Not found */
	return undef;
}

sub getElementByPath
{
    my $self = shift;
    my $path = shift || return undef;
    my @elementNumbers = @_;
    
    my @names = split ("/", $path);
    my $element = $self;
    my $position = 0;
    foreach my $elementName (@names)
    {
	next unless ($elementName);
	if ($element) #/* Make sure we didn't hit a dead end */
	{
	    #/* Ask this element to get the next child in path */
	    $element = $element->getElement($elementName, $elementNumbers[$position++]);
	}
    }
    return $element;
} #/* end method getElementByPath */


sub numChildren
{
    my $self = shift;
    my $named = shift; # optionally only count elements named 'named'
    unless (defined $named)
    {
	return $self->{'_numElementChildren'};
    }
    my $allkids = $self->getAllChildren($named);
    return scalar @{$allkids};
}

sub getAllChildren
{
    my $self = shift;
    my $name = shift; # optionally only children with this name
    
    
    my @returnChildren;
    for (my $i=0; $i < $self->{'_numChildren'}; $i++)
    {
	if ($self->isElement($self->{'_children'}->[$i]))
	{
	    my $childName = $self->{'_children'}->[$i]->name();
	    # return only Element and derivatives children
	    if (defined $name)
	    {
		if ($XML::Mini::CaseSensitive)
		{
		    push @returnChildren, $self->{'_children'}->[$i]
			if ($name =~ /^$childName$/);
		} else {
		    # case insensitive
		    push @returnChildren, $self->{'_children'}->[$i]
			if ($name =~ /^$childName$/i);
		}
	    } else {
		# no name set, all children returned
		push @returnChildren, $self->{'_children'}->[$i];
	    } # end if name
	} # end if element
    } # end loop over all children
    return \@returnChildren;
}

sub isElement
{
    my $self = shift;
    my $element = shift || $self;
    my $type = ref $element;
    return undef unless $type;
    return 0 unless ($type =~ /^XML::Mini::Element/);
    return 1;
}

sub isNode
{
    my $self = shift;
    my $element = shift || $self;
    my $type = ref $element;
    return undef unless $type;
    return 0 unless ($type =~ /^XML::Mini::Node/);
    return 1;
}


sub insertChild {
	my $self = shift;
	my $child = shift;
	my $idx = shift || 0;
	
	
	
	$self->_validateChild($child);
	

	if ($self->{'_avoidLoops'} || $XML::Mini::AutoSetParent)
	{
		if ($self->{'_parent'} == $child)
		{
			my $childName = $child->name();
	    		return XML::Mini->Error("Element::insertChild() Tryng to append parent $childName as child of " 
				    . $self->name());
		}
		$child->parent($self);
	}
	
	my $nextIdx = $self->{'_numChildren'};
	my $lastIdx = $nextIdx - 1;
	
	if ($idx > $lastIdx)
	{
	
		if ($idx > $nextIdx)
		{
			$idx = $lastIdx + 1;
		}
		$self->{'_children'}->[$idx] = $child;
		$self->{'_numChildren'}++;
		$self->{'_numElementChildren'}++ if ($self->isElement($child));
		
	} elsif ($idx >= 0)
	{
		my @removed = splice(@{$self->{'_children'}}, $idx);
		push @{$self->{'_children'}}, ($child, @removed);
		
		$self->{'_numChildren'}++;
		$self->{'_numElementChildren'}++ if ($self->isElement($child));
	} else {
		my $revIdx = (-1 * $idx) % $self->{'_numChildren'};
		my $newIdx = $self->{'_numChildren'} - $revIdx;
		
		if ($newIdx < 0)
		{
			return XML::Mini->Error("Element::insertChild() Ended up with a negative index? ($newIdx)");
		}
		
		return $self->insertChild($child, $newIdx);
	}
		
	return $child;
}
	

sub appendChild
{
	my $self = shift;
	my $child = shift;
	
	$self->_validateChild($child);
	
	if ($self->{'_avoidLoops'} || $XML::Mini::AutoSetParent)
	{
		if ($self->{'_parent'} == $child)
		{
			my $childName = $child->name();
	    		return XML::Mini->Error("Element::appendChild() Tryng to append parent $childName as child of " 
				    . $self->name());
		}
		$child->parent($self);
	}
	
	$self->{'_numElementChildren'}++; #Note that we're addind a Element child 
	
	my $idx = $self->{'_numChildren'}++;
	$self->{'_children'}->[$idx] = $child;
	
	return $self->{'_children'}->[$idx];
}

sub prependChild 
{
	my $self = shift;
	my $child = shift;
	
	$self->_validateChild($child);
	
	if ($self->{'_avoidLoops'} || $XML::Mini::AutoSetParent)
	{
		if ($self->{'_parent'} == $child)
		{
			my $childName = $child->name();
	    		return XML::Mini->Error("Element::appendChild() Tryng to append parent $childName as child of " 
				    . $self->name());
		}
		$child->parent($self);
	}
	
	$self->{'_numElementChildren'}++; #Note that we're addind a Element child 
	
	my $idx = $self->{'_numChildren'}++;
	unshift(@{$self->{'_children'}}, $child);
	
	return $self->{'_children'}->[0];
}
	

sub createChild
{
    my $self = shift;
    my $name = shift;
    my $value = shift; # optionally fill child with 
    
    unless (defined $name)
    {
	return XML::Mini->Error("Element::createChild() Must pass a NAME to createChild.");
    }
    
    my $child = XML::Mini::Element->new($name);
    
    $child = $self->appendChild($child);
    
    if (defined $value)
    {
	if ($value =~ m/^\s*[Ee\d\.\+-]+\s*$/)
	{
	    $child->numeric($value);
	} else {
	    $child->text($value);
	}
    }
    
    $child->avoidLoops($self->{'_avoidLoops'});
    
    return $child;
}


sub _validateChild {
	my $self = shift;
	my $child = shift;
	
	
	return XML::Mini->Error("Element:_validateChild() need to pass a non-NULL Element child")
		unless (defined $child);
	
	return XML::Mini->Error("Element::_validateChild() must pass an Element object to appendChild.")
		unless ($self->isElement($child));
	
	
	my $childName = $child->name();
	
	return XML::Mini->Error("Element::_validateChild() children must be named")
		unless (defined $childName);
	
	if ($child == $self)
	{
		return XML::Mini->Error("Element::_validateChild() Trying to append self as own child!");
	} elsif ( $self->{'_avoidLoops'} && $child->parent())
	{
	
		return XML::Mini->Error("Element::_validateChild() Trying to append a child ($childName) that already has a parent set "
		. "while avoidLoops is on - aborting");
	}
	
	return 1;
}


sub removeChild {
	my $self = shift;
	my $child = shift;
	
	unless (defined $child)
	{
		XML::Mini->Log("Element::removeChild() called without an ELEMENT parameter.");
		return undef;
	}
	
	unless ($self->{'_numChildren'})
	{
		return XML::Mini->Error("Element::removeChild() called for element without any children.");
	}
	
	my $childType = ref $child;
	unless ($childType && $childType =~ /XML::Mini::/)
	{
		# name of the child...
		# try to find it...
		my $el = $self->getElement($child);
		
		return XML::Mini->Error("Element::removeChild() called with element _name_ $child, but could not find any such element")
				unless ($el);
		
		$child = $el;
	}
	
	my $foundChild;
	my $idx = 0;
	while ($idx < $self->{'_numChildren'} && ! $foundChild)
	{
		if ($self->{'_children'}->[$idx] == $child)
		{
			$foundChild = $self->{'_children'}->[$idx];
		} else {
			$idx++;
		}
	}
	
	unless ($foundChild)
	{
		XML::Mini->Log("Element::removeChild() No matching child found.") if ($XML::Mini::Debug);
		return undef;
	}
	
	splice @{$self->{'_children'}}, $idx, 1;
	$self->{'_numChildren'}--;
	if ($foundChild->isElement())
	{
		$self->{'_numElementChildren'}--;
	}
	
	delete $foundChild->{'_parent'} ;
	return $foundChild;
}

sub removeAllChildren {
	my $self = shift;
	
	return undef unless ($self->{'_numChildren'});
	
	my $retList = $self->{'_children'};
	delete $self->{'_children'};
	$self->{'_numElementChildren'} = 0;
	$self->{'_numChildren'} = 0;
	
	foreach my $child (@{$retList})
	{
		delete $child->{'_parent'};
	}
	
	delete $self->{'_children'};
	$self->{'children'} = [];
	
	return $retList;
}

sub remove {
	my $self = shift;
	
	my $parent = $self->parent();
	
	unless ($parent)
	{
		XML::Mini->Log("XML::Mini::Element::remove() called for element with no parent set.  Aborting.");
		return undef;
	}
	
	my $removed = $parent->removeChild($self);
	
	return $removed;
}
	
sub parent {
    my $self = shift;
    my $parent = shift; # optionally set
    
    if (defined $parent)
    {
	return XML::Mini->Error("Element::parent(): Must pass an instance of Element to set.")
	    unless ($self->isElement($parent));
	$self->{'_parent'} = $parent;
    }
    return $self->{'_parent'};
}
		
sub avoidLoops
{
    my $self = shift;
    my $setTo = shift; # optionally set
    if (defined $setTo)
    {
	$self->{'_avoidLoops'} = $setTo;
    }
    return $self->{'_avoidLoops'};
}


sub toStructure {
	my $self = shift;
	
	
	my $retHash = {};
	my $contents = "";
	my $numAdded = 0;
	if ($self->{'_attributes'})
	{
		while (my ($attname, $attvalue) = each %{$self->{'_attributes'}})
		{
			$retHash->{$attname} = $attvalue;
			$numAdded++;
		}
	}
	
	my $numChildren = $self->{'_numChildren'} || 0;
	for (my $i=0; $i < $numChildren ; $i++)
	{
		my $thisChild = $self->{'_children'}->[$i];
		if ($self->isElement($thisChild))
		{
			my $name = $thisChild->name();
			my $struct = $thisChild->toStructure();
			my $existing = $retHash->{$name};
			
			if ($existing)
			{
				my $existingType = ref $existing || "";
				if ($existingType eq 'ARRAY')
				{
					push @{$existing}, $struct;
				} else {
					my $arrayRef = [$existing, $struct];
					$retHash->{$name} = $arrayRef;
				}
			} else {
				
				$retHash->{$name} = $struct;
			}
			
			
			$numAdded++;
			
		} else {
			$contents .= $thisChild->getValue();
		}
	}
	
	if ($numAdded)
	{
		if (length($contents))
		{
			$retHash->{'-content'} = $contents;
		}
		
		return $retHash;
	} else {
		return $contents;
	}

}


sub toString
{ 
    my $self = shift;
    my $depth = shift || 0;

    if ($depth == $XML::Mini::NoWhiteSpaces)
    {
	return $self->toStringNoWhiteSpaces();
    }
    
    my $retString;
    my $attribString = '';
    my $elementName = $self->{'_name'};
    my $spaces = $self->_spaceStr($depth);
    
    foreach my $atName (sort keys %{$self->{'_attributes'}})
    {
	$attribString .= qq|$atName="$self->{'_attributes'}->{$atName}" |;
    }
    
    $retString = "$spaces<$elementName";
    
    if ($attribString)
    {
	$attribString =~ s/\s*$//;
	$retString .= " $attribString";
    }
    
    if (! $self->{'_numChildren'})
    {
		$retString .= " />\n";
		return $retString;
    }
    
    # Else, we do have kids - sub element or nodes
    
    my $allChildrenAreNodes = 1;
    
    my $i=0;
    while ($allChildrenAreNodes && $i < $self->{'_numChildren'})
    {
    	$allChildrenAreNodes = 0 unless ($self->isNode($self->{'_children'}->[$i]));
    	$i++;
    }
    
    
    $retString .= ">";
    $retString .= "\n" unless ($allChildrenAreNodes);
   
    
    my $nextDepth = $depth + 1;
    
    for($i=0; $i < $self->{'_numChildren'}; $i++)
    {
	my $newStr = $self->{'_children'}->[$i]->toString($nextDepth);
	if (defined $newStr)
	{
	    if ( ! ($allChildrenAreNodes  || $newStr =~ m|\n$|) )
	    {
		$newStr .= "\n";
	    }
	    
	    $retString .= $newStr;
	} # end if newStr returned
    } # end loop over all children
    
    $retString .= "$spaces" unless ($allChildrenAreNodes);
    
    $retString .= "</$elementName>\n";
    return $retString;
}

sub toStringNoWhiteSpaces
{
    my $self = shift;
    
    my $retString;
    my $attribString = '';
    my $elementName = $self->{'_name'};
    
    while (my ($atName, $atVal) = each %{$self->{'_attributes'}})
    {
	$attribString .= qq|$atName="$atVal" |;
    }
    
    $retString = "<$elementName";
    
    if ($attribString)
    {
	$attribString =~ s/\s*$//;
	$retString .= " $attribString";
    }
    
    if (! $self->{'_numChildren'})
    {
	$retString .= '/>';
	return $retString;
    }
    
    # Else, we do have kids - sub element or nodes
    
    $retString .= '>';
    
    for(my $i=0; $i < $self->{'_numChildren'}; $i++)
    {
	my $newStr = $self->{'_children'}->[$i]->toStringNoWhiteSpaces();
	$retString .= $newStr if (defined $newStr);
    } # end loop over all children

    $retString .= "</$elementName>";
    return $retString;
}

sub createNode
{
    my $self = shift;
    my $value = shift;
    
    my $newNode = XML::Mini::Node->new($value);
    return undef unless ($newNode);
    
    my $appendedNode = $self->appendNode($newNode);
    return $appendedNode;
}

sub appendNode
{
    my $self = shift;
    my $node = shift;
    
    return XML::Mini->Error("Element::appendNode() need to pass a non-NULL XML::MiniNode.")
	unless (defined $node);
    
    return XML::Mini->Error("Element::appendNode() must pass a XML::MiniNode object to appendNode.")
	unless ($self->isNode($node));
    
    
    
    if ($XML::Mini::AutoSetParent)
    {
	$node->parent($self);
    }
    
    if ($XML::Mini::Debug)
    {
	XML::Mini->Log("Appending node to " . $self->{'_name'});
      }
    
    my $idx = $self->{'_numChildren'}++;
    $self->{'_children'}->[$idx] = $node;
    
    return $self->{'_children'}->[$idx];
}

1;

__END__

=head1 NAME

XML::Mini::Element - Perl implementation of the XML::Mini Element API.

=head1 SYNOPSIS

	use XML::Mini::Document;
	
	my $xmlDoc = XML::Mini::Document->new();
	
	# Fetch the ROOT element for the document
	# (an instance of XML::Mini::Element)
	my $xmlElement = $xmlDoc->getRoot();
	
	# Create an <?xml?> tag
	my $xmlHeader = $xmlElement->header('xml');
	
	# add the version to get <?xml version="1.0"?>
	$xmlHeader->attribute('version', '1.0');
	
	# Create a sub element
	my $newChild = $xmlElement->createChild('mychild');
	
	$newChild->text('hello mommy');
	
	
	# Create an orphan element
	
	my $orphan = $xmlDoc->createElement('annie');
	
	$orphan->attribute('hair', '#ff0000');
	$orphan->text('tomorrow, tomorrow');
	
	# Adopt the orphan
	$newChild->appendChild($orphan);
	
	
	# ...
	# add a child element to the front of the list 
	$xmlElement->prependChild($otherElement);
	
	print $xmlDoc->toString();
	


The code above would output:

 
<?xml version="1.0" ?>
 <mychild>
  hello mommy
  <annie hair="#ff0000">
   tomorrow, tomorrow
  </annie>
 </mychild>

=head1 DESCRIPTION

Although the main handle to the xml document is the XML::Mini::Document object,
much of the functionality and manipulation involves interaction with
Element objects.

A Element 
has:

 - a name
 - a list of 0 or more attributes (which have a name and a value)
 - a list of 0 or more children (Element or XML::MiniNode objects)
 - a parent (optional, only if MINIXML_AUTOSETPARENT > 0)

=head2 new NAME

Creates a new instance of XML::Mini::Element, with name NAME

=head2 name [NEWNAME]

If a NEWNAME string is passed, the Element's name is set 
to NEWNAME.

Returns the element's name.

=head2 attribute NAME [SETTO [SETTOALT]]


The attribute() method is used to get and set the 
Element's attributes (ie the name/value pairs contained
within the tag, <tagname attrib1="value1" attrib2="value2">)

If SETTO is passed, the attribute's value is set to SETTO.

If the optional SETTOALT is passed and SETTO is false, the 
attribute's value is set to SETTOALT.  This is usefull in cases
when you wish to set the attribute to a default value if no SETTO is
present, eg $myelement->attribute('href', $theHref, 'http://psychogenic.com')
will default to 'http://psychogenic.com'.


Returns the value associated with attribute NAME.

=head2 text [SETTO [SETTOALT]]

The text() method is used to get or append text data to this
element (it is appended to the child list as a new XML::MiniNode object).

If SETTO is passed, a new node is created, filled with SETTO 
and appended to the list of this element's children.

If the optional SETTOALT is passed and SETTO is false, the 
new node's value is set to SETTOALT.  See the attribute() method
for an example use.

Returns a string composed of all child XML::MiniNodes' contents.
 

Note: all the children XML::MiniNodes' contents - including numeric 
nodes are included in the return string.


=head2 numeric [SETTO [SETTOALT]]

The numeric() method is used to get or append numeric data to
this element (it is appended to the child list as a XML::MiniNode object).

If SETTO is passed, a new node is created, filled with SETTO 
and appended to the list of this element's children.

If the optional SETTOALT is passed and SETTO is false, the 
new node's value is set to SETTOALT.  See the attribute() method
for an example use.

Returns a space seperated string composed all child XML::MiniNodes' 
numeric contents.

Note: ONLY numerical contents are included from the list of child XML::MiniNodes.

=head2 header NAME

The header() method allows you to add a new XML::Mini::Element::Header to this 
element's list of children.

Headers return a <? NAME ?> string for the element's toString() method.  Attributes
may be set using attribute(), to create headers like
<?xml-stylesheet href="doc.xsl" type="text/xsl"?>

Valid XML documents must have at least an 'xml' header, like:
<?xml version="1.0" ?>

Here's how you could begin creating an XML document:

 

	my $miniXMLDoc =  XML::Mini::Document->new();
	my $xmlRootNode = $miniXMLDoc->getRoot();
	my $xmlHeader = $xmlRootNode->header('xml');
	$xmlHeader->attribute('version', '1.0');

This method was added in version 1.25.

=head2 comment CONTENTS

The comment() method allows you to add a new XML::Mini::Element::Comment to this
element's list of children.

Comments will return a <!-- CONTENTS --> string when the element's toString()
method is called.

Returns a reference to the newly appended XML::Mini::Element::Comment

=head2 docType DEFINITION

Append a new <!DOCTYPE DEFINITION [ ...]> element as a child of this 
element.

Returns the appended DOCTYPE element. You will normally use the returned
element to add ENTITY elements, like

 my $newDocType = $xmlRoot->docType('spec SYSTEM "spec.dtd"');
 $newDocType->entity('doc.audience', 'public review and discussion');

=head2 entity NAME VALUE

Append a new <!ENTITY NAME "VALUE"> element as a child of this 
element.

Returns the appended ENTITY element.

=head2 cdata CONTENTS

Append a new <![CDATA[ CONTENTS ]]> element as a child of this element.
Returns the appended CDATA element.

=head2 getValue

Returns a string containing the value of all the element's
child XML::MiniNodes (and all the XML::MiniNodes contained within 
it's child Elements, recursively).


=head2 getElement NAME [POSITION]

Searches the element and it's children for an element with name NAME.

Returns a reference to the first Element with name NAME,
if found, NULL otherwise.

NOTE: The search is performed like this, returning the first 
	 element that matches:
 

 - Check this element's immediate children (in order) for a match.
 - Ask each immediate child (in order) to Element::getElement()
  (each child will then proceed similarly, checking all it's immediate
  children in order and then asking them to getElement())


If a numeric POSITION parameter is passed, getElement() will return 
the POSITIONth element of name NAME (starting at 1).  Thus, on document
 

  <?xml version="1.0"?>
  <people>
   <person>
    bob
   </person>
   <person>
    jane
   </person>
   <person>
    ralph
   </person>
  </people>

$people->getElement('person') will return the element containing the text node
'bob', while $people->getElement('person', 3) will return the element containing the 
text 'ralph'.




=head2 getElementByPath PATH [POSITIONSARRAY]


Attempts to return a reference to the (first) element at PATH
where PATH is the path in the structure (relative to this element) to
the requested element.

For example, in the document represented by:

	 <partRateRequest>
	  <vendor>
	   <accessid user="myusername" password="mypassword" />
	  </vendor>
	  <partList>
	   <partNum>
	    DA42
	   </partNum>
	   <partNum>
	    D99983FFF
	   </partNum>
	   <partNum>
	    ss-839uent
	   </partNum>
	  </partList>
	 </partRateRequest>

	$partRate = $xmlDocument->getElement('partRateRequest');

	$accessid = $partRate->getElementByPath('vendor/accessid');

Will return what you expect (the accessid element with attributes user = "myusername"
and password = "mypassword").

BUT be careful:
	$accessid = $partRate->getElementByPath('partList/partNum');

will return the partNum element with the value "DA42".   To access other partNum elements you
must either use the POSITIONSARRAY or the getAllChildren() method on the partRateRequest element.

POSITIONSARRAY functions like the POSITION parameter to getElement(), but instead of specifying the
position of a single element, you must indicate the position of all elements in the path.  Therefore, to
get the third part number element, you would use

	my $thirdPart = $xmlDocument->getElementByPath('partRateRequest/partList/partNum', 1, 1, 3);
	
The additional 1,1,3 parameters indicate that you wish to retrieve the 1st partRateRequest element in 
the document, the 1st partList child of partRateRequest and the 3rd partNum child of the partList element
(in this instance, the partNum element that contains 'ss-839uent').

Returns the Element reference if found, NULL otherwise.

=head2 getAllChildren [NAME]

Returns a reference to an array of all this element's Element children

Note: although the Element may contain XML::MiniNodes as children, these are
not part of the returned list.


=head2 createChild ELEMENTNAME [VALUE]

Creates a new Element instance and appends it to the list
of this element's children.
The new child element's name is set to ELEMENTNAME.

If the optional VALUE (string or numeric) parameter is passed,
the new element's text/numeric content will be set using VALUE.

Returns a reference to the new child element


=head2 appendChild CHILDELEMENT

appendChild is used to append an existing Element object to
this element's list.

Returns a reference to the appended child element.

NOTE: Be careful not to create loops in the hierarchy, eg

 $parent->appendChild($child);
 $child->appendChild($subChild);
 $subChild->appendChild($parent);

If you want to be sure to avoid loops, set the MINIXML_AVOIDLOOPS define
to 1 or use the avoidLoops() method (will apply to all children added with createChild())


=head2 prependChild CHILDELEMENT

prependChild is used to add an existing Element object to
this element's list.  The added CHILDELEMENT will be prepended to the list, thus
it will appear first in the XML output.

Returns a reference to the prepended child element.

See the note about creating loops in the above appendChild() description.


=head2 insertChild CHILDELEMENT INDEX

Inserts the child element at a specific location in this elements list of children.

If INDEX is larger than numChildren(), the CHILDELEMENT will be added to the end of
the list (same as appendChild() ).

Returns the inserted child element.

=head2 removeChild CHILDELEMENT

Removes the element CHILDELEMENT from the list of this element's children, if it is 
found within this list.

Returns the child element that was removed, else undef.

=head2 removeAllChildren 

Clears the element's list of child elements.  Returns an array ref of child elements 
that were removed.


=head2 remove

Removes this element from it's parent's list of children.  The parent must be set for the 
element for this method to work - this can be done manually using the parent() method or 
automatically if  $XML::Mini::AutoSetParent is true (set to false by default).




=head2 parent NEWPARENT

The parent() method is used to get/set the element's parent.

If the NEWPARENT parameter is passed, sets the parent to NEWPARENT
(NEWPARENT must be an instance of Element)

Returns a reference to the parent Element if set, NULL otherwise.

Note: This method is mainly used internally and you wouldn't normally need
to use it.
It get's called on element appends when $XML::Mini::AutoSetParent or 
$XML::Mini::AvoidLoops or avoidLoops() > 0

=head2 avoidLoops SETTO

The avoidLoops() method is used to get or set the avoidLoops flag for this element.

When avoidLoops is true, children with parents already set can NOT be appended to any
other elements.  This is overkill but it is a quick and easy way to avoid infinite loops
in the heirarchy.

The avoidLoops default behavior is configured with the $XML::Mini::AvoidLoops variable but can be
set on individual elements (and automagically all the element's children) with the 
avoidLoops() method.

Returns the current value of the avoidLoops flag for the element.

=head2 toString [SPACEOFFSET]

toString returns an XML string based on the element's attributes,
and content (recursively doing the same for all children)

The optional SPACEOFFSET parameter sets the number of spaces to use
after newlines for elements at this level (adding 1 space per level in
depth).  SPACEOFFSET defaults to 0.

If SPACEOFFSET is passed as $XML::Mini::NoWhiteSpaces  
no \n or whitespaces will be inserted in the xml string
(ie it will all be on a single line with no spaces between the tags.

Returns the XML string.

=head2 createNode NODEVALUE


Private (?)

Creates a new XML::MiniNode instance and appends it to the list
of this element's children.
The new child node's value is set to NODEVALUE.

Returns a reference to the new child node.

Note: You don't need to use this method normally - it is used
internally when appending text() and such data.

=head2 appendNode CHILDNODE


appendNode is used to append an existing XML::MiniNode object to
this element's list.

Returns a reference to the appended child node.


Note: You don't need to use this method normally - it is used
internally when appending text() and such data.

=head1 AUTHOR


Copyright (C) 2002-2008 Patrick Deegan, Psychogenic Inc.

Programs that use this code are bound to the terms and conditions of the GNU GPL (see the LICENSE file). 
If you wish to include these modules in non-GPL code, you need prior written authorisation 
from the authors.


This library is released under the terms of the GNU GPL version 3, making it available only for 
free programs ("free" here being used in the sense of the GPL, see http://www.gnu.org for more details). 
Anyone wishing to use this library within a proprietary or otherwise non-GPLed program MUST contact psychogenic.com to 
acquire a distinct license for their application.  This approach encourages the use of free software 
while allowing for proprietary solutions that support further development.


=head2 LICENSE

    XML::Mini::Element module, part of the XML::Mini XML parser/generator package.
    Copyright (C) 2002-2008 Patrick Deegan
    All rights reserved
    
    XML::Mini is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    XML::Mini is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with XML::Mini.  If not, see <http://www.gnu.org/licenses/>.


Official XML::Mini site: http://minixml.psychogenic.com

Contact page for author available on http://www.psychogenic.com/


=head1 SEE ALSO


XML::Mini, XML::Mini::Document

http://minixml.psychogenic.com

=cut
