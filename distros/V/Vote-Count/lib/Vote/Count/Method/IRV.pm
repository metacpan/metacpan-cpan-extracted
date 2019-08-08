use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::IRV;

use namespace::autoclean;
use Moose;
extends 'Vote::Count';

our $VERSION='0.017';

=head1 NAME

Vote::Count::IRV

=head1 VERSION 0.017

=cut

# ABSTRACT: Runs an IRV Election

no warnings 'experimental';
use List::Util qw( min max );

# use Vote::Count::RankCount;
# use Try::Tiny;
use TextTableTiny 'generate_markdown_table';
#use Data::Printer;
#use Data::Dumper;

sub _TieBreaker ( $I, $tiebreaker, $active, @choices ) {
  if ( $tiebreaker eq 'all') { return @choices }
  my $ranked = undef;
  if ( $tiebreaker eq 'borda') {
    $ranked = $I->Borda( $active );
  } elsif ( $tiebreaker eq 'borda_all') {
    $ranked = $I->Borda( $I->BallotSet()->{'choices'} );
  } elsif ( $tiebreaker eq 'approval') {
    $ranked = $I->Approval();
  } else { die "undefined tiebreak method $tiebreaker!\n"}
  my @highchoice = () ;
  my $highest = 0;
  my $counted = $ranked->RawCount();
  for my $c (@choices) {
    if ( $counted->{$c} > $highest ) {
      @highchoice = ( $c );
      $highest = $counted->{$c};
    } elsif ( $counted->{$c} == $highest ) {
      push @highchoice, $c;
    }
  }
  return @highchoice;
}

sub RunIRV ( $self, $active = undef, $tiebreaker = 'all' ) {
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
      my @bottom = sort $self->_TieBreaker(
        $tiebreaker,
        $active,
        $round->ArrayBottom()->@* );
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

There is no standard accepted method for IRV tie resolution, Eliminate All is a common one and the default.

If there is a tie for lowest Top Count the default is 'all' of the tied choices. Returns a tie when all of the remaining choices are in a tie. An optional value to RunIRV is to specify tiebreaker, see _TieBreaker.

=head2 _TieBreaker

Implements some basic methods for resolving ties. By default RunIRV sets a variable of $tiebreaker = 'all', which is to delete all tied choices. Alternate values that can be set are 'borda' (Borda Count the currently active choices), 'borda_all' (Borda Count all of the Choices on the Ballots), and Approval. The Borda Count methods use the defaults.

Tie Break Methods not provided can be implemented by extending Vote::Count::Method::IRV and over-writing the _TieBreaker Method.

  my @remove = $self->_TieBreaker( $tiebreaker, $active, @choices );

=cut

=head2 RunIRV

  $ElectionRunIRV();

  $ElectionRunIRV( $active )

  $ElectionRunIRV( $active, 'approval' )

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

