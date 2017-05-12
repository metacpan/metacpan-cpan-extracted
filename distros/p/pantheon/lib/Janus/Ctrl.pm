package Janus::Ctrl;

=head1 NAME

Janus::Ctrl - Controls maintenance via a SQLite database

=head1 SYNOPSIS

 use Janus::Ctrl;

 my $ctrl = Janus::Ctrl->new( $name => '/sqlite/file' );

 $ctrl->clear();
 $ctrl->pause( 'foo.alpha', 'blah' );
 $ctrl->resume();
 $ctrl->exclude( 'foobar', 'blah' );
 sleep 3 if $ctrl->stuck();
 
=cut
use strict;
use warnings;

use base qw( Vulcan::SQLiteDB );

=head1 DATABASE

A SQLITE db has a I<watcher> table of I<four> columns:

 name : name of maintenance
 ctrl : 'error', 'pause' or 'exclude'
 node : stage name or node name
 info : additional information, if any

=cut
our ( $TABLE, $EXC, $ANY ) = qw( janus exclude ANY );

sub define
{
    name => 'TEXT NOT NULL',
    ctrl => 'TEXT NOT NULL',
    node => 'TEXT NOT NULL PRIMARY KEY',
    info => 'BLOB';
};

sub new
{
    my ( $class, $name, $db ) = splice @_;
    my $self = $class->SUPER::new( $db, $TABLE );
    $self->{name} = $name;
    return $self;
}

sub query
{
    my $self = shift;
    $self->SUPER::query( name => [ 1, $self->{name} ], @_ );
}

=head1 METHODS

=head3 pause( $stage, $info, $ctrl = 'pause' )

Insert a record that cause stuck.

=cut
sub pause
{
    my $self = shift;
    return if @_ < 2 || @_ > 3;
    $self->insert( $TABLE, $self->{name}, ( @_ == 3 ? pop : 'pause' ), @_ );
}

=head3 stuck( @stage )

Return records that cause @stage to be stuck. Return all records if @stage
is not defined.

=cut
sub stuck
{
    my $self = shift;
    $self->select( $TABLE => '*', node => [ 1, @_ ], ctrl => [ 0, $EXC ] );
}

=head3 resume( @stage )

Clear records that cause @stage to be stuck. Clear all records if @stage
is not defined.

=cut
sub resume
{
    my $self = shift;
    my %node = ( node => [ 1, @_ ] ) if @_;
    $self->delete( $TABLE, %node, ctrl => [ 0, $EXC ] );
}

=head3 exclude( $node, $info )

Exclude $node with a $info.

=cut
sub exclude
{
    my $self = shift;
    if ( @_ )
    {
        $_[1] = '' unless defined $_[1];
        $self->insert( $TABLE, $self->{name}, $EXC, @_[0,1] );
    }
}

=head3 excluded()

Return ARRAY ref of excluded nodes.

=cut
sub excluded
{
    my $self = shift;
    my @exc = $self->select( $TABLE => 'node', ctrl => [ 1, $EXC ] );
    return [ map { @$_ } @exc ];
}

=head3 dump()

Return ARRAY ref of *.

=cut
sub dump
{
    my $self = shift;
    my @exc = $self->select( $TABLE => '*' );
    return [ map { @$_ } @exc ];
}

=head3 clear()

clear all records. 

=cut
sub clear
{
    my $self = shift;
    $self->delete( $TABLE );
}

=head3 any()

A pseudo-stage that applies to all stages.

=cut
sub any
{
    my $self = shift;
    return $ANY;
}

1;
