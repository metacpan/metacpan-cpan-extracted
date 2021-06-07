use strict;
use warnings;
use 5.024;
use feature qw /postderef signatures switch/;

package Vote::Count::Charge;
use namespace::autoclean;
use Moose;
extends 'Vote::Count';

no warnings 'experimental::signatures';
no warnings 'experimental::smartmatch';

use Sort::Hash;
use Data::Dumper;
use Time::Piece;
use Path::Tiny;
use Carp;
use JSON::MaybeXS;
use YAML::XS;
# use Storable 3.15 'dclone';

our $VERSION='2.00';

has 'Seats' => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

has 'FloorRule' => (
  is       => 'rw',
  isa      => 'Str',
  default  => '',
);

has 'FloorThresshold' => (
  is      => 'ro',
  isa     => 'Num',
  default => 0,
  );

my @choice_valid_states =
  qw( elected pending defeated withdrawn active suspended );

sub _init_choice_status ( $I ) {
  $I->{'choice_status'} = {};
  $I->{'pending'}       = [];
  $I->{'elected'}       = [];
  $I->{'suspended'}     = [];
  $I->{'deferred'}      = [];
  $I->{'stvlog'}        = [];
  $I->{'stvround'}      = 0;
  for my $c ( $I->GetChoices() ) {
    $I->{'choice_status'}->{$c} = {
      state => 'hopeful',
      votes => 0,
    };
  }
  if ( $I->WithdrawalList ) {
    for my $w (path( $I->WithdrawalList )->lines({ chomp => 1})) {
      $I->Withdraw($w) if defined $I->{'choice_status'}{$w};
    }
  }
}

# Default tie breaking to Precedence,
# Force Precedence as fallback, and generate reproducible precedence
# file if one isn't provided.
sub _setTieBreaks ( $I ) {
  no warnings 'uninitialized';
  unless ( $I->TieBreakMethod() ) {
    $I->logd('TieBreakMethod is undefined, setting to precedence');
    $I->TieBreakMethod('precedence');
  }
  if ( $I->TieBreakMethod ne 'precedence' ) {
    $I->logv( 'Ties will be broken by: '
        . $I->TieBreakMethod
        . ' with a fallback of precedence' );
    $I->TieBreakerFallBackPrecedence(1);
  }
  unless ( stat $I->PrecedenceFile ) {
    my @order = $I->CreatePrecedenceRandom('/tmp/precedence.txt');
    $I->PrecedenceFile('/tmp/precedence.txt');
    $I->logv( "Order for Random Tie Breakers is: " . join( ", ", @order ) );
  }
}

sub ResetVoteValue ($I) {
  my $ballots = $I->GetBallots();
  for my $b ( keys $ballots->%* ) {
    $ballots->{$b}->{'votevalue'} = $I->VoteValue();
    $ballots->{$b}->{'topchoice'} = undef;
  }
}

sub SeatsOpen ($I) { $I->Seats() - $I->Elected() }

sub BUILD {
  my $self = shift;
  unless ( $self->BallotSetType() eq 'rcv' ) {
    croak "Charge only supports rcv Ballot Type";
  }
  $self->_setTieBreaks();
  $self->ResetVoteValue();
  $self->_init_choice_status();
  $self->FloorRounding('down');
}

=pod

CountAbandoned

=cut

sub CountAbandoned ($I) {
  my @continuing = ( $I->Deferred(), $I->GetActiveList );
  my $set        = $I->GetBallots();
  my %res        = ( count_abandoned => 0, value_abandoned => 0, );
  for my $k ( keys $set->%* ) {
    if ( $set->{$k}{'votevalue'} == 0 ) {
      $res{count_abandoned} += $set->{$k}{'count'};
      next;
    }
    my $continue = 0;
    for my $c (@continuing) {
      $continue += ( grep /$c/, $set->{$k}{'votes'}->@* );
    }
    unless ($continue) {
      $res{count_abandoned} += $set->{$k}{'count'};
      $res{value_abandoned} += $set->{$k}{'count'} * $set->{$k}{'votevalue'};
    }
  }
  $res{message} =
"Votes with no Choice left: $res{count_abandoned}, Value: $res{value_abandoned}";
  return \%res;
}

sub GetChoiceStatus ( $I, $choice = 0 ) {
  if   ($choice) { return $I->{'choice_status'}{$choice} }
  else           { return $I->{'choice_status'} }
}

sub SetChoiceStatus ( $I, $choice, $status ) {
  if ( $status->{'state'} ) {
    unless ( grep ( /^$status->{'state'}$/, @choice_valid_states ) ) {
      croak "invalid state *$status->{'state'}* assigned to choice $choice";
    }
    $I->{'choice_status'}->{$choice}{'state'} = $status->{'state'};
  }
  if ( $status->{'votes'} ) {
    $I->{'choice_status'}->{$choice}{'votes'} = int $status->{'votes'};
  }
}

