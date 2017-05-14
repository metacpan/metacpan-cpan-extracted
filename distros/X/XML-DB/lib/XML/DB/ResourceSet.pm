package XML::DB::ResourceSet;
use strict;

=head1 NAME

XML::SimpleDB::ResourceSet - container for multiple documents or document fragments 

=head1 SYNOPSIS

$collection = $dbm->getCollection("xmldb:$driver:$url/db/test/shakespeare");
$service = $collection->getService('XPathQueryService', '1.0');
$resourceSet = $service->query('//TITLE');
$id = 'hamlet.xml';
$resourceSet->addResource($collection->getResource($id));
$n = $resourceSet->getSize();
$resource = $resourceSet->getResource($n-1); 
$resourceSet->removeResource($n);
$aref = $resourceSet->getIterator();
foreach(@{$aref)){
    $xml = $_->getContent();
}
$resourceSet->clear();


=head1 DESCRIPTION

A container for resources, normally used when a query returns multiple document
fragments.

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

XML::DB::Resource

=head1 PUBLIC METHODS

=cut


=head2 addResource

=over

I<Usage>     : $rs->addResource($resource)

I<Purpose>   : Store an additional resource

I<Argument>  : The resource to store

I<Returns>   : undef

=back

=cut

sub addResource{
    my ($self, $resource) = @_;
    push @{$self->resources}, $resource;
    return undef;
}

=head2 clear

=over

I<Usage>     : $rs->clear()

I<Purpose>   : delete all current resources

I<Argument>  : None

I<Returns>   : undef

=back

=cut

sub clear{
    my $self = shift;
    splice @{$self->resources}, 0;
    return undef;
}



=head2 getIterator

=over

I<Usage>     : $rs->getIterator()

I<Purpose>   : Should return an iterator; just returns an array reference (foreach is an iterator, isnt it?)

I<Argument>  : None

I<Returns>   : array reference to resources

=back

=cut

sub getIterator{
    my $self = shift;
    my $ref = $self->{'resources'};
    return $ref;
}


=head2 getMembersAsResource

=over

I<Usage>     : $xml = $rs->getMembersAsResource()

I<Purpose>   : Returns a resource with an xml reprentation of contents 

I<Argument>  : none

I<Returns>   : Resource

I<Comment>   : Not defined; the xml format is not yet defined in the spec. Need to check if Xindice or eXist have chosen to implement this. 

=back

=cut

sub getMembersAsResource{
    my $self = shift;
    die "getMembersAsResource is not yet implmented";
}

=head2 getResource

=over

I<Usage>     : $rs->getResource($no)

I<Purpose>   : returns resource at position $no

I<Argument>  : Integer position in array

I<Returns>   : Resource

=back

=cut

sub getResource{
    my ($self, $no) = @_;
    my $size = scalar(@{$self->{'resources'}});
    if (($size == 0) || ($no < 0) || ($no > $size)){
	die "NO_SUCH_RESOURCE";
    }
    return ($self->{'resources'})->[$no];
}

=head2 getSize

=over

I<Usage>     : $size = $rs->getSize()

I<Purpose>   : returns number of stored resources

I<Argument>  : None

I<Returns>   : Integer

=back

=cut

sub getSize{
    my $self = shift;
    return scalar(@{$self->{'resources'}});
}

=head2 removeResource

=over

I<Usage>     : $rs->removeResource($no)

I<Purpose>   : Removes Resource at position $no

I<Argument>  : Integer position

I<Returns>   : undef

=back

=cut

sub removeResource{
    my ($self, $no) = @_;
    my $size =  scalar(@{$self->{'resources'}});
    if (($size == 0) || ($no < 0) || ($no > $size)){
	die "NO_SUCH_RESOURCE";
    }
    splice @{$self->{'resources'}}, $no, 1;
    return undef;
}




=head2 new

=over

I<Purpose>   : Constructor

I<Comments>  : The constructor should not be called directly; new ResourceSets are created as a result of an XPathQuery.

=back

=cut
  
sub new{
	my ($class, $collection, $contents) = @_;
	my $self = {
	    collection => $collection,
	};
	# parse contents to get fragments and populate array
	$self->{'resources'} = _createResources($contents, $collection);
	return bless $self, ref($class) || $class; 
}

# called only from constructor
# splitting of data is driver-specific
sub _createResources{
    my ($contents, $collection) = @_;
    my @resources;
    my $docs = $collection->{'driver'}->splitContents($contents);
    for my $doc(@{$docs}){
	my $resource = new XML::DB::Resource($doc->{'documentId'}, 0, $collection, 'XMLResource');
	$resource->setContent($doc->{'content'});
	push @resources, $resource;
    }
    return \@resources;
}

1; 

__END__


