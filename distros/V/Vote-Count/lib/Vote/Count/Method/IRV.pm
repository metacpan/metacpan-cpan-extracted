use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::IRV;

use namespace::autoclean;
use Moose;
extends 'Vote::Count';

our $VERSION='0.013';

=head1 NAME

Vote::Count::IRV

=head1 VERSION 0.013

=cut

# ABSTRACT: Runs an IRV Election

no warnings 'experimental';
use List::Util qw( min max );

# use Vote::Count::RankCount;
# use Try::Tiny;
use TextTableTiny 'generate_markdown_table';
use Data::Printer;
use Data::Dumper;

# use YAML::XS;

sub RunIRV ( $self, $active = undef ) {
  unless ( defined $active ) { $active = $self->Active() }
  my $roundctr   = 0;
  my $maxround   = scalar( keys %{$active} );
  $self->logt( "Instant Runoff Voting",
    'Choices: ', join( ', ', ( sort keys %{$active} ) ) );
# forever loop normally ends with return from $majority
# a tie should be detected and also generate a
# return from the else loop.
# if something goes wrong roundcountr/maxround
# will generate exception.
IRVLOOP:
  until ( 0 ) {
    $roundctr++;
    die "IRVLOOP infinite stopped at $roundctr" if $roundctr > $maxround;
    my $round = $self->TopCount($active);
    $self->logv( '---', "IRV Round $roundctr", $round->RankTable() );
    my $majority = $self->EvaluateTopCountMajority( $round );
    if ( defined $majority->{'winner'} ) {
      return $majority;
    } else {
      my @bottom = sort $round->ArrayBottom()->@*;
      if ( scalar(@bottom) == scalar( keys %{$active} ) ) {
        # if there is a tie at the end, the finalists should
        # be both top and bottom and the active set.
        $self->logt( "Tied: " . join( ', ', @bottom ) );
        return { tie => 1, tied => \@bottom, winner => 0  };
      }
      $self->logv( "Eliminating: " . join( ', ', @bottom ) );
      for my $b (@bottom) {
        delete $active->{$b};
      }
    }
  }
}

1;

=pod

=head1 IRV

Implements Instant Runoff Voting.

=head1 SYNOPSIS

  use Vote::Count::Method::IRV;
  use Vote::Count::ReadBallots 'read_ballots';

  my $Election = Vote::Count::Method::IRV->new(
    BallotSet => read_ballots('%path_to_my_ballots'), );

  my $result = $Election->RunIRV();
  my $winner = $result->{'winner'};

  say $Election->logv(); # Print the full Log.

=head1 Method Summary

Instant Runoff Voting Looks for a Majority Winner. If one isn't present the choice with the lowest Top Count is removed.

Instant Runoff Voting is easy to count by hand and meets the Later Harm and Condorcet Loser Criteria. It, unfortunately, fails a large number of consistency criteria; the order of candidate dropping matters and small changes to the votes of non-winning choices that result in changes to the dropping order can change the outcome.

=head2 Tie Handling

If there is a tie for lowest Top Count this implementation removes all of the tied choices, or returns a tie when all choices are tied for lowest.

At present there is no interface to set a tie breaker, it is a planned feature enhancement to change this in a future release.

Your Election Rules should specify Eliminate All for ties.

There is no standard accepted method for IRV tie resolution, Eliminate All is a common one.

=head2 RunIRV

  $ElectionRunIRV();

  $ElectionRunIRV( $active )

Runs IRV on the provided Ballot Set. Takes an optional parameter of $active which is a hashref for which the keys are the currently active choices.

Returns results in a hashref which will be the results of  Vote::Count::TopCount->EvaluateTopCountMajority, if there is no winner hash will instead be:
  tie => [true or false],
  tied => [ array of tied choices ],
  winner => a false value

Supports the Vote::Count logt, logv, and logd methods for providing details of the method.

=cut

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