sub VCUpdateActive ($I) {
  my $active = {};
  for my $k ( keys $I->GetChoiceStatus()->%* ) {
    $active->{$k} = 1 if $I->{'choice_status'}->{$k}{'state'} eq 'hopeful';
    $active->{$k} = 1 if $I->{'choice_status'}->{$k}{'state'} eq 'pending';
  }
  $I->SetActive($active);
}

sub Elect ( $I, $choice ) {
  delete $I->{'Active'}{$choice};
  $I->{'choice_status'}->{$choice}{'state'} = 'elected';
  $I->{'pending'} = [ grep ( !/^$choice$/, $I->{'pending'}->@* ) ];
  push $I->{'elected'}->@*, $choice;
  return $I->{'elected'}->@*;
}

sub Elected ($I) { return $I->{'elected'}->@* }

sub Defeat ( $I, $choice ) {
  delete $I->{'Active'}{$choice};
  $I->{'choice_status'}->{$choice}{'state'} = 'defeated';
}

sub Defeated ($I) {
  my @defeated = ();
  for my $c ( keys  $I->{'choice_status'}->%* ) {
    if ( $I->{'choice_status'}{$c}{'state'} eq 'defeated') {
      push @defeated, $c;
    }
  }
  return sort(@defeated);
}

sub Withdrawn ($I) {
  my @withdrawn = ();
  for my $c ( keys  $I->{'choice_status'}->%* ) {
    if ( $I->{'choice_status'}{$c}{'state'} eq 'withdrawn') {
      push @withdrawn, $c;
    }
  }
  return sort(@withdrawn);
}

sub Withdraw ( $I, $choice ) {
  delete $I->{'Active'}{$choice};
  $I->{'choice_status'}->{$choice}{'state'} = 'withdrawn';
  return $I->Withdrawn();
}

sub Suspend ( $I, $choice ) {
  delete $I->{'Active'}{$choice};
  $I->{'choice_status'}->{$choice}{'state'} = 'suspended';
  unless ( grep ( /^$choice$/, $I->{'suspended'}->@* ) ) {
    push $I->{'suspended'}->@*, $choice;
  }
  return $I->Suspended();
}

sub Suspended ($I ) {
  return $I->{'suspended'}->@*;
}

sub Defer ( $I, $choice ) {
  delete $I->{'Active'}{$choice};
  $I->{'choice_status'}->{$choice}{'state'} = 'deferred';
  unless ( grep ( /^$choice$/, $I->{'deferred'}->@* ) ) {
    push $I->{'deferred'}->@*, $choice;
  }
  return $I->Deferred();
}

sub Deferred ($I ) {
  return $I->{'deferred'}->@*;
}

sub Pending ( $I, $choice = undef ) {
  if ($choice) {
    unless ( grep /^$choice$/, $I->{'pending'}->@* ) {
      $I->{'choice_status'}->{$choice}{'state'} = 'pending';
      push $I->{'pending'}->@*, $choice;
      delete $I->{'Active'}{$choice};
    }
  }
  return $I->{'pending'}->@*;
}

sub Reinstate ( $I, @choices ) {
  # if no choices are given reinstate all.
  @choices = ($I->{'suspended'}->@*, $I->{'deferred'}->@* ) unless @choices;
  my @reinstated = ();
REINSTATELOOP:
  for my $choice (@choices) {
  # I'm a fan of the give/when construct, but go to lengths not to use it
  # because of past issues and that after 15 years it is still experimental.
    given ($I->{'choice_status'}{$choice}{'state'}){
      when ( 'suspended') { }
      when ( 'deferred' )  { }
      default { next REINSTATELOOP }
    };
    ($I->{'suspended'}->@*) = grep ( !/^$choice$/, $I->{'suspended'}->@* );
    ($I->{'deferred'}->@*) = grep ( !/^$choice$/, $I->{'deferred'}->@* );
    $I->{'choice_status'}->{$choice}{'state'} = 'hopeful';
    $I->{'Active'}{$choice} = 1;
    push @reinstated, $choice;
  }
  return @reinstated;
}

