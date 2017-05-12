package XML::DB::Service::CollectionManager;
use strict;

BEGIN {
	use vars qw (@ISA);
	@ISA         = qw (XML::DB::Service);
}

=head1 NAME

XML::DB::CollectionManager - manages collections

=head1 SYNOPSIS

    $collectionManager = $collection->getService('CollectionManager', '1.0');
    $collectionManager->createCollection('test');
    $collectionManager->removeCollection('test');

=head1 DESCRIPTION

CollectionManager implements Service. It provides the ability to create
or remove Collections from the database.

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

=head2 createCollection

=over

I<Usage> : $coll = $cm->createCollection($name)

I<Purpose> : creates a new (empty) collection in the database

I<Arguments> : name of collection

I<Returns> : collection

I<Throws> : exception if unable to create collection

=back

=cut

sub createCollection{
    my ($self, $name) = @_;

    my $path = $self->{'collection'}->{'path'};
    my $driver = $self->{'collection'}->{'driver'};
    eval { 
	$driver->createCollection($path, $name);
	};
    if ($@){ 
	die $@;
    }
    my $collection;
    eval{
	$collection = new XML::DB::Collection($driver, $path, $name, undef, undef)
	};
    if ($@){
	die $@;
    }
return $collection;
}

=head2 removeCollection

=over

I<Usage> : $cm->removeCollection($name)

I<Purpose> : removes a collection from the database

I<Arguments> : name of collection

I<Returns> : undef

I<Throws> : exception if unable to remove collection

=back

=cut

sub removeCollection{
    my ($self, $name) = @_;

    my $path = $self->{'collection'}->{'path'};
    my $driver = $self->{'collection'}->{'driver'};
    my $resp;
    eval{
	$resp = $driver->dropCollection($path .'/' . $name);
    };
    if ($@){ 
	die $@;
    }
return undef;
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


