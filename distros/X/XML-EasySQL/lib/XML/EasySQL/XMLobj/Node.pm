=head1 NAME

XML::EasySQL::XMLobj::Node - Node interface. Derived from a fork of Robert Hanson's killer XML::EasyOBJ module, which offers Easy XML object navigation

=head1 VERSION

Version 1.2

=head1 METHODS

=cut

package XML::EasySQL::XMLobj::Node;

use XML::DOM;
use strict;

use vars qw/$VERSION/;
$VERSION = '1.2';

use vars qw/$AUTOLOAD/;

sub new {
        my $proto = shift;
        my $params = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
	$self->{doc} = $params->{doc};
	$self->{ptr} = $params->{ptr};
	if(defined $params->{constructor_params}) {
		$self->{constructor_params} = $params->{constructor_params};
	} else {
		$self->{constructor_params} = {};
	}
	bless $self, $class;
}

$AUTOLOAD = '';

sub DESTROY {
	local $^W = 0;
	my $self = $_[0];
	$_[0] = '';
	unless ( $_[0] ) {
		$_[0] = $self;
		$AUTOLOAD = 'DESTROY';
		return AUTOLOAD( @_ );
	}
}

sub AUTOLOAD {
	my $funcname = $AUTOLOAD || 'AUTOLOAD';
	$funcname =~ s/.*:://;
	$AUTOLOAD = '';

	my $self = shift;
	my $index = shift;
	my @nodes = ();

	die "Fatal error: lost pointer!" unless ( exists $self->{ptr} );

	for my $kid ( $self->{ptr}->getChildNodes ) {
		if ( ( $kid->getNodeType == ELEMENT_NODE ) && ( $kid->getTagName eq $funcname ) ) {
			my $node = $self->makeNewNode(undef, $kid);
			push (@nodes, $node);
		}
	}

	if ( wantarray ) {
		return @nodes;
	} else {
		if ( defined $index ) {
			unless ( defined $nodes[$index] ) {
				for ( my $i = scalar(@nodes); $i <= $index; $i++ ) {
					my $node = $self->makeNewNode($funcname);
					$nodes[$i] = $node;
				} 
			}
			return $nodes[$index];
		} else {
			if(!defined $nodes[0]) {
;
				my $node = $self->makeNewNode($funcname);
				return $node;
			}
			return $nodes[0];
		}
	}
}

=head2 makeNewNode( NEW_TAG )

Append a new element node to the current node. Takes the tag name
as the parameter and returns the created node as a convienence.

 my $p_element = $doc->body->makeNewNode('p');

=cut

sub makeNewNode {
        my $self = shift;
        my $tag = shift;
	my $new_ptr = shift;
	if(!ref $new_ptr) {
		$new_ptr = $self->{ptr}->appendChild( $self->{doc}->createElement($tag) );
	}
	my %constructor_params_copy = %{$self->{constructor_params}};
	$constructor_params_copy{doc} = $self->{doc};
	$constructor_params_copy{ptr} = $new_ptr;
	$constructor_params_copy{constructor_params} = $self->{constructor_params};
	my $node = $self->new(\%constructor_params_copy);
        return $node;
}

=head2 getString( )

Recursively extracts text from the current node and all children
element nodes. Returns the extracted text as a single scalar value.

=cut

sub getString {
	my $self = shift;
	die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );
	return $self->_extractText( $self->{ptr} );
}

=head2 _extractText( )

Utility method. Don't call this and don't overload it.

=cut

sub _extractText {
	my $self = shift;
	my $n = shift;
	my $text = '';

	if ( $n->getNodeType == TEXT_NODE ) {
		$text = $n->toString;
	} elsif ( $n->getNodeType == ELEMENT_NODE ) {
		foreach my $c ( $n->getChildNodes ) {
			$text .= $self->_extractText($c);
		}
	}
	return $text;
}


=head2 setString( STRING )

Sets the text value of the specified element. This is done by
first removing all text node children of the current element
and then appending the supplied text as a new child element.

Take this XML fragment and code for example:

<p>This elment has <b>text</b> and <i>child</i> elements</p>

 $doc->p->setString('This is the new text');

This will change the fragment to this:

<p><b>text</b><i>child</i>This is the new text</p>

Because the <b> and <i> tags are not text nodes they are left
unchanged, and the new text is added at the end of the specified
element.

If you need more specific control on the change you should
either use the getDomObj() method and use the DOM methods
directly or remove all of the child nodes and rebuild the
<p> element from scratch.  Also see the addString() method.

=cut

sub setString {
	my $self = shift;
	my $text = shift;

	die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );

	foreach my $n ( $self->{ptr}->getChildNodes ) {
		if ( $n->getNodeType == TEXT_NODE ) {
			$self->{ptr}->removeChild( $n );
		}
	}

	$self->{ptr}->appendChild( $self->{doc}->createTextNode( $text ) );
	return $self->_extractText( $self->{ptr} );
}


