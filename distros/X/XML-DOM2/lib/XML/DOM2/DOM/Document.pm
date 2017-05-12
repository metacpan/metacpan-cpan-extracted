package XML::DOM2::DOM::Document;

use strict;
use warnings;

=head1 NAME

  XML::DOM2::DOM::Document

=head1 DESCRIPTION

  Base class for document objects, extends the DOM with document specific methods.

=head1 METHODS

=cut

use XML::DOM2::Element::DocumentType;
use XML::DOM2::Attribute::Namespace;
use XML::DOM2;
use Carp;

=head2 $class->createDocumentType( $qualifiedName, $publicId, $systemId, $dtd )

  Create a new XML Document Type.

=cut
sub createDocumentType
{
	my ($self, $qualifiedName, $publicId, $systemId, $dtd) = @_;
	my $doctype = XML::DOM2::Element::DocumentType->new(
		name     => $qualifiedName,
		publicid => $publicId,
		systemid => $systemId,
		dtd      => $dtd,
	);
	return $doctype;
}

=head2 $class->createDocument( $namespaceURI, $qualifiedName, $doctype )

  Creates a new XML Document.

=cut
sub createDocument
{
	my ($proto, $namespaceURI, $qualifiedName, $doctype) = @_;
	my $class = ref $proto || $proto;
	$doctype ||= XML::DOM2->createDocumentType;
	my $document = $class->new(
		namespace   => $namespaceURI,
		name        => $qualifiedName,
		doctype     => $doctype,
	);
	$doctype->ownerDocument($document);
	return $document;
}

=head2 $document->documentElement()

  Returns the main document as an element! it's no longer a document object.

=cut
sub documentElement
{
	my ($self, $setObj) = @_;
	if(not $self->{'element'}) {
		if($setObj) {
			confess "New Document element has no tag name" if not $setObj->localName;
			$self->{'element'} = $setObj;
			if(ref($setObj) eq 'XML::DOM2::Element::Document') {
				$self->{'fragment'} = 1;
			}
		} else {
	        $self->{'element'} = $self->createElement(
				'#document',
				document => $self,
				documentTag => $self->_document_name
			);
			if($self->{'namespace'}) {
				$self->{'element'}->setAttribute( 'xmlns', $self->{'namespace'} );
			} 
		}
	}
	return $self->{'element'};
}

=head2 $document->documentType()

  Returns a document type object for this document.

=cut
sub documentType
{
	my ($self) = @_;
#	if(not $self->{'doctype'}) {
#		$self->{'doctype'} = $self->createDocumentType();
#	}
	return $self->{'doctype'};
}

=head2 $document->addId( $id, $element )

  Adds an id of an element, used internaly.

=cut
sub addId
{
	my ($self, $id, $tag) = @_;
	if(not defined($self->{'idlist'})) {
	    $self->{'idlist'} = {};
	}
	if(not defined($self->{'idlist'}->{$id})) {
	    $self->{'idlist'}->{$id} = $tag;
	    return 1;
	}
	return undef;
}

=head2 $document->removeId( $id )

  Removes an id of an element, used internaly.

=cut
sub removeId
{
	my ($self, $id) = @_;
	return delete($self->{'idlist'}->{$id});
}

=head2 $document->getElementById( $id )

  Returns the element with that id in this document.

=cut
sub getElementById
{
	my ($self, $id)=@_;
	return undef unless defined($id);
	my $idlist = $self->{'idlist'};
	if (exists $idlist->{$id}) {
	    return $idlist->{$id};
	}
	return undef;
}

=head2 $document->addElement( $element )

  Adds an element to the elements list, used internaly.

=cut
sub addElement
{
	my ($self, $tag) = @_;
	my $name = $tag->localName;
	if(not defined($self->{'elist'})) {
	    $self->{'elist'} = {};
	}
	if(not defined($self->{'elist'}->{$name})) {
	    $self->{'elist'}->{$name} = [];
	}
	$tag->{'tagindex'} = @{$self->{'elist'}->{$name}};
	push @{$self->{'elist'}->{$name}}, $tag;
	return 1;
}

=head2 $document->removeElement( $element )

  Remove the specified element from the elements list, used internaly.

=cut
sub removeElement
{
	my ($self, $tag) = @_;
	my $name = $tag->getElementName;
	splice @{$self->{'elist'}->{$name}}, $tag->{'tagindex'}, 1;
	# Remove the elist name if no nodes;
	# this keeps getElementNames function consistant
	delete($self->{'elist'}->{$name}) unless @{$self->{'elist'}->{$name}};
}

=head2 $document->getElements( $type )

=head2 $document->getElementsByType( $type )

