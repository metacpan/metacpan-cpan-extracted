use strict;
use warnings;
use 5.024;
use feature qw /postderef signatures/;

package Vote::Count::IRV;

use namespace::autoclean;
use Moose::Role;

with 'Vote::Count::TopCount';
with 'Vote::Count::TieBreaker';

use Storable 3.15 'dclone';

our $VERSION='2.02';

=head1 NAME

Vote::Count::IRV

=head1 VERSION 2.02

=cut

# ABSTRACT: IRV Method for Vote::Count

no warnings 'experimental';
use List::Util qw( min max );
#use Data::Dumper;
# use Data::Printer;

sub _ResolveTie ( $self, $active, $tiebreaker, @tiedchoices ) {
  return @tiedchoices if @tiedchoices == 1;
  my %high =
    map { $_ => 1 } $self->TieBreaker( $tiebreaker, $active, @tiedchoices );
  if ( defined $self->{'last_tiebreaker'} ) {
    $self->logt( $self->{'last_tiebreaker'}{'terse'} );
    $self->logv( $self->{'last_tiebreaker'}{'verbose'} );
    $self->{'last_tiebreaker'} = undef;
  }
  if ( @tiedchoices == scalar( keys %high ) ) { return @tiedchoices }
  # tiebreaker returns winner, we want losers!
  # use map to remove winner(s) from @tiedchoices.
  # warning about sort interpreted as function fixed
  my @low = sort map {
    if   ( $high{$_} ) { }
    else               { $_ }
  } @tiedchoices;
  return @low;
}

sub RunIRV ( $self, $active = undef, $tiebreaker = undef ) {
  $self->_IRVDO( active => $active, tiebreaker => $tiebreaker );
}

sub RunBTRIRV ( $self, %args ) {
  my $ranking2 = $args{'ranking2'} ? $args{'ranking2'} : 'precedence';
  $self->_IRVDO( 'btr' => 1, ranking2 => $ranking2 );
}

# RunIRV needed a new argument and was a long established method,
# so now it hands everything off to this private method that uses
# named arguments.
sub _IRVDO ( $self, %args ) {
  local $" = ', ';
  my $active = defined $args{'active'} ? dclone $args{'active'} : dclone $self->Active() ;
  my $tiebreaker = do {
    if ( defined $args{'tiebreaker'} ) { $args{'tiebreaker'} }
    elsif ( defined $self->TieBreakMethod() ) { $self->TieBreakMethod() }
    else { 'all' }
  };
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
    elsif ( $args{'btr'}) {
      my $br = $self->BottomRunOff(
        'active' => $active, 'ranking2' => $args{'ranking2'} );
      $self->logv( $br->{'runoff'});
      $self->logt( "Eliminating: ${\ $br->{'eliminate'} }" );
      delete $active->{ $br->{'eliminate'} };
    }
    else { #--
      my @bottom = $self->_ResolveTie( $active, $tiebreaker, $round->ArrayBottom()->@* );
      if ( scalar(@bottom) == scalar( keys %{$active} ) ) {
        # if there is a tie at the end, the finalists should
        # be both top and bottom and the active set.
        $self->logt( "Tied: @bottom" );
        return { tie => 1, tied => \@bottom, winner => 0 };
      }
      $self->logt( "Eliminating: @bottom" );
      for my $b (@bottom) {
        delete $active->{$b};
      }
    } #--
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

An optional value to RunIRV is to specify tiebreaker, see L<Vote::Count::TieBreaker>.

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

=head1 Bottom Two Runoff IRV

B<Bottom Two Runoff IRV> is the simplest modification to IRV which meets the Condorcet Winner Criteria. Instead of eliminating the low choice, the lowest two choices enter a virtual runoff, eliminating the loser. This is the easiest possible Hand Count Condorcet method, there will always be fewer pairings than choices. As a Condorcet method it fails Later No Harm.

BTR IRV will only eliminate a member of the Smith Set when both members of the runoff are in it, so it can never eliminate the final member of the Smith Set, and is thus Smith compliant.

=head2 RunBTRIRV

  my $result = $Election->RunBTRIRV();
  my $result = $Election->RunBTRIRV( 'ranking2' => 'Approval');

Choices are ordered by TopCount, ties for position are decided by Precedence. It is mandatory that either the TieBreakMethod is Precedence or TieBreakerFallBackPrecedence is True. The optional ranking2 option will use a second method before Precedence, see UnTieList in L<Vote::Count::TieBreaker|Vote::Count::TieBreaker/UnTieList>.

The returned values and logging are the same as for RunIRV.

=cut

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

