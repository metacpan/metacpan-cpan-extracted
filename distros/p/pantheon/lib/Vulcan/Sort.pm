package Vulcan::Sort;

=head1 NAME

Vulcan::Sort - Multi-dimensional Sort

=cut
use warnings;
use strict;

use Carp;

=head1 SYNOPSIS

 use Vulcan::Sort;

 my $sort = Vulcan::Sort->new( dim1 => sub {}, dim2 => sub {} .. );
 my @b = $sort->run( \@a, qw( dim1 dim2 .. ) );

=cut
sub new
{
    my ( $class, %self ) = splice @_;
    map { confess "invalid code $_" if ref $self{$_} ne 'CODE' } keys %self;
    bless \%self, ref $class || $class;
}

=head1 Methods

=head3 run( \@array, @dim )

Sort @array by each dimension in @dim. Returns sorted array.

=cut
sub run
{
    my ( $self, $list, %sort ) = splice @_, 0, 2;
    my @sort = defined $list
        ? ref $list && ( ref $list eq 'ARRAY' || $list->isa( 'ARRAY' ) )
        ? $self->h2a( $self->a2h( $list, @_ ) ) : confess 'invalid list' : ();
    return wantarray ? @sort : \@sort;
}

sub a2h
{
    my ( $self, $list, %sort ) = splice @_, 0, 2;
    return $list unless @_;
    return $list unless my $w8 = $self->{ shift @_ };

    map { push @{ $sort{ &$w8( $_ ) } }, $_ } @$list;
    map { $sort{$_} = $self->a2h( $sort{$_}, @_ ) } keys %sort;
    return \%sort;
}

sub h2a
{
    my ( $self, $sort ) = splice @_;
    return ref $sort eq 'ARRAY' ? @$sort :
        map { $self->h2a( $sort->{$_} ) } sort { $a <=> $b } keys %$sort;
}

1;
