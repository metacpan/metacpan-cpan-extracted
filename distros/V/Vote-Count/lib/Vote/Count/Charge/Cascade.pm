use strict;
use warnings;
use 5.024;

package Vote::Count::Charge::Cascade;
use namespace::autoclean;
use Moose;
extends 'Vote::Count::Charge';
# with 'Vote::Count::Charge::NthApproval';

no warnings 'experimental';
use feature qw /postderef signatures/;

use Storable 3.15 'dclone';
use Mojo::Template;
use Sort::Hash;
use Data::Dumper;
use Try::Tiny;
use JSON::MaybeXS;
use YAML::XS;
use Path::Tiny;
use Carp;
use Vote::Count::Helper::FullCascadeCharge;

our $VERSION='2.00';

=head1 NAME

Vote::Count::Charge::Cascade

=head1 VERSION 2.00

=cut

has 'VoteValue' => (
  is      => 'ro',
  isa     => 'Int',
  default => 100000,
);

has 'IterationLog' => (
  is    => 'rw',
  isa   => 'Str',
  required => 0,
);

has 'EstimationRule' => (
  is    => 'ro',
  isa   => 'Str',
  default => 'estimate',
);

has 'EstimationFresh' => (
  is    => 'ro',
  isa   => 'Bool',
  default => 0,
);

has 'TieBreakMethod' => (
  is       => 'rw',
  isa      => 'Str',
  default => ''
);

sub BUILD {
  my $I = shift;
  # $I->TieBreakMethod('precedence');
  $I->TieBreakerFallBackPrecedence(1);
  $I->{'roundstatus'}  = { 0 => {} };
  $I->{'currentround'} = 0;
# to hold the last charged values for elected choices.
  $I->{'lastcharge'} = {};
}

our $coder = JSON->new->ascii->pretty;

sub Round($I) { return $I->{'currentround'}; }

# quota and charge of from previous round!
sub NewRound ( $I, $quota = 0, $charge = {} ) {
  $I->TopCount();
  my $round = ++$I->{'currentround'};
  $I->{'roundstatus'}{ $round - 1 } = {
    'charge' => $charge,
    'quota'  => $quota,
  };
  if ( keys $charge->%* ) { $I->{'lastcharge'} = $charge }
  return $round;
}

sub _preEstimate ( $I, $quota, @elected ) {
  my $estrule = $I->EstimationRule();
  my $lastround  = $I->{'currentround'} ? $I->{'currentround'} - 1 : 0;
  my $lastcharge = $I->{'lastcharge'};
  my $unw        = $I->LastTopCountUnWeighted();
  die 'LastTopCountUnWeighted failed' unless ( keys $unw->%* );
  my %estimate = ();
  my %caps     = ();
  if ( $I->EstimationFresh && $I->EstimationRule eq 'estimate') {
    die "Fresh Estimation is not compatible with EstimationRule estimate, because prior winners are not in current top count!";
  }
  for my $e (@elected) {
    if ( $I->{'lastcharge'}{$e} && ! $I->EstimationFresh ) {
      $estimate{$e} = $I->{'lastcharge'}{$e};
      $caps{$e}     = $I->{'lastcharge'}{$e};
    }
    else {
      if ($estrule eq 'estimate') { $estimate{$e} = int( $quota / $unw->{$e} ) }
      elsif ( $estrule eq 'votevalue' ) { $estimate{$e} = $I->VoteValue }
      elsif ( $estrule eq 'zero') { $estimate{$e} = 0 }
      elsif ( $estrule eq 'halfvalue' ){ $estimate{$e} = int( $I->VoteValue / 2 ) }
      $caps{$e}     = $I->VoteValue;
    }
  }
  return ( \%estimate, \%caps );
}

