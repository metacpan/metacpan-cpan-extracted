use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::CondorcetIRV;
use namespace::autoclean;
use Moose;
extends 'Vote::Count';

our $VERSION='1.08';

=head1 NAME

Vote::Count::Method::CondorcetIRV

=head1 VERSION 1.08

=cut

# ABSTRACT: Simple Condorcet IRV Methods.

=pod

=head1 SYNOPSIS

  use Vote::Count::Method::CondorcetIRV ;

  my $SmithIRV = Vote::Count::Method::CondorcetIRV->new(
    'BallotSet' => $someballotset,
  );
  my $result = $SmithIRV->SmithSetIRV() ;
  say "Winner is: " . $result->{'winner'};
  say $Election->logv();

=head1 Description

Provides Common Basic Condorcet-IRV Methods. These methods are simple and beat other Condorcet Methods on Later Harm.

=head1 Method Common Names: Smith Set IRV, Smith-IRV

Identifies the Smith Set and runs IRV on it.

=head2 Function Name: SmithSetIRV

SmithSetIRV is exported and requires a Vote::Count object, an optional second argument is an IRV tiebreaker rule name (see IRV module). It will return a hashref similar to RunIRV, in the event of a tie the Vote::Count Object's Active Set will also be the tied choices (available for any later tie breakers you would implement). Events will be logged to the Vote::Count Object.

=head2 Criteria

=head3 Simplicity

SmithSet IRV is easy to understand but requires a full matrix and thus is harder to handcount than Benham. An aggressive Floor Rule like TCA (see Floor module) is recommended. If it is desired to Hand Count, a more aggressive Floor Rule would be required, like 15% of First Choice votes. 15% First Choice limits to 6 choices, but 6 choices still require 15 pairings to complete the Matrix.

=head3 Later Harm

When there is no Condorcet Winner this method is Later Harm Sufficient. There might be edge cases where IRV's sensitivity to dropping order creates a Later Harm effect, but they should be pretty rare. When there is a Condorcet Winner the effect is the normal one for a Condorcet Method.

The easiest way to imagine a case where a choice not in the Smith Set changed the outcome is by cloning the winner, such that there is a choice defeating them in early Top Count but not defeating them. The negative impact of the clone is an established weakness of IRV. It would appear that any possible Later Harm issue in addition to being very much at the edge is more than offset by consistency improvement.

Smith Set IRV still inherits the Later Harm failure of requiring a Condorcet Winner, but it has the lowest possible Later Harm effect for a Condorcet Method. Woodhull and restricting Pairwise Opposition to the Smith Set have equal Later Harm effect to Smith Set IRV.

=head3 Condorcet Criteria

Meets Condorcer Winner, Condorcet Loser, and Smith.

=head3 Consistency

By meeting the three Condorcet Criteria a level of consistency is guaranteed. When there is no Condorcet Winner the resolution has all of the weaknesses of IRV, as discussed in the Later Harm topic above restricting IRV to the Smith Set would appear to provide a consistency gain over basic IRV.

Smith Set IRV is therefore substantially more consistent than basic IRV, but less consistent than Condorcet methods like SSD that focus on Consistency.

=head1 Smith Set Restricted MinMax (See Vote::Count::Method::MinMax)

MinMax methods do not meet the Smith Criteria nor the Condorcet Loser Criteria, two do meet the Condorcet Winner Criteria, and one meets Later Harm. Restricting MinMax to the Smith Set will make all of the sub-methods meet all three Condorcet Criteria;  "Opposition" will match the Later Harm protection of Smith Set IRV

=head1 Method Common Name: Woodhull Method (Currently Unimplemented)

The Woodhull method is similar to Smith Set IRV. The difference is: instead of eliminating the choices outside the Smith Set, Woodhull does not permit them to win. Since, it has to deal with the situation where an ineligible choice wins via IRV, it becomes slightly more complex. In addition, group elimination of unwinnable choices slightly improves consistency, which is another advantage to Smith Set IRV. As for possible differences in Later Harm effect, the Later Harm comes from the restriction of the victor to the Smith Set, which is the same effect for both methods.

The argument in favor of Woodhull over Smith would be that: Anything which alters the dropping order can alter the outcome of IRV, and Woodhull preserves the IRV dropping order. Since, a dropping order change has an equal possiblity of helping or hurting one's preferred choice, this side-effect is a random flaw. Removing the least consequential choices is preventing them from impacting the election (in a random manner), thus this author sees it as an advantage for Smith Set IRV.

=cut

no warnings 'experimental';

use Carp;

sub SmithSetIRV ( $E, $tiebreaker = 'all' ) {
  my $matrix = $E->PairMatrix();
  $E->logt('SmithSetIRV');
  my $winner = $matrix->CondorcetWinner();
  if ($winner) {
    $E->logv("Condorcet Winner: $winner");
    return {
      'winner' => $winner,
      'tied'   => 0
    };
  }
  else {
    my $Smith = $matrix->SmithSet();
    $E->logv( "Smith Set: " . join( ',', sort( keys $Smith->%* ) ) );
    my $IRV = $E->RunIRV( $Smith, $tiebreaker );
    unless ( $IRV->{'winner'} ) {
      $winner = '';
      $E->SetActive( { map { $_ => 1 } ( $IRV->{'tied'}->@* ) } );
    }
    return $IRV;
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

Copyright 2019-2020 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut

