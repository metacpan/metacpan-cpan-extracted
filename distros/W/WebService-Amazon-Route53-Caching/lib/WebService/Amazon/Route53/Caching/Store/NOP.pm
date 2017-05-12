
=head1 NAME

WebService::Amazon::Route53::Caching::Store::NOP - Dummy cache-storage.

=head1 SYNOPSIS

This module implements several methods which makes it possible to
get/set/delete cached values by a string-key.

The implementation of these methods are NOPs (no-operations), which
means nothing is ever cached.

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut


use strict;
use warnings;

package WebService::Amazon::Route53::Caching::Store::NOP;


=begin doc

Constructor.  Do nothing.

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    bless( $self, $class );
    return $self;
}



=begin doc

Do nothing.

=end doc

=cut

sub set
{
    my ( $self, $key, $val ) = (@_);
}



=begin doc

Do nothing.

=end doc

=cut

sub get
{
    my ( $self, $key ) = (@_);

    undef;
}



=begin doc

Do nothing.

=end doc

=cut

sub del
{
    my ( $self, $key ) = (@_);
}



1;
