use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::IRV;

use namespace::autoclean;
use Moose::Role;

with 'Vote::Count::TopCount';
with 'Vote::Count::TieBreaker';

use Storable 3.15 'dclone';

our $VERSION='1.09';

=head1 NAME

Vote::Count::IRV

=head1 VERSION 1.09

=cut

# ABSTRACT: IRV Method for Vote::Count

no warnings 'experimental';
use List::Util qw( min max );
use Vote::Count::TextTableTiny 'generate_markdown_table';
#use Data::Dumper;

sub _ResolveTie ( $self, $active, $tiebreaker, @choices ) {
  return @choices if @choices == 1;
  my %high =
    map { $_ => 1 } $self->TieBreaker( $tiebreaker, $active, @choices );
  if ( defined $self->{'last_tiebreaker'} ) {
    $self->logt( $self->{'last_tiebreaker'}{'terse'} );
    $self->logv( $self->{'last_tiebreaker'}{'verbose'} );
    $self->{'last_tiebreaker'} = undef;
  }
  if ( @choices == scalar( keys %high ) ) { return @choices }
  # tiebreaker returns winner, we want losers!
  # use map to remove winner(s) from @choices.
  # warning about sort interpreted as function fixed
  my @low = sort map {
    if   ( $high{$_} ) { }
    else               { $_ }
  } @choices;
  return @low;
}

sub RunIRV ( $self, $active = undef, $tiebreaker = undef ) {
  # external $active should not be changed.
  if ( defined $active ) { $active = dclone $active }
  # Object's active is altered by IRV.
  else { $active = dclone $self->Active() }
  unless ( defined $tiebreaker ) {
    if ( defined $self->TieBreakMethod() ) {
      $tiebreaker = $self->TieBreakMethod();
    }
    else {
      $tiebreaker = 'all';
    }
  }
  my $roundctr = 0;
  my $maxround = scalar( keys %{$active} );
  $self->logt( "Instant Runoff Voting",
    'Choices: ', join( ', ', ( sort keys %{$active} ) ) );
  # forever loop normally ends with return from $majority
  # a tie should be detected and also generate a
  # return from the else loop.
  # if something goes wrong roundcountr/maxround
  # will generate exception.
IRVLOOP:
  until (0) {
    $roundctr++;
    die "IRVLOOP infinite stopped at $roundctr" if $roundctr > $maxround;
    my $round = $self->TopCount($active);
    $self->logv( '---', "IRV Round $roundctr", $round->RankTable() );
    my $majority = $self->EvaluateTopCountMajority($round);
    if ( defined $majority->{'winner'} ) {
      return $majority;
    }
    else {
      my @bottom =
        $self->_ResolveTie( $active, $tiebreaker, $round->ArrayBottom()->@* );
      if ( scalar(@bottom) == scalar( keys %{$active} ) ) {
        # if there is a tie at the end, the finalists should
        # be both top and bottom and the active set.
        $self->logt( "Tied: " . join( ', ', @bottom ) );
        return { tie => 1, tied => \@bottom, winner => 0 };
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

Implements Instant Runoff Voting for Vote::Count.

=head1 SYNOPSIS

  use Vote::Count::Method;
  use Vote::Count::ReadBallots 'read_ballots';

  my $Election = Vote::Count::->new(
    BallotSet => read_ballots('%path_to_my_ballots'),
    TieBreakMethod => 'grandjunction');

  my $result = $Election->RunIRV();
  my $winner = $result->{'winner'};

  say $Election->logv(); # Print the full Log.

=head1 Method Summary

Instant Runoff Voting Looks for a Majority Winner. If one isn't present the choice with the lowest Top Count is removed.

Instant Runoff Voting is easy to count by hand and meets the Later Harm and Condorcet Loser Criteria. It, unfortunately, fails a large number of consistency criteria; the order of candidate dropping matters and small changes to the votes of non-winning choices that result in changes to the dropping order can change the outcome.

Instant Runoff Voting is also known as Alternative Vote and as the Hare Method.

=head2 Tie Handling

There is no standard accepted method for IRV tie resolution, Eliminate All is a common one and the default.

Returns a tie when all of the remaining choices are in a tie. 

An optional value to RunIRV is to specify tiebreaker, see TieBreaker.

=head2 RunIRV

  $Election->RunIRV();

  $Election->RunIRV( $active )

  $Election->RunIRV( $active, 'approval' )

Runs IRV on the provided Ballot Set. Takes an optional parameter of $active which is a hashref for which the keys are the currently active choices.

Returns results in a hashref which will be the results of  Vote::Count::TopCount->EvaluateTopCountMajority, if there is no winner hash will instead be:

  tie => [true or false],
  tied => [ array of tied choices ],
  winner => a false value

Supports the Vote::Count logt, logv, and logd methods for providing details of the method.

=head2 TieBreaker

Uses TieBreaker from the TieBreaker Role. The default is 'all', which is to not break ties. 'none' the default for the Matrix (Condorcet) Object should not be used for IRV.

All was chosen as the module default because it is Later Harm safe. Modified Grand Junction is the most resolvable and is the recommended option.

In the event that the tie-breaker returns a tie eliminate all that remain tied is used, unless that would eliminate all choices, in which case the election returns a tie.

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
