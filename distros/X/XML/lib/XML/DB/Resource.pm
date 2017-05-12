package XML::DB::Resource;
use strict;
use XML::DB::Resource::XMLResource;

=head1 NAME

XML::DB::Resource - Wrapper class for documents or document fragments 

=head1 SYNOPSIS

    $resource = $collection->getResource($id);  
    $id = $resource->getId();
    $xml = $resource->getContent();
    $resource->setContent($xml);
    $collection->storeResource($resource);
    $parentColl = $resource->getParentCollection(); 

=head1 DESCRIPTION

This is an abstract class implementing the Service interface Database from the XML:DB base specification. It should only be used indirectly, as superclass for a specific Resource type. The only current example is XMLResource.

=head1 BUGS

=head1 AUTHOR

	Graham Seaman
	CPAN ID: GSEAMAN
	graham@opencollector.org

=head1 COPYRIGHT

Copyright (c) 2002 Graham Seaman. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=head1 PUBLIC METHODS

=cut


=head2 getContent

=over

I<Usage>     : $r->getContent()

I<Purpose>   : Returns the stored data

I<Argument>  : None

I<Returns>   : XML String 

=back

=cut

sub getContent{
    my $self = shift;
    return $self->{'content'};
}

=head2 getId

=over

I<Usage>     : $r->getId()

I<Purpose>   : Returns the stored id (may be undef)

I<Argument>  : None

I<Returns>   : id or undef

=back

=cut

sub getId{
    my $self = shift;
    return $self->{'id'};
}


=head2 getParentCollection

=over

I<Usage>     : $collection = $r->getParentCollection()

I<Purpose>   : Returns the collection this resource belongs to

I<Argument>  : none

I<Returns>   : Collection

=back

=cut

sub getParentCollection{
    my $self = shift;
    return $self->{'collection'};
}

=head2 setContent

=over

I<Usage>     : $r->setContent($doc)

I<Purpose>   : stores the content (overwriting any previous content)

I<Argument>  : XML document

I<Returns>   : void

=back

=cut

sub setContent{
    my ($self, $doc) = @_;
    $self->{'content'} = $doc;
}

=head2 getResourceType

=over

I<Usage>     : $type = $r->getResourceType()

I<Purpose>   : Returns resource type of implementing class

I<Argument>  : none

I<Returns>   : string

=back

=cut

sub getResourceType{
    my $self = shift;
    return $self->{'resourceType'};
}


=head2 new

=over

I<Purpose>   : Constructor

I<Comments>  : The constructor should not be called directly; new Resources are created via their parent Collection, or implicitly while building a ResourceSet.

=back

=cut
  
sub new{
	my ($class, $documentId, $id, $collection, $type) = @_;
	my $self = {
	    content => '',
	    collection => $collection,
	    documentId => $documentId,
	    id => $id || $documentId,
	    resourceType => $type,
	};
	my $implementation = 'XML::DB::Resource::' . $type;
	eval 'require ' . $implementation;
	die $@ if ($@);
	return new $implementation($self);
}



1; 

__END__