# Must move directly to charge after this
# --- if another topcount happens estimate will crash!
sub QuotaElectDo ( $I, $quota ) {
  my %TC        = $I->TopCount()->RawCount()->%*;
  my @Electable = ();
  for my $C ( keys %TC ) {
    if ( $TC{$C} >= $quota ) {
      $I->Elect($C);
      push @Electable, $C;
    }
  }
  return @Electable;
}

# Produce a better estimate than the previous by running
# FullCascadeCharge of the last estimate. Clones a copy of
# Ballots for the Cascade Charge.
sub _chargeInsight ( $I, $quota, $est, $cap, $bottom, $freeze, @elected ) {
  my $active = $I->GetActive();
  my %estnew = ();
  # make sure a new freeze is applied before charge evaluation.
  for my $froz ( keys $freeze->%* ) {
    $est->{$froz} = $freeze->{$froz} if $freeze->{$froz};
  }
  my %elect = map { $_ => 1 } (@elected);
  my $B     = dclone $I->GetBallots();
  my $charge =
    FullCascadeCharge( $B, $quota, $est, $active, $I->VoteValue() );
LOOPINSIGHT: for my $E (@elected) {
    if ( $freeze->{$E} ) {    # if frozen stay frozen.
      $estnew{$E} = $freeze->{$E};
      next LOOPINSIGHT;
    }
    elsif ( $charge->{$E}{'surplus'} >= 0 ) {
      $estnew{$E} =
        $est->{$E} - int( $charge->{$E}{'surplus'} / $charge->{$E}{'count'} );
    }
    else {
      $estnew{$E} = $est->{$E} -
        ( int( $charge->{$E}{'surplus'} / $charge->{$E}{'count'} ) ) + 1 ;
    }
    $estnew{$E} = $cap->{$E} if $cap->{$E} < $estnew{$E};    # apply cap.
    $estnew{$E} = $bottom->{$E}
      if $bottom->{$E} > $estnew{$E};                        # apply bottom.
  }
  return { 'result' => $charge, 'estimate' => \%estnew };
}

sub _write_iteration_log ( $I, $round, $data ) {
  if( $I->IterationLog() ) {
    my $jsonpath = $I->IterationLog() . ".$round.json";
    my $yamlpath = $I->IterationLog() . ".$round.yaml";
    path( $jsonpath )->spew( $coder->encode( $data ) );
    path( $yamlpath )->spew( Dump $data );
  }
}

sub CalcCharge ( $I, $quota ) {
  my @elected   = $I->Elected();
  my $round     = $I->Round();
  my $estimates = {};
  my $iteration = 0;
  my $freeze    = { map { $_ => 0 } @elected };
  my $bottom    = { map { $_ => 0 } @elected };
  my ( $estimate, $cap ) = _preEstimate( $I, $quota, @elected );
  $estimates->{$iteration} = $estimate;
  my $done = 0;
  my $charged = undef ; # the last value from loop is needed for log.
  until ( $done  ) {
    ++$iteration;
    if ( $iteration > 100 ) { die "Exceeded Iteration Limit!\n"}
    # for ( $estimate, $cap, $bottom, $freeze, @elected ) { warn Dumper $_}
    $charged =
      _chargeInsight( $I, $quota, $estimate, $cap, $bottom, $freeze,
      @elected );
    $estimate                = $charged->{'estimate'};
    $estimates->{$iteration} = $charged->{'estimate'};
    $done                    = 1;
    for my $V (@elected) {
      my $est1 = $estimates->{$iteration}{$V};
      my $est2 = $estimates->{ $iteration - 1 }{$V};
      if ( $est1 != $est2 ) { $done = 0 }
    }
  }
  _write_iteration_log( $I, $round, {
    estimates => $estimates,
    quota => $quota,
    charge => $estimate,
    iterations => $iteration,
    detail => $charged->{'result'} } );

  $I->STVEvent( {
    round => $round,
    quota => $quota,
    charge => $estimate,
    iterations => $iteration,
    detail => $charged->{'result'}
    } );
  return $estimate;
}

__PACKAGE__->meta->make_immutable;
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

