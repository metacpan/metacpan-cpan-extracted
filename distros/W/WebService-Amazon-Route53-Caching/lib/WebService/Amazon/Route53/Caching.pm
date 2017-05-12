
=head1 NAME

WebService::Amazon::Route53::Caching - Caching layer for the Amazon Route 53 API

=head1 SYNOPSIS

WebService::Amazon::Route53::Caching provides an caching layer on top of
the existing L<WebService::Amazon::Route53> module, which presents an interface
to the Amazon Route 53 DNS service.

=cut

=head1 DESCRIPTION

This module overrides the base behaviour of the L<WebService::Amazon::Route53>
object to provide two specific speedups:

=over 8

=item We force the use of HTTP Keep-Alive when accessing the remote Amazon API end-point.

=item We cache the mapping between zone-names and Amazon IDs

=back

The reason for the existance of this module was observed performance
issues with the native client.  A user of the Route53 API wishes to use
the various object methods against B<zones>, but the Amazon API requires
that you use their internal IDs.

For example rather than working with a zone such as "steve.org.uk", you
must pass in a zone_id of the form "123ZONEID".  Discovering the ID
of a zone is possible via L<get_hosted_zone|WebService::Amazon::Route53/"get_hosted_zone"> method.

Unfortunately the implementation of the B<get_hosted_zone> method essentially
boils down to fetching all possible zones, and then performing a string
comparison on their names.

This module was born to cache the ID-data of individual zones, allowing
significant speedups when dealing with a number of zones.

=cut

=head1 CACHING

This module supports two different types of caching:

=over 8

=item Caching via the fast in-memory datastore, Redis.

=item Caching via the L<DB_File> module.

=back

To specify the method you need to pass the appropriate argument
to the constructor of this class.

The simplest approach involves passing a filename to use as the
DB-store:

=for example begin

    my $c = WebService::Amazon::Route53::Caching->new( key => "xx",
                                                       id  => "xx",
                                                       path => "/tmp/x.db" );

    $c->....

=for example end

The following example uses Redis :

=for example begin

    my $r = new Redis;

    my $c = WebService::Amazon::Route53::Caching->new( key => "xx",
                                                       id  => "xx",
                                                       redis => $r );

    $c->....

=for example end


All other class methods remain identical to those implemented in the
parent.

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut


package WebService::Amazon::Route53::Caching;

use strict;
use warnings;


use base ("WebService::Amazon::Route53");
use Carp;

use WebService::Amazon::Route53::Caching::Store::DBM;
use WebService::Amazon::Route53::Caching::Store::NOP;
use WebService::Amazon::Route53::Caching::Store::Redis;

use JSON;
our $VERSION = "0.4.2";



=begin doc

Override the constructor to enable Keep-Alive in the UserAgent
object.  This cuts down request time by 50%.

=end doc

=cut

sub new
{
    my ( $class, %args ) = (@_);

    # Invoke the superclass.
    my $self = $class->SUPER::new(%args);


    #
    #  This is messy only because the length of the classes.
    #
    #  We always create a caching mechanism, here we determine the correct
    # one to load.
    #
    #  If none is explicitly specified then we use the NOP one.
    #
    if ( $args{ 'path' } )
    {
        $self->{ '_cache' } =
          WebService::Amazon::Route53::Caching::Store::DBM->new(
                                                      path => $args{ 'path' } );
    }
    elsif ( $args{ 'redis' } )
    {
        $self->{ '_cache' } =
          WebService::Amazon::Route53::Caching::Store::Redis->new(
                                                    redis => $args{ 'redis' } );
    }
    else
    {
        $self->{ '_cache' } =
          WebService::Amazon::Route53::Caching::Store::NOP->new();
    }

    # Update the User-Agent to use Keep-Alive.
    $self->{ 'ua' } = LWP::UserAgent->new( keep_alive => 10 );

    return $self;
}



=begin doc

Find data about the hosted zone, preferring our local cache first.

=end doc

=cut

sub find_hosted_zone
{
    my ( $self, %args ) = (@_);

    if ( !defined $args{ 'name' } )
    {
        carp "Required parameter 'name' is not defined";
    }

    #
    #  Lookup from the cache - deserializing after the fetch.
    #
    my $data = $self->{ '_cache' }->get( "zone_data_" . $args{ 'name' } );
    if ( $data && length($data) )
    {
        my $obj = from_json($data);
        return ($obj);
    }

    #
    # OK that failed, so revert to using our superclass.
    #
    my $result = $self->SUPER::find_hosted_zone(%args);

    #
    # Store the result in our cache so that the next time we'll get a hit.
    #
    if ( $result )
    {
        # Store the values of the lookup.
        $self->{ '_cache' }
          ->set( "zone_data_" . $args{ 'name' }, to_json($result) );

        # Store the mapping from the returned ID to the domain-data.
        my $id = $result->{'id'};
        if ( $id )
        {
            $self->{ '_cache' }
              ->set( "zone_data_id_" . $id, $args{'name'} );
        }
    }

    return ($result);
}



=begin doc

When a zone is created the Amazon ID is returned, so we can pre-emptively
cache that.

=end doc

=cut

sub create_hosted_zone
{
    my ( $self, %args ) = @_;

    my $result = $self->SUPER::create_hosted_zone(%args);

    #
    #  Update the cache.
    #
    if ( $result && $result->{ 'zone' } )
    {
        $self->{ '_cache' }
          ->set( "zone_data_" . $args{ 'name' }, to_json($result) );

        #
        # Store the mapping from the returned ID to the domain-data.
        #
        my $id = $result->{'zone'}->{'id'} || $result->{'id'};
        if ( $id )
        {
            $id =~ s/\/hostedzone\///g;
            $self->{ '_cache' }
              ->set( "zone_data_id_" . $id, $args{'name'} );
        }

    }

    return ($result);
}



=begin doc

When a zone is deleted we'll remove the association we have between
the name and the ID.

=end doc

=cut

sub delete_hosted_zone
{
    my ( $self, %args ) = (@_);

    if ( !defined $args{ 'zone_id' } )
    {
        carp "Required parameter 'zone_id' is not defined";
    }


    #
    #  Remove the cache-data associated with this key.
    #
    #  First lookup the name of the zone, so we can find the keyu
    # which is based on the zone-name.
    #
    my $zone = $self->{ '_cache' }->get( "zone_data_id_" . $args{'zone_id'} );

    $self->{ '_cache' }->del( "zone_data_"    . $zone ) if ( $zone );
    $self->{ '_cache' }->del( "zone_data_id_" . $args{ 'zone_id' } );

    return ( $self->SUPER::delete_hosted_zone(%args) );
}


=begin doc

Allow the caller to gain access to our caching object.

=end doc

=cut

sub cache
{
    my( $self ) = ( @_ );
    return( $self->{'_cache'} );
}

1;

