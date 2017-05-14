package XML::DB::Service;
use strict;

=head1 NAME

XML::SimpleDB::Service - Abstract class for extension by XML:SimpleDB services 

=head1 SYNOPSIS

  use XML::SimpleDB::Service;

=head1 DESCRIPTION

This is an abstract class implementing the Service interface Database from the XML:DB base specification. It should only be used indirectly, as superclass for a specific Service. The current examples are XPathQueryService, XUpdateQueryService, and Collectionmanager. 

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

sub new{
	my ($class, $collection, $name, $version) = @_;
	my $self = {
	    version => $version,
	    name => $name,
	    namespaces => {},
	    default_namespace => 'http://opencollector.org/xmldb',
	    collection => $collection,
	};
	die "Wrong version of $name: $version" if ($version ne '1.0'); # how silly..
	my $implementation = 'XML::DB::Service::' . $name;
	eval 'require ' . $implementation;
	die $@ if ($@);
	return new $implementation($self);
}

=head2 getName

=over

I<Usage>     : $name = $service->getName()

I<Purpose>   : Returns the service name

I<Argument>  : None

I<Returns>   : String

=back

=cut

sub getName{
    my $self = shift;
    return $self->{'name'};
}

=head2 getVersion

=over

I<Usage>     : $version = $service->getVersion()

I<Purpose>   : Returns the service version

I<Argument>  : None

I<Returns>   : String

=back

=cut

sub getVersion{
    my $self = shift;
    return $self->{'version'};
}

=head2 setCollection

=over

I<Usage>     : $service->setCollection($collection)

I<Purpose>   : Associates service with a collection

I<Argument>  : Collection object

I<Returns>   : void

=back

=cut

sub setCollection{
    my ($self, $collection) = @_;
    
    $self->{'collection'} = $collection;

return undef;    
}

1; 

__END__


