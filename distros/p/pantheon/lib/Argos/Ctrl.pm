package Argos::Ctrl;

=head1 NAME

Argos::Ctrl - Controls Argos via a SQLite database

=head1 SYNOPSIS

 use Argos::Ctrl;

 my $ctrl = Argos::Ctrl->new( '/sqlite/file' );

 $ctrl->pause( $watcher, $time, $info );
 $ctrl->exclude( $node, $time, $info );

 my %xcldd = map { $_ => 1 } @{ $ctrl->excluded() };
 sleep 3 if $ctrl->stuck( $watcher );
 
=cut
use strict;
use warnings;

use base qw( Vulcan::SQLiteDB );

=head1 DATABASE

A SQLITE db has a I<argos> table of I<four> columns:

 ctrl : 'pause' or 'exclude'
 node : watcher name or node name
 time : time to expire
 info : additional information, if any

=cut
our ( $TABLE, $EXC, $PAUSE ) = qw( argos exclude pause );

sub define
{
    ctrl => 'TEXT NOT NULL',
    node => 'TEXT NOT NULL PRIMARY KEY',
    time => 'INTEGER NOT NULL',
    info => 'BLOB',
}

sub new
{
    my $self = shift;
    $self = $self->SUPER::new( @_, $TABLE );
    $self->{stmt}{$TABLE}{expire} =
        $self->{db}->prepare( "DELETE FROM $TABLE WHERE time < ?" );
    return $self;
}

=head1 METHODS

=head3 pause( $watcher, $time, $info )

Pause $watcher for $time seconds.

=cut
sub pause
{
    my $self = shift;
    $self->insert( $TABLE, $PAUSE, @_ ) if @_ == 3;
}

=head3 stuck( @watcher )

Return records that cause @watcher to be stuck. Return all records if
@watcher is not defined.

=cut
sub stuck
{
    my $self = shift;
    my %query = ( node => [ 1, @_ ], ctrl => [ 0, $EXC ] );

    delete $query{node} unless @_;
    $self->expire( $TABLE, time );
    $self->select( $TABLE, '*', %query );
}

=head3 exclude( $node, $time, $info )

Exclude $node for $time seconds.

=cut
sub exclude
{
    my $self = shift;
    $self->insert( $TABLE, $EXC, @_ ) if @_ == 3;
}

=head3 excluded()

Return ARRAY ref of excluded nodes.

=cut
sub excluded
{
    my $self = shift;
    $self->expire( $TABLE, time );
    my @exc = $self->select( $TABLE, 'node', ctrl => [ 1, $EXC ] );
    return [ map { @$_ } @exc ];
}

=head3 clear( $ctrl => @target )

Undo $ctrl for @target, where $ctrl may be I<pause> or I<exclude>

=cut
sub clear
{
    my ( $self, $ctrl ) = splice @_, 0, 2;
    map { $self->insert( $TABLE, $ctrl, $_, 0, '' ) } @_;
}

1;
