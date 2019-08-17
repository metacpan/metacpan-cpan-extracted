use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::CondorcetIRV;

use Exporter::Easy ( EXPORT => [ 'SmithSetIRV' ] );

# use namespace::autoclean;
# use Moose;
# extends 'Vote::Count';

our $VERSION='0.021';

=head1 NAME

Vote::Count::Method::CondorcetIRV

=head1 VERSION 0.021

=cut

# ABSTRACT: Simple Condorcet IRV Methods.

=pod

=head1 SYNOPSIS

  use Vote::Count::Method::CondorcetIRV;

  ...
  # SmithSetIRV
  my $winner = SmithSetIRV( $Election );
  say $Election->logv();

=head1 Description

Provides Common Basic Condorcet-IRV Methods. These methods are simple and beat most other Condorcet Methods on Later Harm.

The author of Vote::Count recomends serious consideration to these methods and Redactionive Condorcet methods.

These methods can all be considered Sufficient in Resolvability, although specifiying a tie breaker is as always recommended.

This module exports the methods it provides which expect a Vote::Count object as an argument.

=head1 Method Common Name: SmithSet IRV

Identifies the Smith Set and runs IRV on it.

=head2 Function Name: SmithSetIRV

SmithSetIRV is exported and requires a Vote::Count object, an optional second argument is an IRV tiebreaker rule name (see IRV module). It will return the winner, in the event of the tie it will return the empty string and the Vote::Count Object's Active Set will be the tied choices (available for any later tie breakers you would implement). Events will be logged to the Vote::Count Object.

=head2 Criteria

=head3 Simplicity

SmithSet IRV is easy to understand but requires a full matrix and thus is harder to handcount than Benham. An aggressive Floor Rule like TCA (see Floor module) is recommended. If it is desired to Hand Count, a more aggressive Floor Rule would be required, like 15% of First Choice votes. 15% First Choice limits to 6 choices, but 6 choices still require 15 pairings to complete the Matrix.

=head3 Later Harm

When there is no Condorcet Winner this method is Later Harm Sufficient. There might be edge cases where IRV's sensitivity to dropping order creates a Later Harm effect, but they should be pretty rare. When there is a Condorcet Winner the effect is the normal one for a Condorcet Method.

The easiest way to imagine a case where a choice not in the Smith Set changed the outcome is by cloning the winner, such that there is a choice defeating them in early Top Count but not defeating them. The negative impact of the clone is an established weakness of IRV. It would appear that any possible Later Harm issue in addition to be very much at the edge is more than offset by consistency improvement.

Smith Set IRV still has a significant Later Harm failure, but it has demonstrably less Later Harm effect than other Condorcet methods.

=head3 Condorcet Criteria

Meets Condorcer Winner, Condorcet Loser, and Smith.

=head3 Consistency

By meeting the three Condorcet Criteria a level of consistency is guaranteed. When there is no Condorcet Winner the resolution has all of the weaknesses of IRV, as discussed in the Later Harm topic above restricting IRV to the Smith Set would appear to provide a consistency gain over basic IRV.

Smith Set IRV is therefore substantially more consistent than basic IRV, but less consistent than Condorcet methods like SSD that focus on Consistency.

=cut


no warnings 'experimental';
# use YAML::XS;

use Carp;

sub SmithSetIRV ( $E, $tiebreaker='all' ) {
  my $matrix = $E->PairMatrix();
  $E->logt( 'SmithSetIRV');
  my $winner = $matrix->CondorcetWinner();;
  if ( $winner) {
    $E->logv( "Condorcet Winner: $winner");
  } else {
    my $Smith = $matrix->SmithSet();
    $E->logv( "Smith Set: " . join( ',', sort( keys $Smith->%* )));
    my $IRV = $E->RunIRV( $Smith, $tiebreaker );
    $winner = $IRV->{'winner'};
    unless ( $winner ) {
      $winner = '';
      $E->SetActive( {map { $_ => 1 } ( $IRV->{'tied'}->@* )});
    }
  }
  return $winner;
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
