package XML::DB::Service::XPathQueryService;
use XML::DB::ResourceSet;
use strict;

BEGIN {
	use vars qw (@ISA $VERSION);
	$VERSION = 0.01;
	@ISA  = qw (XML::DB::Service);
}

=head1 NAME

XML::DB::Service::XPathQueryService - provides XPath queries

=head1 SYNOPSIS

$service = $collection->getService('XPathQueryService', '1.0');
$resourceSet1 = $service->query($xpath);
$resourceSet2 = $service->queryResource($xpath, $resourceId);

=head1 DESCRIPTION

Implements XML::DB::Service.
Provides XPath queries relative to the Collection it is fetched from.

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

=head1 BUGS

=head1 SEE ALSO

XML::DB::Service

=head1 PUBLIC METHODS


=cut




=head2 clearNamespaces

=over

I<Usage> clearNamespaces()

I<Purpose> clears the namespace map

I<Arguments> none

I<Returns> void 

=back

=cut

sub clearNamespaces{
    my $self = shift;
    my %map = {};
    $self->{'namespaces'} = \%map;

    return undef;
}

=head2 getNamespace

=over

I<Usage> my $uri = $service->getNamespace($prefix)

I<Purpose> Returns the uri associated with a prefix

I<Arguments> $prefix 

I<Returns> uri associated with prefix; default uri for empty prefix, or undef for prefix not found

=back

=cut

sub getNamespace{
    my ($self, $prefix) = @_;

    if (! defined $prefix){
	return $self->{'default_namespace'};
    }
    return $self->{'namespaces'}->{$prefix} || undef;
}

=head2 removeNamespace

=over

I<Usage> $service->removeNamespace($prefix)

I<Purpose> Removes the uri associated with a prefix, or the default namespace if prefix is empty

I<Arguments> $prefix 

I<Returns> void

=back

=cut

sub removeNamespace{
    my ($self, $prefix) = @_;

    if (! defined $prefix){
	$self->{'default_namespace'} = '';
    }
    else{
	delete $self->{'namespaces'}->{$prefix};
    }
    return undef;
}

=head2 setNamespace

=over

I<Usage>: $service->setNamespace($prefix, $url)

I<Purpose>: Associates a uri with a prefix; if prefix is null, the default namespace is set to the uri

I<Arguments>: $prefix, $uri 

I<Returns>: void

I<Throws>: Exception if both uri and prefix are undefined 

=back

=cut

sub setNamespace{
    my ($self, $prefix, $uri) = @_;

    if ((! defined $prefix)&&(! defined $uri)){
	die "no uri or prefix defined";
    }
    if (! defined  $uri){
	$self->{'default_namespace'} = $prefix; # really the uri
    }
    else{
	$self->{'namespaces'}->{$prefix} = $uri;
    }
    return undef; 
}

=head2 query

=over

I<Usage>     : $resourceSet = query($XPath)

I<Purpose>   : Executes a query against a collection

I<Arguments>  : xpath query string

I<Returns> : ResourceSet

I<Throws> : Exception

=back

=cut

sub query{
    my ($self, $query) = @_;
 
    my $collection = $self->{'collection'}->{'path'};
    my $driver = $self->{'collection'}->{'driver'};
    my $namespaces = $self->{'namespaces'};
    my $result;
    eval{
	$result = $driver->queryCollection($collection, 'XPath', $query, $namespaces)
	};
    if ($@){
	die $@;
    }
    return new XML::DB::ResourceSet($self->{'collection'}, $result);
}

=head2 queryResource

=over

I<Usage>     : $resourceSet = query($XPath, $id)

I<Purpose>   : Executes a query against a resource in the collection

I<Arguments>:

=over 4

=item * $xpath - query string

=item * $id - id of resource to query

=back

I<Returns> : ResourceSet

I<Throws> : Exception

=back

=cut

sub queryResource{
    my ($self, $query, $id) = @_;
 
    my $collection = $self->{'collection'}->{'path'};
    my $driver = $self->{'collection'}->{'driver'};
    my $namespaces = $self->{'namespaces'};
    my $result;
    eval{
	$result = $driver->queryDocument($collection, 'XPath', $query, $namespaces, $id)
	};
    if ($@){
	die $@;
    }
    return new XML::DB::ResourceSet($self->{'collection'}, $result);
}

=head2 new

=over

I<Usage>     : Should only be called indirectly, from a Collection (see Synopsis)

I<Purpose>   : Constructor

=back

=cut 

sub new{
	my ($class, $self) = @_;
	bless $self, $class;
	return $self; 
}


1; 
__END__