sub Charge ( $I, $choice, $quota, $charge=$I->VoteValue() ) {
  my $charged      = 0;
  my $surplus      = 0;
  my @ballotschrgd = ();
  my $cntchrgd     = 0;
  my $active       = $I->Active();
  my $ballots      = $I->BallotSet()->{'ballots'};
  # warn Dumper $ballots;
CHARGECHECKBALLOTS:
  for my $B ( keys $ballots->%* ) {
    next CHARGECHECKBALLOTS if ( $I->TopChoice($B) ne $choice );
    my $ballot = $ballots->{$B};
    if ( $charge == 0 ) {
      $charged += $ballot->{'votevalue'} * $ballot->{'count'};
      $ballot->{'charged'}{$choice} = $ballot->{'votevalue'};
      $ballot->{'votevalue'} = 0;
    }
    elsif ( $ballot->{'votevalue'} >= $charge ) {
      my $over = $ballot->{'votevalue'} - $charge;
      $charged += ( $ballot->{'votevalue'} - $over ) * $ballot->{'count'};
      $ballot->{'votevalue'} -= $charge;
      $ballot->{'charged'}{$choice} = $charge;
    }
    else {
      $charged += $ballot->{'votevalue'} * $ballot->{'count'};
      $ballot->{'charged'}{$choice} = $ballot->{'votevalue'};
      $ballot->{'votevalue'} = 0;
    }
    push @ballotschrgd, $B;
    $cntchrgd += $ballot->{'count'};
  }
  $I->{'choice_status'}->{$choice}{'votes'} += $charged;
  $surplus = $I->{'choice_status'}->{$choice}{'votes'} - $quota;
  $I->{'choice_status'}->{$choice}{'votes'} = $charged;
  return (
    {
      choice       => $choice,
      surplus      => $surplus,
      ballotschrgd => \@ballotschrgd,
      cntchrgd     => $cntchrgd,
      quota        => $quota
    }
  );
}

sub STVEvent ( $I, $data = 0 ) {
  return $I->{'stvlog'} unless $data;
  push $I->{'stvlog'}->@*, $data;
}

sub WriteSTVEvent( $I) {
  my $jsonpath = $I->LogTo . '_stvevents.json';
  my $yamlpath = $I->LogTo . '_stvevents.yaml';
  # my $yaml = ;
  my $coder = JSON->new->ascii->pretty;
  path($jsonpath)->spew( $coder->encode( $I->STVEvent() ) );
  path($yamlpath)->spew( Dump $I->STVEvent() );
}

sub STVRound($I) { return $I->{'stvround'} }

sub NextSTVRound( $I) { return ++$I->{'stvround'} }

sub TCStats( $I ) {
  my $tc = $I->TopCount;
  $tc->{'total_votes'}      = $I->VotesCast;
  $tc->{'total_vote_value'} = $tc->{'total_votes'} * $I->VoteValue;
  $tc->{'abandoned'}        = $I->CountAbandoned;
  $tc->{'active_vote_value'} =
    $tc->{'total_vote_value'} - $tc->{'abandoned'}{'value_abandoned'};
  return $tc;
}

sub STVFloor ( $I, $action='Withdraw' ) {
  if ( $I->FloorRule() && $I->FloorThresshold() ) {
    $I->FloorRule('ApprovalFloor') if $I->FloorRule() eq 'Approval';
    $I->FloorRule('TopCountFloor') if $I->FloorRule() eq 'TopCount';
    my @withdrawn =();
    my $newactive =
      $I->ApplyFloor(
        $I->FloorRule(),
        $I->FloorThresshold()
      );
    for my $choice (sort $I->GetChoices()) {
      unless( $newactive->{$choice}) {
        $I->$action( $choice );
        push @withdrawn, $choice;
      }
    }
    @withdrawn = sort (@withdrawn);
    my $done = $action;
    $done = 'Withdrawn' if $action eq 'Withdraw';
    $done = 'Defeated' if $action eq 'Defeat';
    return @withdrawn;
  }
}

sub SetQuota ($I, $style='droop') {
  my $abandoned   = $I->CountAbandoned();
  my $abndnvotes  = $abandoned->{'value_abandoned'};
  my $cast        = $I->BallotSet->{'votescast'};
  my $numerator   = ( $cast * $I->VoteValue ) - $abndnvotes;
  my $denominator = $I->Seats();
  my $adjust = 0;
  if ( $style eq 'droop' ) {
    $denominator++;
    $adjust = 1;
  }
  return ( $adjust + int( $numerator / $denominator ) );
}

=head1 NAME

Vote::Count::Charge

=head1 VERSION 2.00

=cut

# ABSTRACT: Vote::Charge - implementation of STV.

=pod

=head1 SYNOPSIS

  my $E = Vote::Count::Charge->new(
    Seats => 3,
    VoteValue => 1000,
    BallotSet => read_ballots('t/data/data1.txt', ) );

  $E->Elect('SOMECHOICE');
  $E->Charge('SOMECHOICE', $quota, $perCharge );
  say E->GetChoiceStatus( 'CARAMEL'),
   >  { state => 'withdrawn', votes => 0 }

=head1 Vote Charge implementation of Surplus Transfer

Vote Charge is how Vote::Count implements Surplus Transfer. The wording is chosen to make the concept more accessible to a general audience. It also uses integer math and imposes truncation as the rounding rule.

Vote Charge describes the process of Single Transferable Vote as:

