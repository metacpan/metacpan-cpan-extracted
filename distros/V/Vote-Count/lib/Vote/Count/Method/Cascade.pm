use strict;
use warnings;
use 5.024;

package Vote::Count::Method::Cascade;
use namespace::autoclean;
use Moose;
extends 'Vote::Count::Charge::Cascade';

no warnings 'experimental';
use feature qw /postderef signatures/;

use Vote::Count::TextTableTiny qw/generate_table/;
use Vote::Count::Method::CondorcetIRV;
    # import Vote::Count::Method::CondorcetIRV;

use Storable 3.15 'dclone';
use Sort::Hash;
use Data::Dumper;
use Try::Tiny;
use Path::Tiny;
use Carp;

our $VERSION='2.02';

=head1 NAME

Vote::Count::Method::Cascade

=head1 VERSION 2.02

=cut

# ABSTRACT: A Proposal of a Complete Method using Full Cascade Vote Charging.

=pod

=head1 SYNOPSIS

....

=head1 Description

Experimental Implementation of a method using Full Cascade Charging.

=head1 The Rules

...

=cut

# Values 'none', NthApproval
has 'AutomaticDefeat' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'NthApproval',
);

has 'CalculatedPrecedenceFile' => (
  is      => 'ro',
  isa     => 'Str',
  default => '/tmp/vote_count_method_charge_precedence.txt',
);

has 'FloorRule' => (
  is      => 'rw',
  isa     => 'Str',
  default => 'Approval',
);

has 'FloorThresshold' => (
  is      => 'ro',
  isa     => 'Num',
  default => 1,
);

# values topcount, bottomrunoff, approval
has 'DropRule' => (
  is      => 'rw',
  isa     => 'Str',
  default => 'topcount',
);

has 'FinalPhase' => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);

has 'FinalPhaseMethod' => (
  is      => 'rw',
  isa     => 'Str',
  default => 'approval',
);

has 'TieBreakMethod' => (
  is      => 'rw',
  isa     => 'Str',
  default => 'buildprecedence',
);

has 'QuotaTrigger' => (
  is => 'rw',
  isa => 'Int',
  required => 1,
);

sub BUILD {
  my $self = shift @_;
  my $tbm = $self->TieBreakMethod();
  unless ( $tbm eq 'precedence' || $tbm eq 'buildprecedence' ) {
    die "TieBreaker is restricted to precedence or buildprecedence, $tbm is invalid\n"
  }
}

sub _automatic_defeat ($I) {
  my @defeated = ();
  my $rule     = $I->AutomaticDefeat();
  if    ( $rule eq 'NthApproval' ) { @defeated = NthApproval($I); }
  elsif ( lc($rule) eq 'none' )    { return 0 }
  else { ... }    # other rules might be available in the future.
  for (@defeated) { $I->Defeat($_) }
  if (@defeated) {
    $I->logt( "Defeated by $rule: " . join( ', ', @defeated ) . '.' );
    $I->STVEvent( { round => $I->Round, defeat => \@defeated } );
    return 1;
  }
  else {
    $I->logt("No Defeats by $rule.");
    return 0;
  }
}

sub _set_quota ($I) {
  my $tc    = $I->TCStats();
  my $av    = $tc->{active_vote_value};
  my $quota = $I->SetQuota();
  $I->logv("Active Vote Value: $av (${\ int ( $av / $I->VoteValue()) }) ");
  $I->logt("Quota is $quota (${\ int $quota / $I->VoteValue() })");
  return $quota;
}

sub _check_quota_changed ($I, $quota) {
  return 0 unless $I->Elected();
  my $qf =  $I->{'lastquota'} - ( $I->VoteValue * $I->QuotaTrigger );
  if ( $quota < $qf ) { return 1 }
  return 0;
}

sub _check_seatschoices ($I ) {
  my @active = $I->GetActiveList();
  my $seats  = $I->SeatsOpen();
  # FinalPhase is responsible for the last seat
  if ( $I->FinalPhase && $seats == 1 ) { return 0 }
  # Start filling seats if running out of choices.
  # Necessary to charge so that votes don't transfer.
  if ( $seats >= @active ) {
    my @sorted = $I->UnTieList( 'TopCount', @active );
    my $elect  = $sorted[0];
    $I->Elect($elect);
    $I->Charge( $elect, 0 );    # No Quota.
    $I->logt(
"Seats Open: ${seats}. Choices: ${\ scalar(@active) }. Electing: ${elect}"
    );
    $I->{'lastcharge'}{$elect} = $I->VoteValue;
    $I->STVEvent(
      {
        round      => $I->Round,
        quota      => 0,
        charge     => $I->VoteValue,
        iterations => 0,
        detail     => $I->{'lastcharge'},
      }
    );
    $I->NewRound;
    return 1;
  }
  return 0;
}

