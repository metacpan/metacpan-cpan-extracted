use strict;
use warnings;
use 5.024;

package Vote::Count::Method::WIGM;
use namespace::autoclean;
use Moose;
extends 'Vote::Count::Charge';

no warnings 'experimental';
use feature qw /postderef signatures/;

use Storable 3.15 'dclone';
use Mojo::Template;
use Sort::Hash;
use Data::Dumper;

our $VERSION='2.02';

=head1 NAME

Vote::Count::Method::WIGM

=head1 VERSION 2.02

=cut

# ABSTRACT: An implementation of WIGM STV using Vote::Charge.

=pod

=head1 SYNOPSIS

  use Vote::Count::Method::WIGM;
  use Vote::Count::ReadBallots 'read_ballots';

  my $ballotset = read_ballots('t/data/Scotland2012/Cumbernauld_South.txt');
  my $Cumbernauld   = Vote::Count::Method::WIGM->new(
    Seats     => 4,
    BallotSet => $ballotset,
    VoteValue => 100000, # default
    LogTo => '/tmp/cumbernauld_south_2012',
  );

  # Run the Election
  $D->WIGRun();
  # Write the Human Readable Logs
  $D->WriteLog();
  # Write the Events in JSON and YAML
  $D->WriteSTVEvent();

=head1 Description

Implements Weighted Improved Gregory Single Transferable Vote based on Scotland's rules.

=head1 WIGRun

Run and log the Election.

=head2 Implementation Notes

The Scottish Rules specify 5 decimal places, a weight of 100,000 is used which is equivalent.

When more than one choice is Pending the rules call for a full Stage to elect each of them. Pending Choices cannot recieve additional votes, this implementation elects, charges, and rebates the Pending Choices, then starts a new Round. The final result will be the same, but Vote::Count::Method::WIGM rounds will not always match the stages of the Hand Count rules.

=head1 Experimental

Small discrepencies with the stages data available for testing have been seen, which are likely to be rounding issues. Until further review can be taken, this code should be considered a preview.

=head1 The Rules

L<The Official Rules|http://www.opsi.gov.uk/legislation/scotland/ssi2007/ssi_20070042_en.pdf>

=cut

has 'VoteValue' => (
  is      => 'ro',
  isa     => 'Int',
  default => 100000,
);

sub _SetWIGQuota ( $I, $ballots = 0 ) {
  $ballots = $I->VotesCast() unless $ballots;
  my $denominator = $I->Seats() + 1;
  my $q           = 1 + int( $ballots / $denominator );
  return ( $q * $I->VoteValue );
}

# If a floor is applied there may be abandoned ballots,
# _WIGStart will remove these from the quota.

sub _format_round_result ( $rslt, $topcount, $votevalue ) {
  my $top = dclone $topcount;
  my $rawcount = $top->{'rawcount'};
  for my $t ( keys $rawcount->%* ) {
    my $folded = $rawcount->{$t} / $votevalue;
    $rawcount->{$t} = "$folded ($rawcount->{$t})";
  }
  # die Dumper $rawcount;
  my $tmpl = q|% use feature 'postderef';
% my @pending = $rslt->{'pending'}->@*;
## Round: <%= $rslt->{'round'} %>

<%= $tc->RankTable() %>
% if ( @pending ) {
### Winners:

% for my $p ( @pending ) {
*<%= $p %>*: <%= $rslt->{'winvotes'}{$p} / $votevalue %> (<%= $rslt->{'winvotes'}{$p} %>)

% }
% } else {
### No Winners

% }|;
  my $mt = Mojo::Template->new;
  return $mt->vars(1)->render( $tmpl, {rslt => $rslt, tc => $top, votevalue => $votevalue });
}

sub _WIGStart ( $I ) {
  my $seats        = $I->Seats();
  my $ballots_cast = $I->VotesCast();
  $I->TopCount();    # Set the topchoice values on the ballots.
  my $abandoned     = $I->CountAbandoned()->{'count_abandoned'};
  my $ballots_valid = $ballots_cast - $abandoned;
  my $abandonmsg =
    $abandoned
    ? "\nThere are $ballots_cast ballots. \n$abandoned ballots have no choices and will be disregarded"
    : '';
  my $quota = $I->_SetWIGQuota($ballots_valid);
  $I->logt(
    qq/Using Weighted Inclusive Gregory, Scottish Rules. $abandonmsg
    Seats to Fill: $seats
    Ballots Counted for Quota: $ballots_valid
    Quota: $quota;
  /
  );
  my $event = { ballots => $ballots_valid, quota => $quota };
  $I->STVEvent($event);
  return $event;
}

