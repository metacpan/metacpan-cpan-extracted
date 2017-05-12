
=head1 NAME

WebService::Amazon::Route53::Caching::Store::DBM - DBM-based cache-storage.

=head1 SYNOPSIS

This module implements several methods which makes it possible to
get/set/delete cached values by a string-key.

The module will expect to be passed a filename to use for the cache in
the constructor:

=for example begin

    my $redis = Redis->new();
    my $cache = WebService::Amazon::Route53::Caching::Store::DBM->new( path => "/tmp/db.db" );

=for example end

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut


use strict;
use warnings;


package WebService::Amazon::Route53::Caching::Store::DBM;


use DB_File;



=begin doc

Constructor.  Save the filename away.

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    $self->{ '_path' } = $supplied{ 'path' };
    bless( $self, $class );
    return $self;
}



=begin doc

Tie, set, and untie the backing-store.

=end doc

=cut

sub set
{
    my ( $self, $key, $val ) = (@_);

    #
    #  Here we tie, get, and untie.
    #
    #  We need to explicitly untie to force a cache flush.
    #
    my %h;
    tie %h, "DB_File", $self->{ '_path' }, O_RDWR | O_CREAT, 0666, $DB_HASH or
      return;

    $h{ $key } = $val;
    untie(%h);
}



=begin doc

Tie, get, and untie the backing-store.

=end doc

=cut

sub get
{
    my ( $self, $key ) = (@_);

    #
    #  Here we tie, get, and untie.
    #
    #  We need to explicitly untie to force a cache flush.
    #
    my %h;
    tie %h, "DB_File", $self->{ '_path' }, O_RDWR | O_CREAT, 0666, $DB_HASH or
      return;

    my $ret = $h{ $key };
    untie(%h);

    return ($ret);
}



=begin doc

Tie, unset, and untie the backing-store.

=end doc

=cut

sub del
{
    my ( $self, $key ) = (@_);

    #
    #  Here we tie, get, and untie.
    #
    #  We need to explicitly untie to force a cache flush.
    #
    my %h;
    tie %h, "DB_File", $self->{ '_path' }, O_RDWR | O_CREAT, 0666, $DB_HASH or
      return;

    $h{$key} = "[deleted]";
    delete $h{ $key };
    untie(%h);
}



1;
