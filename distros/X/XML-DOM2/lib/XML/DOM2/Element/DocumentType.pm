package XML::DOM2::Element::DocumentType;

use strict;
use warnings;

=head1 NAME

  XML::DOM2::Element::DocumentType - XML DocumentType

=head1 DESCRIPTION

  Provides a DocumentType element for documents

=head1 METHODS

=cut

use Carp;

=head2 new

Creates a new documentType object

Parameters:

  - name       qualified name of the document to be created.
  - publicid   The external subset public identifier.
  - systemid   The external subset system identifier.

=cut
sub new
{
	my ($proto, %args) = @_;
#	croak "name required (qualifiedName) in documentType" if not $args{'name'};
#	croak "publicid required in documentType" if not $args{'publicid'};
	my $doctype = bless \%args, $proto;
	return $doctype;
}

=head2 ownerDocument

$document = $document->ownerDocument;

Returns the document that this type is within, undef if orphaned.

=cut
sub ownerDocument
{
	my ($self, $set) = @_;
	$self->{'document'} = $set if defined($set);
	return $self->{'document'};
}

=head2 name

The name of DTD; i.e., the name immediately following the DOCTYPE keyword.

=cut
sub name
{
	my ($self, $set) = @_;
	$self->{'name'} = $set if defined($set);
	return $self->{'name'};
}

=head2 entities

A NamedNodeMap containing the general entities, both external and internal, declared in the DTD. Parameter entities are not contained. Duplicates are discarded.

=cut
sub entities
{
	die "Not implimented yet";
}

=head2 notations

Returns a HASH containing the notations declared in the DTD. Duplicates are discarded. Every node in this map also implements the Notation interface.

The DOM Level 2 does not support editing notations, therefore notations cannot be altered in any way.

=cut
sub notations
{
	die "Not implimented yet";
}

=head2 publicId

Returns the public identifier of the external subset.

=cut
sub publicId
{
	my ($self, $set) = @_;
	$self->{'publicId'} = $set if defined($set);
	return $self->{'publicId'};
}

=head2 systemId

Returns the system identifier of the external subset.

=cut
sub systemId
{
	my ($self, $set) = @_;
	$self->{'systemId'} = $set if defined($set);
	return $self->{'systemId'};
}

=head2 internalSubset

The internal subset as a string.

Note: The actual content returned depends on how much information is available to the implementation. This may vary depending on various parameters, including the XML processor used to build the document.

=cut
sub internalSubset
{
	die "Not implimented yet";
}

=head2 $documentType->dtd()

  Returns the document type definition information.

=cut
sub dtd
{
	my ($self) = @_;
	return $self->{'dtd'};
}

=head1 AUTHOR

Martin Owens, doctormo@postmaster.co.uk

=head1 SEE ALSO

perl(1), L<XML::DOM2>, L<XML::DOM2::Element>, L<XML::DOM2::DOM>

L<http://www.w3.org/TR/1998/REC-DOM-Level-1-19981001/level-one-core.html> DOM at the W3C

=cut

return 1;