sub _do_charge ( $I, $quota, @elected ) {
  my $chargecalc = $I->CalcCharge($quota);
  my $result =
    FullCascadeCharge( $I->GetBallots, $quota, $chargecalc, $I->GetActive,
    $I->VoteValue );
  $I->{'lastcharge'} = $chargecalc;
  $I->logv( ChargeTable( $chargecalc, $result ) );
  $I->STVEvent(
    { round => $I->Round, elected => [@elected],
    result => $result, charge => $chargecalc,  } );
  return $chargecalc;
}

sub _re_charge ( $I, $quota ) {
  # my $chargecalc = $I->CalcCharge($quota);
  # my $result =
  #   FullCascadeCharge( $I->GetBallots, $quota, $chargecalc, $I->GetActive,
  #   $I->VoteValue );
  # return { charge => $chargecalc, result => $result }
  die 'recharge';
}

sub _do_drop ( $I ) {
  if ( $I->DropRule eq 'bottomrunoff' ) {
    return $I->BottomRunOff }
  elsif ( $I->DropRule eq 'approval' ) {
    return
      [ $I->UntieActive( 'Approval', 'precedence' )->OrderedList() ]->[-1];
  }
  elsif ( $I->DropRule eq 'topcount' ) {
    return
      [ $I->UntieActive( 'TopCount', 'precedence' )->OrderedList() ]->[-1];
  }
  else { die "Invalid DropRule: ${\ $I->DropRule }\n" }
}

sub _finalphase ($I) {
  return 0 unless $I->FinalPhase;
  return 0 unless $I->SeatsOpen == 1;
  my $finalmthd = $I->FinalPhaseMethod;
  my @suspended = $I->Suspended();
  $I->Reinstate( @suspended );
  # my @defeated = $I->Defeated();
  # for my $choice (@defeated) {
  #   $I->{'choice_status'}->{$choice}{'state'} = 'hopeful';
  #   $I->{'Active'}{$choice} = 1;
  # }

# path('/tmp/mockd.pl')->spew( Dumper $I->BallotSet() );
# path('/tmp/mockdactive.txt')->spew( map { "$_\n"} ( $I->GetActiveList));
  $I->logv("Only One Seat Remains, Elect last choice by $finalmthd");
  $I->logv("reinstating ${\ join ', ',  } ") if @suspended;
  $I->logv( WeightedTable($I) );
  my $winner = undef;
  if ( $finalmthd =~ /Approval|TopCount/ ) {
      $winner = do {
        my @l = $I->UntieActive( $finalmthd, 'precedence' )->OrderedList();
        $l[0];
        };
    }
  elsif ( $finalmthd eq 'IRV' ) {
    $winner = $I->RunIRV()->{'winner'};
  }  elsif ( $finalmthd =~ /smith/i ) {
    # die "Smith IRV is unweighted aborting";
warn "precedencefile ${\ $I->PrecedenceFile }";
    my $CIRV = Vote::Count::Method::CondorcetIRV->new(
      BallotSet => $I->BallotSet(),
      TieBreakMethod => 'precedence',
      PrecedenceFile => $I->PrecedenceFile,
    );
    $CIRV->SetActive( dclone $I->GetActive );
warn "CIRV active = @{[ $CIRV->GetActiveList ]}"    ;
    $winner = $CIRV->SmithSetIRV()->{'winner'};
# die $CIRV->logd;
    $I->logv( $CIRV->PairMatrix->MatrixTable );
    $I->logv( $CIRV->PairMatrix->ScoreTable );
    $I->logv( $CIRV->PairMatrix->PairingVotesTable );
    $I->logv( $CIRV->logv );
  }
  $I->logt("Last Seat By ${finalmthd}. Elected: $winner");
  $I->STVEvent(
    { round      => $I->Round,
      finalphase => 'approval',
      winner     => $winner,
      approval   => $I->Approval->RawCount
    }
  );
  $I->Elect($winner);
  return 1;
}