The Votes are assigned a value, based on the number of seats and the total value of all of the votes, a cost is determined for electing a choice. The votes supporting that choice are then charged to pay that cost. The remainder of the value for the vote, if any, is available for the next highest choice of the vote.

When value is transferred back to the vote, Vote Charge refers to it as a Rebate.

Vote Charge uses integer math and truncates all remainders. Setting the Vote Value is equivalent to setting a number of decimal places, a Vote Value of 100,000 is the same as a 5 decimal place precision.

=head1 Description

This module provides methods that can be shared between Charge implementations and does not present a complete tool for conducting STV elections. Look at the Methods that have been implemented as part of Vote::Count.

=head1 Candidate / Choices States

Single Transferable Vote rules have more states than Active, Eliminated and Elected. Not all methods need all of the possible states. The SetChoiceStatus method is not linked to the underlying Vote::Count objects Active Set, the action methods: Elect, Defeat, Suspend, Defer, Reinstate, Withdraw do update the Active Set.

Active choices are referred to as Hopeful. The normal methods for accessing the Active list are available. Although not prevented from doing so, STV Methods should not directly set the active list, but rely on methods that manipulate candidate state. The VCUpdateActive method will sync the Active set with the STV choice states corresponding to active.

=over

=item *

hopeful: The default active state of a choice.

=item *

withdrawn: A choice that will be treated as not present.

=item *

defeated: A choice that will no longer be considered for election.

=item *

deferred and suspended:

A choice that is temporarily removed from consideration. Suspended is treated the same as Defeated, but is eligible for reinstatement. Deferred is removed from the ActiveSet, but treated as present when calculating Quota and Non-Continuing Votes.

=item *

elected and pending:

Elected and Pending choices are removed from the Active Set, but Pending choices are not yet considered elected. The Pending state is available to hold newly elected choices for a method that will not immediately complete processing their election.

=back

=head3 GetChoiceStatus

When called with the argument of a Choice, returns a hashref with the keys 'state' and 'votes'. When called without argument returns a hashref with the Choices as keys, and the values a hashref with the 'state' and 'votes' keys.

=head3 SetChoiceStatus

Takes the arguments of a Choice and a hashref with the keys 'state' and 'votes'. This method does not keep the underlying active list in Sync. Use either the targeted methods such as Suspend and Defeat or use VCUpdateActive to force the update.

=head3 VCUpdateActive

Update the ActiveSet of the underlying Vote::Count object to match the set of Choices that are currently 'hopeful' or 'pending'.

=head2 Elected and Pending

In addition to Elected, there is a Pending State. Pending means a Choice has reached the Quota, but not completed its Charges and Rebates. The distinction is for the benefit of methods that need choices held in pending, both Pending and Elected choices are removed from the active set.

=head3 Elect, Elected

Set Choice as Elected. Elected returns the list of currently elected choices.

=head3 Pending

Takes an Choice to set as Pending. Returns the list of Pending Choices.

=head2 Eliminated: Withdrawn, Defeated, or Suspended

In methods that set the Quota only once, choices eliminated before setting Quota are Withdrawn and may result in null ballots that can be exluded. Choices eliminated after setting Quota are Defeated. Some rules bring eliminated Choices back in later Rounds, Suspended distinguishes those eligible to return.

=head3 Defeat, Defer, Withdraw, Suspend

Perform the corresponding action for a Choice.

  $Election->Defeat('MARMALADE');

=head3 Defeated, Deferred, Withdrawn, Suspended

Returns a list of choices in that state.

=head3 Reinstate

Will reinstate all currently suspended choices or may be given a list of suspended choices that will be reinstated.

=head2 STVRound, NextSTVRound

STVRound returns the current Round, NextSTVRound advances the Round Counter and returns the new Round number.

=head2 STVEvent

Takes a reference as argument to add that reference to an Event History. This needs to be done seperately from logI<x> because STVEvent holds a list of data references instead of readably formatted events.

=head2 WriteSTVEvent

Writes JSON and YAML logs (path based on LogTo) of the STVEvents.

=head2 SetQuota

Calculate the Hare or Droop Quota. After the Division the result is rounded down and 1 is added to the result. The default is the Droop Quota, but either C<'hare'> or C<'droop'> may be requested as an optional parameter.

  my $droopquota = $Election->SetQuota();
  my $harequota = $Election->SetQuota('hare');

The Hare formula is Active Votes divided by number of Seats. Droop adds 1 to the number of seats, and to the result after rounding, resulting in a lower quota. The Droop Quota is the smallest for which it is impossible for more choices than the number of seats to reach the quota.

=head2 Charge

Charges Ballots for election of choice, parameters are $choice, $quota and $charge (defaults to VoteValue ).

=head2 ResetVoteValue

Resets all Ballots to their initial Vote Value.

=head2 SeatsOpen

Calculate and return the number of seats remaining to fill.

=cut

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