=head2 addString( STRING )

Adds to the the text value of the specified element. This
is done by appending the supplied text as a new child element.

Take this XML fragment and code for example:

<p>This elment has <b>text</b></p>

 $doc->p->addString(' and elements');

This will change the fragment to this:

<p>This elment has <b>text</b> and elements</p>

=cut

sub addString {
	my $self = shift;
	my $text = shift;

	die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );

	$self->{ptr}->appendChild( $self->{doc}->createTextNode( $text ) );
	return $self->_extractText( $self->{ptr} );
};


=head2 getAttr( ATTR_NAME )

Returns the value of the named attribute.

 my $val = $doc->body->img->getAttr('src');

=cut

sub getAttr {
	my $self = shift;
	my $attr = shift;

	die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );

	if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
		return $self->{ptr}->getAttribute($attr);
	}
	return '';
}

=head2 getTagName( )

Returns the tag name of the specified element. This method is
useful when you are enumerating child elements and do not
know their element names.

 foreach my $element ( $doc->getElement() ) {
    print $element->getTagName();
 }

=cut

sub getTagName {
	my $self = shift;
      
	die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );

	if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
		return $self->{ptr}->getTagName;
	}
	return '';
}

=head2 setAttr( ATTR_NAME, ATTR_VALUE, [ATTR_NAME, ATTR_VALUE]... )

For each name/value pair passed the attribute name and value will
be set for the specified element.

=cut

sub setAttr {
	my $self = shift;
	my %attr = @_;

	die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );

	if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
		if ( scalar(keys %attr) == 1 ) {
			for ( keys %attr ) {
				return $self->{ptr}->setAttribute($_, $attr{$_});
			}
		} else {
			for ( keys %attr ) {
				$self->{ptr}->setAttribute($_, $attr{$_});
			}
			return 1;
		}
	}
	return '';
}

=head2 remAttr( ATTR_NAME )

Removes the specified attribute from the current element.

=cut

sub remAttr {
	my $self = shift;
	my $attr = shift;
      
	die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );

	if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
		if ( $self->{ptr}->getAttributes->getNamedItem( $attr ) ) {
			$self->{ptr}->getAttributes->removeNamedItem( $attr );
			return 1;
		}
	}
	return 0;
}

=head2 remElement( TAG_NAME, INDEX )

Removes a child element of the current element. The name of the
child element and the index must be supplied.  An index of 0
will remove the first occurance of the named element, 1 the second,
2 the third, etc.

=cut

sub remElement {
	my $self = shift;
	my $name = shift;
	my $index = shift;
      
	my $node = ( $index ) ? $self->$name($index) : $self->$name();
	$self->{ptr}->removeChild( $node->{ptr} );
}

=head2 getElement( TAG_NAME, INDEX )

Returns the node from the tag name and index. If no index is
given the first child with that name is returned. Use this
method when you have element names that include characters that
are not legal as a perl method name.  For example:

 <foo> <!-- root element -->
  <bar>
   <foo-bar>test</foo-bar>
  </bar>
 </foo>

 # "foo-bar" is not a legal method name
 print $doc->bar->getElement('foo-bar')->getString();

=cut

sub getElement {
	my $self = shift;
	my $funcname = shift;
	my $index = shift;
	my @nodes = ();

	die "Fatal error: lost pointer!" unless ( exists $self->{ptr} );

	foreach my $kid ( $self->{ptr}->getChildNodes ) {
		if ( $funcname ) {
			if ( ( $kid->getNodeType == ELEMENT_NODE ) && ( $kid->getTagName eq $funcname ) ) {
				my $node = $self->makeNewNode(undef, $kid);
				push (@nodes, $node);
			}
		} else {
			if ( $kid->getNodeType == ELEMENT_NODE ) {
				my $node = $self->makeNewNode(undef, $kid);
				push (@nodes, $node);
			}
		}
	}
      
	if ( wantarray ) {
		return @nodes;
	} else {
		$index = 0 unless ( defined $index );

		if ( defined $nodes[$index] ) {
			return $nodes[$index];
		} else {
			# fail if no tag name given
			return undef unless ( $funcname );
			for ( my $i = scalar(@nodes); $i <= $index; $i++ ) {
				my $node = $self->makeNewNode($funcname);
				$nodes[$i] = $node;
			}
			return $nodes[$index];
		}
	}
}

=head1 getDomObj( )

Returns the DOM object associated with the current node. This
is useful when you need fine access via the DOM to perform
a specific function.

=cut

sub getDomObj {
	my $self = shift;
	return $self->{ptr};
}

1;

