use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Borda;

use Moose::Role;


our $VERSION='0.013';

=head1 NAME

Vote::Count::Borda

=head1 VERSION 0.013

=cut

# ABSTRACT: Provides Borda Count to Vote::Count objects

no warnings 'experimental';
use List::Util qw( min max );
use Vote::Count::RankCount;
# use Try::Tiny;
# use boolean;
use Data::Printer;

has 'bordaweight' => (
  is => 'rw',
  isa => 'CodeRef',
  builder => '_buildbordaweight',
  lazy => 1,
);

has 'bordadepth' => (
  is => 'rw',
  isa => 'Int',
  default => 0,
);

=pod

=head1 Borda Wieght

Borda's original method assigned each position the
inverse if its position, ie in a 9 choice ballot
position 1 was worth 9, while position 9 was worth 1,
and position 8 was worth 2.

When Creating a VoteCount object the Borda weight
may be set by passing a coderef. The coderef takes
two arguments. The first argument is the
position of the choice in question.
The second argument is the depth of the ballot. The
optional bordadepth attribute will set an arbitrary
depth. Some popular options such inversion ( where
choice $c becomes $c/1 then inverted to 1/$c) don't
need to know the depth. In such cases the coderef
should just ignore the second argument.

The default Weight when none are provided is Borda's
original weight. If the bordadepth attribute is set
it will be followed.

=cut

sub _buildbordaweight {
   return sub {
    my ( $x, $y ) = @_ ;
    return ( $y +1 - $x) }
  }

=pod

=head3 Private Method _bordashrinkballot( $BallotSet, $active )

Takes a BallotSet and active list and returns a
BallotSet reduced to only the active choices. When
choices are removed later choices are promoted.

=cut

sub _bordashrinkballot ( $BallotSet, $active ) {
  my $newballots = {};
  my %ballots = $BallotSet->{'ballots'}->%* ;
  for my $b ( keys %ballots ) {
    my @newballot = ();
    for my $item ( $ballots{$b}{'votes'}->@* ) {
      if ( defined $active->{ $item }) {
        push @newballot, $item ;
      }
    }
    if (scalar( @newballot )) {
      $newballots->{$b}{'votes'} = \@newballot;
      $newballots->{$b}{'count'} =
    $ballots{$b}->{'count'};
    }
  }
  return $newballots;
}

sub _dobordacount( $self, $BordaTable, $active) {
  my $BordaCount = {};
  my $weight = $self->bordaweight;
  my $depth = $self->bordadepth
    ? $self->bordadepth
    : scalar( keys %{$active} );
  for my $c ( keys $BordaTable->%*) {
    for my $rank ( keys $BordaTable->{$c}->%* ) {
      $BordaCount->{ $c } = 0 unless defined $BordaCount->{ $c };
      $BordaCount->{ $c } +=
        $BordaTable->{$c}{$rank} *
        $weight->( $rank, $depth ) ;
    }
  }
  return $BordaCount;
}

sub Borda ( $self, $active = undef ) {
  my %BallotSet = $self->BallotSet()->%*;
  my %ballots   = ();
  $active = $self->Active() unless defined $active;
  %ballots = %{_bordashrinkballot( \%BallotSet, $active )};
  my %BordaTable = ( map { $_ => {} } keys( $active->%* ) );
  for my $b ( keys %ballots ) {
    my @votes  = $ballots{$b}->{'votes'}->@*;
    my $bcount = $ballots{$b}->{'count'};
    for ( my $i = 0 ; $i < scalar(@votes) ; $i++ ) {
      my $c = $votes[$i];
      if ( defined $BordaTable{$c} ) {
        $BordaTable{$c}->{ $i + 1 } += $bcount;
      }
      else {
        $BordaTable{$c}->{ $i + 1 } = $bcount;
      }
    }
  }
  my $BordaCounted =
         _dobordacount(
           $self,
           \%BordaTable,
           $active );
  return Vote::Count::RankCount->Rank( $BordaCounted );
}

1;


#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut

