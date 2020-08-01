use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::MinMax;

use namespace::autoclean;
use Moose;
extends 'Vote::Count::Matrix';

our $VERSION='1.06';

=head1 NAME

Vote::Count::Method::MinMax

=head1 VERSION 1.06

=cut

# ABSTRACT: Methods in the MinMax Family.

=pod

=head1 SYNOPSIS

  my $MinMaxElection =
    Vote::Count::Method::MinMax->new(
      'BallotSet' => $ballotset ,
      'DropStyle' => 'all',
      'DropRule'  => 'topcount',
    );

  my $Winner = $CondorcetElection->RunCondorcetDropping( $SmithSet )->{'winner'};

=head1 Shameless Piracy of Electowiki

Minmax or Minimax (Simpson-Kramer method) is the name of several election methods based on electing the candidate with the lowest score, based on votes received in pairwise contests with other candidates.

Minmax(winning votes) elects the candidate whose greatest pairwise loss to another candidate is the least, when the strength of a pairwise loss is measured as the number of voters who voted for the winning side.

Minmax(margins) is the same, except that the strength of a pairwise loss is measured as the number of votes for the winning side minus the number of votes for the losing side.

Criteria passed by both methods: Condorcet criterion, majority criterion

Criteria failed by both methods: Smith criterion, mutual majority criterion, Condorcet loser criterion.

Minmax(winning votes) also satisfies the Plurality criterion. In the three-candidate case, Minmax(margins) satisfies the Participation criterion.

Minmax(pairwise opposition) or MMPO elects the candidate whose greatest opposition from another candidate is minimal. Pairwise wins or losses are not considered; all that matters is the number of votes for one candidate over another.

Pairwise opposition is defined for a pair of candidates. For X and Y, X's pairwise opposition in that pair is the number of ballots ranking Y over X. MMPO elects the candidate whose greatest pairwise opposition is the least.

