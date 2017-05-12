
=head1 NAME

WebService::Amazon::Route53::Caching::Store::Redis - Redis-based cache-storage.

=head1 SYNOPSIS

This module implements several methods which makes it possible to
get/set/delete cached values by a string-key.

The module will expect to be passed an open/valid Redis handle in the
constructor:

=for example begin

    my $redis = Redis->new();
    my $cache = WebService::Amazon::Route53::Caching::Store::Redis->new( redis => $redis );

=for example end

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut


package WebService::Amazon::Route53::Caching::Store::Redis;

use strict;
use warnings;



=begin doc

Constructor, just save the Redis handle away.

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    $self->{ '_handle' } = $supplied{ 'redis' };
    bless( $self, $class );
    return $self;
}



=begin doc

Set a given value to the named key.

=end doc

=cut

sub set
{
    my ( $self, $key, $val ) = (@_);

    return ( $self->{ '_handle' }->set( $key, $val ) );
}



=begin doc

Fetch the value from a given key.

=end doc

=cut

sub get
{
    my ( $self, $key ) = (@_);

    return ( $self->{ '_handle' }->get($key) );
}



=begin doc

Delete the value associated with the given key.

=end doc

=cut

sub del
{
    my ( $self, $key ) = (@_);

    $self->{ '_handle' }->set($key, "[deleted]" );
    return ( $self->{ '_handle' }->del($key) );
}



1;
