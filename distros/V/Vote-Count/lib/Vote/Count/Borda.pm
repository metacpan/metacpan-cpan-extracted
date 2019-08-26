use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Borda;

use Moose::Role;


our $VERSION='0.022';

=head1 NAME

Vote::Count::Borda

=head1 VERSION 0.022

=cut

# ABSTRACT: Provides Borda Count to Vote::Count objects

no warnings 'experimental';
use List::Util qw( min max );
use Vote::Count::RankCount;
# use Try::Tiny;
# use boolean;
# use Data::Printer;

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

=head1 Synopsis

  my $VC1 = Vote::Count->new(
    BallotSet  => read_ballots('t/data/data1.txt'),
    bordadepth => 5
  );

=head1 Borda Count

Scores Choices based on their position on the Ballot. The first choice candidate gets a score equal to the number of choices, each lower choice recieves 1 less.

Variations mostly relate to altering the Borda Weight for scoring. The original method scored unranked choices at 1, optionally they may be scored as 0 (which is the current module behaviour).

=head2 Borda Wieght and Depth

Numerous alternate weightings have been used.

One alternative is to score for the number of choices after the current one -- in a five choice race first is worth 4 and last is worth 0.

One major criticism of the count is that when there are many choices the difference between a first and second choice becomes negligable. Many of the alternate weights address this by either limiting the maximum depth, fixing the depth or using a different scaling such as 1/x where x is the position of the choice (1 is worth 1, 3 is 1/3).

Range Voting Proposals such as STAR typically use a fixed depth count where voters may rank choices equally.

When Creating a VoteCount object the Borda weight may be set by passing a coderef. The coderef takes two arguments. The first argument is the
position of the choice in question. The second argument is the depth of the ballot. The optional bordadepth attribute will set an arbitrary
depth. Some popular options such inversion (where choice $c becomes $c/1 then inverted to 1/$c) don't  need to know the depth. In such cases the coderef should just ignore the second argument.

  my $testweight = sub {
    my $x = int shift @_;
    return $x ? 1/$x : 0 ;
  };

  my $VC2 = Vote::Count->new(
    BallotSet   => read_ballots('t/data/data2.txt'),
    bordaweight => $testweight,
  );

=head1 To Do

Since there are so many variations of Borda, it would be nice to offer a large array of presets. Currently options are only handled by passing a coderef at object creation. Borda is not a priority for the developer, who considers Borda primarily useful as a tie breaking option or in systems like STAR that use a fixed field depth.

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