Minmax(pairwise opposition) does not strictly satisfy the Condorcet criterion or Smith criterion. It also fails the Plurality criterion, and is more indecisive than the other Minmax methods (unless it's used with a tiebreaking rule such as the simple one described below). However, it satisfies the Later-no-harm criterion, the Favorite Betrayal criterion, and in the three-candidate case, the Participation criterion, and the Chicken Dilemma Criterion.

MMPO's choice rule can be regarded as a kind of social optimization: The election of the candidate to whom fewest people prefer another. That choice rule can be offered as a standard in and of itself.

MMPO's simple tiebreaker:

If two or more candidates have the same greatest pairwise opposition, then elect the one that has the lowest next-greatest pairwise opposition. Repeat as needed. 

=cut

no warnings 'experimental';
use List::Util qw( min max );
use Carp;
use Try::Tiny;
use Data::Dumper;

sub _scorewinningvotes ( $self ) {

}

=pod
has 'Matrix' => (
  isa     => 'Object',
  is      => 'ro',
  lazy    => 1,
  builder => '_newmatrix',
);

# DropStyle: whether to apply drop rule against
# all choices ('all') or the least winning ('leastwins').
has 'DropStyle' => (
  isa     => 'Str',
  is      => 'ro',
  default => 'leastwins',
);

has 'DropRule' => (
  isa     => 'Str',
  is      => 'ro',
  default => 'plurality',
);

has 'SkipLoserDrop' => (
  isa     => 'Int',
  is      => 'ro',
  default => 0,
);

sub GetRound ( $self, $active, $roundnum = '' ) {
  my $rule = lc( $self->DropRule() );
  if ( $rule =~ m/(plurality|topcount)/ ) {
    return $self->TopCount($active);
  }
  elsif ( $rule eq 'approval' ) {
    my $round = $self->Approval($active);
    $self->logv( "Round $roundnum Approval Totals ", $round->RankTable() );
    return $round;
  }
  elsif ( $rule eq 'borda' ) {
    my $round = $self->Borda($active);
    $self->logv( "Round $roundnum Borda Count ", $round->RankTable() );
    return $round;
  }
  elsif ( $rule eq 'greatestloss' ) {
    return $self->Matrix()->RankGreatestLoss($active);
  }
  else {
    croak "undefined dropping rule $rule requested";
  }
}

sub DropChoice ( $self, $round, @jeapardy ) {
  my %roundvotes = $round->RawCount()->%*;
  my @eliminate  = ();
  my $lowest     = $round->CountVotes();
  for my $j (@jeapardy) {
    $lowest = $roundvotes{$j} if $roundvotes{$j} < $lowest;
  }
  for my $j (@jeapardy) {
    if ( $roundvotes{$j} == $lowest ) {
      push @eliminate, $j;
    }
  }
  return @eliminate;
}

sub _newmatrix ($self) {
  return Vote::Count::Matrix->new(
    'BallotSet' => $self->BallotSet(),
    Active      => $self->Active()
  );
}

sub _logstart ( $self, $active ) {
  my $dropdescription = 'Elimination Rule is Applied to All Active Choices.';
  if ( $self->DropStyle eq 'leastwins' ) {
    $dropdescription =
      'Elimination Rule is Applied to only Choices with the Fewest Wins.';
  }
  my $rule = '';
  if ( $self->DropRule() =~ m/(plurality|topcount)/ ) {
    $rule = "Drop the Choice With the Lowest TopCount.";
  }
  elsif ( $self->DropRule() eq 'approval' ) {
    $rule = "Drop the Choice With the Lowest Approval.";
  }
  elsif ( $self->DropRule() eq 'borda' ) {
    $rule = "Drop the Choice With the Lowest Borda Score.";
  }
  elsif ( $self->DropRule() eq 'greatestloss' ) {
    $rule = "Drop the Choice With the Greatest Loss.";
  }
  else {
    croak "undefined dropping rule $rule requested";
  }
  $self->logt( 'CONDORCET SEQUENTIAL DROPPING METHOD',
    'CHOICES:', join( ', ', ( sort keys %{$active} ) ) );
  $self->logv( "Elimination Rule: $rule", $dropdescription );
}

sub RunCondorcetDropping ( $self, $active = undef ) {
  unless ( defined $active ) { $active = $self->Active() }
  my $roundctr = 0;
  my $maxround = scalar( keys %{$active} );
  $self->_logstart($active);
  my $result = { tie => 0, tied => undef, winner => 0 };
DROPLOOP:
  until (0) {
    $roundctr++;
    die "DROPLOOP infinite stopped at $roundctr" if $roundctr > $maxround;
    my $topcount = $self->TopCount($active);
    my $round = $self->GetRound( $active, $roundctr );
    $self->logv( '---', "Round $roundctr TopCount", $topcount->RankTable() );
    my $majority = $self->EvaluateTopCountMajority($topcount);
    if ( defined $majority->{'winner'} ) {
      $result->{'winner'} = $majority->{'winner'};
      last DROPLOOP;
    }
    my $matrix = Vote::Count::Matrix->new(
      'BallotSet' => $self->BallotSet,
      'Active'    => $active
    );
    $self->logv( '---', "Round $roundctr Pairings", $matrix->MatrixTable() );
    my $cw = $matrix->CondorcetWinner() || 0;
    if ($cw) {
      my $wstr = "*  Winner $cw  *";
      my $rpt  = length($wstr);
      $self->logt( '*' x $rpt, $wstr, '*' x $rpt );
      $result->{'winner'} = $cw;
      last DROPLOOP;
    }
    my $eliminated =
      $self->SkipLoserDrop()
      ? { 'eliminations' => 0 }
      : $matrix->CondorcetLoser();
    if ( $eliminated->{'eliminations'} ) {
      # tracking active between iterations of matrix.
      $active = $matrix->Active();
      $self->logv( $eliminated->{'verbose'} );
      # active changed, restart loop
      next DROPLOOP;
    }
    my @jeapardy = ();
    if ( $self->DropStyle eq 'leastwins' ) {
      @jeapardy = $matrix->LeastWins();
    }
    else { @jeapardy = keys %{$active} }
    for my $goodbye ( $self->DropChoice( $round, @jeapardy ) ) {
      delete $active->{$goodbye};
      $self->logv("Eliminating $goodbye");
    }
    my @remaining = keys $active->%*;
    if ( @remaining == 0 ) {
      $self->logt(
        "All remaining Choices would be eliminated, Tie between @jeapardy");
      $result->{'tie'}  = 1;
      $result->{'tied'} = \@jeapardy;
      last DROPLOOP;
    }
    elsif ( @remaining == 1 ) {
      my $winner = $remaining[0];
      $self->logt( "Only 1 choice remains.", "** WINNER : $winner **" );
      $result->{'winner'} = $winner;
      last DROPLOOP;
    }
  };    #infinite DROPLOOP
  return $result;
}

=cut

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