sub StartElection ( $Election ) {
  $Election->STVFloor();
  my @precedence = ();
  if ( $Election->TieBreakMethod() eq 'precedence' ) {
    @precedence =
      path( $Election->PrecedenceFile() )->lines( { chomp => 1 } );
    $Election->logv(qq/## Tie Breaker Precedence:/);
  }
  else {
    @precedence =
      $Election->UntieActive( 'TopCount', 'Approval' )->OrderedList;
    path( $Election->CalculatedPrecedenceFile )
      ->spew( map { "$_\n" } (@precedence) );
    $Election->PrecedenceFile( $Election->CalculatedPrecedenceFile );
    $Election->TieBreakMethod('Precedence');
    $Election->logv(
      qq/## Tie Breaker Precedence from Top Count, Approval, FallBack:/);
  }
  my $prec = 0;
  $Election->logv( map { "${\ ++$prec }. $_" } @precedence );
  $Election->{'lastquota'} = 0;
}

sub Conduct ( $I ) {
  my $forever = () = $I->GetChoices;
  $forever += 2;
  # Check Complete is in loop condition
CONDUCTCASCADELOOP: while ( $I->SeatsOpen() ) {
    # uncoverable something
    if ( $forever-- < 0 ) {
      warn "infinite loop break from CONDUCTCASCADELOOP\n";
      last CONDUCTCASCADELOOP;
    }
    $I->logt("## Round ${\ $I->Round() }");
    # Quota
    my $quota = $I->_set_quota();
my $changed = $I->_check_quota_changed( $quota ) ;
warn "--- changed $changed";
warn "*** quota set $quota . check changed $changed *** ${\ $I->{lastquota} } - " ;     $changed = $I->_check_quota_changed( $quota ) ;
warn "^^^ quota set $quota . check changed $changed *** ${\ $I->{lastquota} } - " ;
    if ( $I->_check_quota_changed( $quota ) ) {
      my $maxtries = 10;
      my $result = {};
warn "maxtries $maxtries --- "  . $I->_check_quota_changed( $quota );
warn ~~$I->_check_quota_changed . " $maxtries";
      until ( ! $I->_check_quota_changed  ) {
        last unless $maxtries;
die 'here'        ;
        $result = $I->_re_charge( $quota );
        $maxtries--;
        $I->{'lastquota'} = $quota;
        $quota = $I->_set_quota();
      }
      $I->STVEvent( { round => $I->Round, quota => $quota } );
      $I->Logv( "Recharge Round ${\ $I->Round }\n" .
        ChargeTable( $result->{charge}, $result->{result} ) );
    }
    $I->STVEvent(
      {
        round    => $I->Round,
        approval => $I->Approval->RawCount,
        topcount => $I->TopCount->RawCount
      }
    );
    $I->logv( WeightedTable($I) );
    # Automatic Defeat
    if ($I->_automatic_defeat() ) {
      $I->NewRound($quota);
      next CONDUCTCASCADELOOP;
    }
    # Check Seats vs remaining.
    # Start Electing Remaining Choices, apply Final Phase if applicable.
    if ($I->_check_seatschoices()) {
      $I->NewRound($quota);
      next CONDUCTCASCADELOOP;
    }

    # Elect
    my @elected = $I->QuotaElectDo($quota);
    # Charge
    if (@elected) {
      $I->logt( "Elected: " . join( ', ', @elected ) );
      my $charge = $I->_do_charge( $quota, @elected );
      $I->NewRound( $quota, $charge );
      next CONDUCTCASCADELOOP;
    }
    else {
      $I->logv('No Choices Meet Quota');
    }
    next CONDUCTCASCADELOOP if $I->_finalphase();
    # Drop Rule
    if ( my $defeat = $I->_do_drop() ) {
      $I->Suspend($defeat);
      $I->logv("Suspending: $defeat");
      $I->STVEvent( { round => $I->Round, suspend => [$defeat] } );
      $I->NewRound($quota);
      next CONDUCTCASCADELOOP;
    }
ENDROUND:

  }
  $I->logt( "Elected: " . join ', ', ( sort $I->Elected ) );
  $I->STVEvent( { elected => [ sort $I->Elected ] } );
  $I->WriteSTVEvent;
  return sort $I->Elected;
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

