use strict;
use warnings;
use 5.024;
use feature qw /postderef signatures/;

package Vote::Count::Method::CondorcetDropping;

use namespace::autoclean;
use Moose;
extends 'Vote::Count';

our $VERSION='2.01';

=head1 NAME

Vote::Count::Method::CondorcetDropping

=head1 VERSION 2.01

=cut

# ABSTRACT: Methods which use simple dropping rules to resolve a Winner-less Condorcet Matrix.

=pod

=head1 Method Description for Simple Dropping

Simple Dropping eliminates the I<weakest> choice until there is a Condorcet Winner. This method is simple and widely used.

=head1 SYNOPSIS

  my $CondorcetElection =
    Vote::Count::Method::CondorcetDropping->new(
      'BallotSet' => $ballotset ,
      'DropStyle' => 'all', # default = leastwins
      'DropRule'  => 'topcount', # default
      'TieBreakMethod' => 'none', # default
    );

  my $Winner = $CondorcetElection->RunCondorcetDropping( $ActiveSet )->{'winner'};

=head1 RunCondorcetDropping

Takes an optional parameter of an Active Set as a HashRef. Returns a HashRef with the standard result keys: winner, tie, tied. Writes details to the Vote::Count logs.

=head1 Dropping Options

=head2 DropStyle

Set DropStyle to 'all' for dropping against all choices or 'leastwins' to only consider those choices.

Default is leastwins.

=head2 DropRule

Determines the rule by which choices will be eliminated when there is no Condorcet Winner. Supported Dropping Rules are: 'borda' count (with all the attendant weighting issues), 'approval', 'topcount' ('plurality'), and 'greatestloss'.

default is plurality (topcount)

=head2 SkipLoserDrop

Normally RunCondorcetDropping eliminates Condorcet Losers whenever they are discovered. Dropping Condorcet Losers will be skipped if set to 1.

=head1 Benham

This method modifies IRV by checking for a Condorcet Winner each round, and then drops the low choice as regular IRV. It is probably the most widely used Condorcet Method for Hand Counting because it does not require a full matrix. For each choice it is only required to determine if they lose to any of the other active choices. By Counting Approval at the beginning, it is often possible to determine that a choice will lose at least one pairing without conducting any pairings, then it is only necessary to check choices that possibly have no losses.

This method is fairly simple, and meets Condorcet Winner/Loser, but fails LNH, and inherits IRV's failings on consistency. BTR-IRV is even easier to Hand Count and is Smith Compliant, Benham has no obvious advantage to it, other than having been used more widely in the past.

The original method specified Random for Tie Breaker, which can be done in a reproducable manner with L<Precedence|Vote::Count::TieBreaker/Precedence>.

The following example implements Benham, resolving ties with a precedence file generated using the number of ballots cast as the random seed.

  my $Benham = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet'      => $someballotset,
    'DropStyle'      => 'all',
    'DropRule'       => 'topcount',
    'SkipLoserDrop'  => 1,
    'TieBreakMethod' => 'precedence',
    'PrecedenceFile' => '/tmp/benhamties.txt',
  );
  $Benham->CreatePrecedenceRandom( '/tmp/benhamties.txt' );
  my $Result = $Benham->RunCondorcetDropping();

=cut

no warnings 'experimental';
# use List::Util qw( min max );
# use YAML::XS;

use Vote::Count::Matrix;
use Carp;
# use Try::Tiny;
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

Copyright 2019-2021 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

SUPPORT

This software is provided as is, per the terms of the GNU Public License. Professional support and customisation services are available from the author.

=cut

