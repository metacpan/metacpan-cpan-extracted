use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::CondorcetDropping;

use namespace::autoclean;
use Moose;
extends 'Vote::Count';

our $VERSION='1.00';

=head1 NAME

Vote::Count::Method::CondorcetDropping

=head1 VERSION 1.00

=cut

# ABSTRACT: Methods which use simple dropping rules to resolve a Winnerless Condorcet Matrix.

=pod

=head1 SYNOPSIS

  my $CondorcetElection =
    Vote::Count::Method::CondorcetDropping->new(
      'BallotSet' => $ballotset ,
      'DropStyle' => 'all',
      'DropRule'  => 'topcount',
    );

  my $Winner = $CondorcetElection->RunCondorcetDropping( $SmithSet )->{'winner'};

=head1 Condorcet Dropping Methods

This module implements dropping methodologies for resolving a Condorcet Matrix with no Winner. Dropping Methodologies apply a rule to either all remaining choices or to those with the least wins to select a choice for elimination.

=head2 Basic Dropping Methods

Supported Dropping Methods are: Borda Count (with all the attendant weighting issues), Approval, TopCount, and Greatest Loss. 

=head2 Option SkipLoserDrop

Normally RunCondorcetDropping eliminates Condorcet Losers whenever they are discovered. However, the Benham method, which is probably the most widely used method that uses simple dropping, only considers Condorcet Winners.

=cut

no warnings 'experimental';
use List::Util qw( min max );
# use YAML::XS;

use Vote::Count::Matrix;
use Carp;
# use Try::Tiny;
# use Text::Table::Tiny 'generate_markdown_table';
# use Data::Printer;
# use Data::Dumper;

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
