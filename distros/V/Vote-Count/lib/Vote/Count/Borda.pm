use strict;
use warnings;
use 5.024;
use feature qw /postderef signatures/;

package Vote::Count::Borda;

use Moose::Role;

our $VERSION='2.04';

=head1 NAME

Vote::Count::Borda

=head1 VERSION 2.04

=cut

# ABSTRACT: Provides Borda Count to Vote::Count objects

no warnings 'experimental';
use List::Util qw( min max );
use Vote::Count::RankCount;
use Try::Tiny;
use Data::Dumper;

has 'bordaweight' => (
  is      => 'rw',
  isa     => 'CodeRef',
  builder => '_buildbordaweight',
  lazy    => 1,
);

has 'bordadepth' => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
);

# Many real world Borda implmentations use 1
# for unranked default. The way unranked choices are valued
# relies on NonApproval (from Approval), which does not
# support overriding the Active Set. Because this is a low
# priority function the limitation is acceptable.
has 'unrankdefault' => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
);

=pod

=head1 Synopsis

  my $RCV = Vote::Count->new(
    BallotSet  => read_ballots('t/data/data1.txt'),
    bordadepth => 5
  );
  my $bordacount = $RCV->Borda();

=head1 Borda Count

Scores Choices based on their position on the Ballot. The first choice candidate gets a score equal to the number of choices, each lower choice receives 1 less.

The Borda Count is trying to Cardinally value Preferential choices, for this reason where the Borda Count is an appropriate method it is a better to use a Range Ballot instead of Preferential so that the voters may assign the Cardinal values.

=head1 Variations on the Borda Count

One major criticism of the count is that when there are many choices the difference between a first and second choice becomes negligible. A large number of alternative weightings have been used to address this.

=head2 Borda Depth (bordadepth parameter)

One of the simpler variations is to fix the depth, when the depth is set to a certain number the weighting is as if the ballot had that many choices, and choices ranked lower than the depth are scored 0. If there are eight choices and a depth of 3, a first choice is worth 3, a 3rd 1, and later choices are ignored

=head2 Borda Weight (bordaweight parameter)

Some of the popular alternate weighting systems include:

=over

=item * different scaling such as 1/x where x is the position of the choice (1 is worth 1, 3 is 1/3).

=item * Another popular alternative is to score for one less than the number of choices -- in a five choice race first is worth 4 and last is worth 0.

=back

When Creating a VoteCount object a custom Borda weight may be set by passing a coderef for bordaweight. The coderef takes two arguments. The first argument is the position of the choice in question. The second argument is optional for passing the depth of the ballot to the coderef. Some popular options such inversion (where choice $c becomes $c/1 then inverted to 1/$c) don't need to know the depth. In such cases the coderef should just ignore the second argument.

  my $testweight = sub {
    my $x = int shift @_;
    return $x ? 1/$x : 0 ;
  };

  my $VC2 = Vote::Count->new(
    BallotSet   => read_ballots('t/data/data2.txt'),
    bordaweight => $testweight,
  );

=head2 unrankdefault

Jean-Charles de Borda expected voters to rank all available choices. When they fail to do this the unranked choices need to be handled. The default in Vote::Count is to score unranked choices as 0. However, it is also common to score them as 1. Vote::Count permits using any Integer for this valuation.

  my $VC2 = Vote::Count->new(
    BallotSet   => read_ballots('t/data/data2.txt'),
    unrankdefault => 1,
  );

=head1 Method Borda

Returns a RankCount Object with the scores per the weighting rule, for Ranked Choice Ballots. Optional Parameter is a hashref defining an active set.

=cut

sub _buildbordaweight {
  return sub {
    my ( $x, $y ) = @_;
    return ( $y + 1 - $x );
    }
}

# Private Method _bordashrinkballot( $BallotSet, $active )

# Takes a BallotSet and active list and returns a
# BallotSet reduced to only the active choices. When
# choices are removed later choices are promoted.

sub _bordashrinkballot ( $BallotSet, $active ) {
  my $newballots = {};
  my %ballots    = $BallotSet->{'ballots'}->%*;
  for my $b ( keys %ballots ) {
    my @newballot = ();
    for my $item ( $ballots{$b}{'votes'}->@* ) {
      try { if (  $active->{$item} ) { push @newballot, $item } }
      catch {};
    }
    if ( scalar(@newballot) ) {
      $newballots->{$b}{'votes'} = \@newballot;
      $newballots->{$b}{'count'} =
        $ballots{$b}->{'count'};
    }
  }
  return $newballots;
}

sub _dobordacount ( $self, $BordaTable, $active ) {
    my $BordaCount = {};
  my $weight     = $self->bordaweight;
  my $depth =
      $self->bordadepth
    ? $self->bordadepth
    : scalar( keys %{$active} );
  for my $c ( keys $BordaTable->%* ) {
    for my $rank ( keys $BordaTable->{$c}->%* ) {
      $BordaCount->{$c} = 0 unless defined $BordaCount->{$c};
      $BordaCount->{$c} +=
        $BordaTable->{$c}{$rank} * $weight->( $rank, $depth );
    }
  }
  return $BordaCount;
}

sub Borda ( $self, $active = undef ) {
  my %BallotSet = $self->BallotSet()->%*;
  my %ballots   = ();
  if ( defined $active ) {
    die q/unrankdefault other than 0 is not compatible with overriding the
        Active Set. To fix this use the SetActive method to update the active
        set, then call this (Borda) method without passing an active set./
    if $self->unrankdefault();
  }
  $active = $self->Active() unless defined $active;
  %ballots = %{ _bordashrinkballot( \%BallotSet, $active ) };
  my %BordaTable = ( map { $_ => {} } keys( $active->%* ) );
BORDALOOPACTIVE:
  for my $b ( keys %ballots ) {
    my @votes  = $ballots{$b}->{'votes'}->@* ;
    my $bcount = $ballots{$b}->{'count'};
    for ( my $i = 0 ; $i < scalar(@votes) ; $i++ ) {
      my $c = $votes[$i];
      $BordaTable{$c}->{ $i + 1 } += $bcount;
    }
  }
  my $BordaCounted = _dobordacount( $self, \%BordaTable, $active );
  if ( $self->unrankdefault() ) {
    my $unranked = $self->NonApproval()->RawCount();
    for my $u ( keys $unranked->%* ) {
      $BordaCounted->{$u} += $unranked->{$u} * $self->unrankdefault()
    }
  }
  return Vote::Count::RankCount->Rank($BordaCounted);
}

sub borda { Borda(@_) }

1;

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019-2021 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

SUPPORT

This software is provided as is, per the terms of the GNU Public License. Professional support and customisation services are available from the author.

=cut