sub _WIGRound ( $I, $quota ) {
  my $round_num = $I->NextSTVRound();
  my $round     = $I->TopCount();
  my $roundcnt  = $round->RawCount();
  my @choices   = $I->GetActiveList();
  my %rndvotes  = ();
  my $leader = $round->Leader()->{'winner'};
  my $votes4leader = $round->RawCount->{$leader};
  my $pending = $votes4leader >= $quota ? $leader : '';

  for my $C (@choices ) {
    if( $roundcnt->{ $C} >= $quota ) {
      $rndvotes{ $C } = $roundcnt->{ $C } ;
    }
  }
  my @pending = sort_hash( \%rndvotes, 'numeric', 'desc' );

  my $rslt = {
    pending  => \@pending,
    winvotes => \%rndvotes,
    quota    => $quota,
    round    => $round_num,
    allvotes => $round->RawCount(),
    lowest   => $round->ArrayBottom()->[0],
    noncontinuing => $I->CountAbandoned()->{'value_abandoned'},
  };
  $I->STVEvent($rslt);
  $I->logv( _format_round_result( $rslt, $round, $I->VoteValue() ) );
  return ($rslt);
}

sub _WIGElect ( $I, $chrg ) {
  my $choice = $chrg->{'choice'};
  my $refund   = int( $chrg->{'surplus'} / $chrg->{'cntchrgd'} );
  my $refunded = 0;
  for my $b ( $chrg->{'ballotschrgd'}->@* ) {
    my $ballot = $I->BallotSet()->{'ballots'}{$b};
     if  ( $ballot->{'charged'}{$choice} < $refund )
     {
      $ballot->{'votevalue'} += $ballot->{'charged'}{$choice};
      $refunded += $ballot->{'charged'}{$choice} * $ballot->{'count'};
      $ballot->{'charged'}{$choice} = 0;
    } else
     {
    $ballot->{'votevalue'} += $refund;
    $refunded += $ballot->{'count'} * $refund;
    $ballot->{'charged'}{$choice} -= $refund;
     }
  }
  my $candvotes =
    $I->GetChoiceStatus( $choice )->{'votes'} - $refunded;
  $I->SetChoiceStatus( $choice, { votes => $candvotes } );
  $I->Elect( $choice );
}

sub _wigcomplete ( $I, $_WIGRound ) {
  my @choices = $I->GetActiveList();
  my $choiceremain = scalar @choices;
  my $numelected   = scalar( $I->{'elected'}->@* );
  my $openseats = $I->Seats() - $numelected;
  if ( $choiceremain <= $openseats ) {
    $I->logv( "Electing all Remaining Choices: @choices.\n");
    for my $C (@choices) {
      my $cvotes = $_WIGRound->{'allvotes'}{$C};
        $I->Elect($C);
        $I->SetChoiceStatus( $C, { votes => $cvotes } );
    }
  return 1;
  }
  return 0;
}

sub WIGRun ( $I ) {
  my $pre_rslt = $I->_WIGStart();
  my $quota    = $pre_rslt->{'quota'};
  my $seats    = $I->Seats();

WIGDOROUNDLOOP:
  while ( $I->Elected() < $seats ) {
    my $rnd = $I->_WIGRound($quota);
    last WIGDOROUNDLOOP if _wigcomplete ( $I, $rnd );
    my @pending = $rnd->{'pending'}->@*;
    if ( scalar(@pending)){
      for my $pending (@pending) {
        my $chrg = $I->Charge( $pending, $quota );
        $I->_WIGElect($chrg);
        }
    } else {
      $I->logv( "Eliminating low choice: $rnd->{'lowest'}\n");
      $I->Defeat($rnd->{'lowest'});
      last WIGDOROUNDLOOP if _wigcomplete ( $I, $rnd );
    }
  }
  my @elected = $I->Elected();
  $I->STVEvent( { winners => \@elected });
  $I->logt( "Winners: " . join( ', ', @elected ));
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

