package Ceres::DBI::Index;

=head1 NAME

Ceres::DBI::Index - DB interface to Ceres index

=head1 SYNOPSIS

 use Ceres::DBI::Index;

 my $db = Ceres::DBI::Index->new( '/database/file' );

=cut
use strict;
use warnings;

=head1 METHODS

See Vulcan::SQLiteDB.

=cut
use base qw( Vulcan::SQLiteDB );

=head1 DATABASE

A SQLITE db has a <ceres> table of I<three> columns:

 host : hostname
 key : md5 key
 sig : current md5 signature

=cut
our $TABLE  = 'ceres';

sub define
{
    host => 'TEXT NOT NULL PRIMARY KEY',
    key => 'TEXT NOT NULL',
    sig => 'TEXT NOT NULL',
};

sub new
{
    my $self = shift;
    $self = $self->SUPER::new( @_, $TABLE );
    return $self;
}

=head1 METHODS

=head3 update( $host, $key, $sig )

Update record if I<key> or I<sig> changed.

=cut
sub update
{
    my ( $self, $host, $key, $sig ) = splice @_;

    $self->delete( $TABLE, host => [ 0, $host ], key => [ 1, $key ] );
    $self->delete( $TABLE, host => [ 1, $host ], key => [ 0, $key ] );

    my ( $record ) = $self->select( $TABLE => '*', host => [ 1, $host ] );
    $self->insert( $TABLE, $host, $key, $sig )
        unless $record && $record->[2] eq $sig;
}

=head3 index( $host, $sig )

Select I<key> by $host, and by failed I<sig> match if $sig is defined.
Return last two characters of I<key>, or undef if $host does not exist.

=cut
sub index
{
    my ( $self, $host, $sig ) = splice @_;
    my %query = ( host => [ 1, $host ] );

    $query{sig} = [ 0, $sig ] if defined $sig;
    my ( $record ) = $self->select( $TABLE => '*', %query );
    return $record ? substr $record->[1], -2, 2 : undef;
}

1;
