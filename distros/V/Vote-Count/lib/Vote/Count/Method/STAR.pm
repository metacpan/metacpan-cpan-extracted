use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::STAR;
use namespace::autoclean;
use Moose;
extends 'Vote::Count';

our $VERSION='1.09';

=head1 NAME

Vote::Count::Method::STAR

=head1 VERSION 1.09

=cut

# ABSTRACT: STAR Voting.

=pod

=head1 SYNOPSIS

  use Vote::Count::Method::STAR;

  my $tennessee = Vote::Count::Method::STAR->new(
  BallotSet  => read_range_ballots('t/data/tennessee.range.json'), );
  my $winner = $tennessee->STAR() ;

  say $Election->logv();

=head1 Description

Implements the STAR method for resolving Range Ballots.

=head1 Method Common Name: STAR (Score Then Automatic Runoff)

Scores the Range Ballots, then holds a runoff between the two highest scored choices. The method is named for the acronym for Score Then Automatic Runoff.

=head2 Function Name: STAR

Conducts and Logs STAR. Returns the winner or 0 in the event of a tie.

=head2 Criteria

=head3 Simplicity

The Range Ballot is more complex for voters than the Ranked Choice Ballot. The scoring and runoff are both very simple.

=head3 Later Harm

There is significantly less Later Harm with STAR than with other Borda methods. By ranking the preferred choice with the maximum score, and alternate choices very low, the voter is minimizing the later harm impact of those later choices. With 10 choices in regular Borda, the second choice would recieve 90% of the first choice's score, by ranking later choices at the bottom of the scale the impact is much lower.

=head3 Condorcet Criteria

STAR only meets the Condorcet Loser Criteria. The runoff prevents a Condorcet Loser from winning.

STAR does not meet the Smith and Condorcet Winner Criteria.

More information is needed to know if in practice it performs better than IRV.

=head3 Consistency

STAR should meet Monotonacity. Adding a non-winning choice will have no impact on the outcome unless they can score high enough to reach and lose the runoff phase. Clone handling is dependent on the behavior of the clone group supporters, if they rank the clones far apart, the clone that attracts later support from non-clone supporters is likely to not reach the runoff.

More information is needed to know if Clone handling is good or poor in practice, and whether there is a significant consistency failure of some other type.

=head2 Implementation Notes

Beginning with version 1.08 the STAR() method returns a Hash Ref similar to other Vote::Count Methods. The key 'tie' is true for a tie false otherwise, the key 'winner' contains the winning choice or 0 if there is a tie. When there is a tie an additional key 'tied' contains an Array Ref of the tied choices.

When more than 2 choices are in a tie for the automatic runoff STAR() returns them as a tie.

=cut

no warnings 'experimental';
# use YAML::XS;

use Carp;
use List::Util qw( min max sum );
# use Data::Dumper;
use Sort::Hash;

# Similar needs will arise elsewhere. this method should be generalized
# and put in a shared role. the aability to resolve ties internally will
# also be desired.

sub _best_two ( $I, $scores ) {
  my %sv      = $scores->RawCount()->%*;
  my @order   = sort_hash( 'desc', \%sv );
  my @toptwo  = ( shift @order, shift @order );
  my %tied    = ( map { $_ => $sv{$_} } @toptwo );
  my $lastval = $sv{ $toptwo[1] };
  while ( $sv{ $order[0] } == $lastval ) {
    my $tieit = shift @order;
    $tied{$tieit} = $sv{tieit};
  }
  if ( scalar( keys %tied ) > 2 ) {
    $I->logt(
"Unhandled Situation, there is a tie in determining the top two for Automatic Runoff."
    );
    $I->logt( join( ', ', ( sort keys %tied ) ) );
    $I->logd( $scores->RankTable() );
    # $I->logd( Dumper $I );
    return ( keys %tied );
  }
  return @toptwo;
}

sub STAR ( $self, $active = undef ) {
  $active = $self->Active() unless defined $active;
  my $scores = $self->Score($active);
  $self->logv( $scores->RankTable() );
  my @best_two = $self->_best_two($scores);
  if ( scalar( @best_two ) > 2  ) {
    return { 'tie' => 1, 'winner' => 0, 'tied' => \@best_two };
  }
  my ( $A, $B ) = @best_two;
  my ( $countA, $countB ) = $self->RangeBallotPair( $A, $B );
  if ( $countA > $countB ) {
    $self->logt("Automatic Runoff Winner: $A [ $A: $countA -- $B: $countB ]");
    return { 'tie' => 0, 'winner' => $A };
  }
  elsif ( $countA < $countB ) {
    $self->logt("Automatic Runoff Winner: $B [ $B: $countB -- $A: $countA ]");
    return { 'tie' => 0, 'winner' => $B };
  }
  else {
    $self->logt("Automatic Runoff TIE: [ $A: $countA -- $B: $countB ]");
    return { 'tie' => 1, 'winner' => 0, 'tied' => [ $A, $B ] };
  }
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