=head2 $document->getElementsByName( $type )

  Get all elements of the specified type/tagName; if none is specified, get all elements in document.

=cut
sub getElements
{
	my ($self, $element) = @_;
	return undef unless exists $self->{'elist'};

	my $elist = $self->{'elist'};
	if (defined $element) {
		if (exists $elist->{$element}) {
			return wantarray?@{$elist->{$element}}:
				$elist->{$element};
		}
		return wantarray?():undef;
	} else {
		# Return all elements for all types
		my @elements;
		foreach my $element_type (keys %$elist) {
			push @elements,@{$elist->{$element_type}};
		}
		return wantarray?@elements:\@elements;
	}
}
*getElementsByType=\&getElements;
*getElementsByName=\&getElements;

=head2 $document->getElementNames()

=head2 $document->getElementTypes()

  Get all the element types in use in the document.

=cut
sub getElementNames
{
	my $self = shift;
	my @types = keys %{$self->{'elist'}};

	return wantarray ? @types : \@types;
}
*getElementTypes=\&getElementNames;

=head2 $document->addDefinition( $def )

  Add a definition to the document.

=cut
sub addDefinition
{
	my ($self, $object) = @_;
	$self->{'defs'} = [] if(not $self->{'defs'});
	push @{$self->{'defs'}}, $object;
	return $self;
}

=head2 $document->definitions( )

  Return all definitions in document.

=cut
sub definitions
{
	my ($self) = @_;
	return $self->{'defs'} || [];
}

=head2 $document->getNamespace( $uri )

  Return a namespace based on the uri or prefix.

=cut
sub getNamespace
{
	my ($self, $uri) = @_;
	$self->{'xmlns'} = {} if not $self->{'xmlns'};
	if($uri eq 'xmlns' and not $self->{'xmlns'}->{'xmlns'}) {
		$self->{'xmlns'}->{'xmlns'} = XML::DOM2::Attribute::Namespace->new(
			owner => $self,
			name => 'xmlns',
			prefix => 'xmlns',
			uri => 'XML Namespace URI'
		);
	}
	return $self->{'xmlns'}->{$uri};
}

=head2 $document->createNamespace( $prefix, $uri )

  Create a new namespace within this document.

=cut 
sub createNamespace
{
	my ($self, $prefix, $uri) = @_;
	my $xmlns = $self->getNamespace( 'xmlns' );
	$self->documentElement->setAttributeNS( $xmlns, $prefix, $uri );
	my $ns = $self->documentElement->getAttributeNS( $xmlns, $prefix );
	if(not $ns) {
		carp "Unable to create namespace, no attribute defined";
	}
	return $ns;
}

=head2 $document->addNamespace( $namespace )

  Add namespace to this document.

=cut
sub addNamespace
{
	my ($self, $namespace) = @_;
	$self->{'xmlns'}->{$namespace->ns_prefix} = $namespace;
	$self->{'xmlns'}->{$namespace->ns_uri} = $namespace;
}

=head2 $document->removeNamespace( $namespace )

  Remove a namespace from this document.

=cut
sub removeNamespace
{
	my ($self, $namespace) = @_;
	delete($self->{'xmlns'}->{$namespace->ns_prefix});
	delete($self->{'xmlns'}->{$namespace->ns_uri});
}

=head2 $document->createElement( $name, %options )

  Creates a new element of type name.

=cut
sub createElement
{
	my ($self, $name, %opts) = @_;
	croak "Unable to create element without a name" if not defined($name) or $name eq '';
	my $element = $self->_element_handle( $name, %opts );
	return $element;
	}

=head2 $document->createElementNS( $namespace, $name, %options )

  Create an element in a namespace.

=cut
sub createElementNS
{
	my ($self, $ns, $name, %opts) = @_;
	croak "Unable to create element without a name" if not defined($name) or $name eq '';
	my $element = $self->_element_handle(
		$name,
		namespace => $ns,
		name => $name,
		%opts,
	);
	return $element;
}

=head2 $document->createTextNode( $data )

  Create a textnode element.

=cut 
sub createTextNode
{
	my ($self, $data) = @_;
	return $self->_element_handle( '#cdata-entity', notag => 1 );
}

=head2 $document->createComment( $data )

  Create a comment element

=cut 
sub createComment
{
	my ($self, $data) = @_;
	return $self->_element_handle( '#comment', text => $data ); 
}

=head2 $document->createCDATASection( $data )

  create a CDATA element.

=cut 
sub createCDATASection
{
	my ($self, $data) = @_;
	return $self->_element_handle( '#cdata-entity',	notag => 0 );
}

=head1 COPYRIGHT

Martin Owens, doctormo@cpan.org

=head1 SEE ALSO

L<XML::DOM2>

=cut
1;
