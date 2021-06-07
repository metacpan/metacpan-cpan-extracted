#!/usr/bin/env perl

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
# use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;
no warnings 'experimental';
# use Path::Tiny;
use Try::Tiny;
use Vote::Count::Charge;
# use Vote::Count::Helper::FullCascadeCharge;
# use Vote::Count::Helper::NthApproval;
use Vote::Count::Helper::Table 'WeightedTable' ;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Warnings qw/warns warning warnings no_warnings/;

use Data::Dumper;

subtest 'CountAbandoned, TCStats' => sub {
  my $A = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/data1.txt'),
  );
  my $tcs = $A->TCStats;
  ok( $tcs->{abandoned}{message},
    'there is a message in the abandoned key');
  is( $tcs->{'active_vote_value'}, 1000,
    'active vote value is reported by TCStats');
  my $abandoned = $A->CountAbandoned;
  is($abandoned->{count_abandoned}, 0, 'no abandoned ballots at beginning' );
  is($abandoned->{value_abandoned}, 0, 'so their vote value is 0' );
  $A->Defeat('VANILLA');
  $tcs = $A->TCStats;
  is( $tcs->{abandoned}{count_abandoned}, 2,
    'after elimination 2 votes abandoned');
  is( $tcs->{abandoned}{value_abandoned}, 200,
    'after elimination 200 vote value abandoned');
  is( $tcs->{'active_vote_value'}, 800, 'active vote value adjusted');
};

subtest 'WithdrawalList' => sub {
    my $A = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/biggerset1.txt'),
    FloorRule => 'Approval',
    FloorThresshold => 2,
    WithdrawalList => 't/data/biggerset1withdrawn.txt',
  );
  is( $A->{'choice_status'}{'POISON_APPLE'}, undef,
    'Withdrawn choice not present in ballots doesnt get added by bug');
  is_deeply( [$A->Withdrawn], [ qw( CARAMEL ROCKYROAD RUMRAISIN )]);
};

subtest 'SetQuota' => sub {
  my $A = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/biggerset1.txt'),
  );
  my $B = Vote::Count::Charge->new(
    Seats     => 3,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/biggerset1.txt'),
  );
  is( $A->SetQuota, 3751, 'calculate quota with default (droop)');
  is( $B->SetQuota('droop'), 5626, 'calculate quota requesting droop');
  is( $A->SetQuota('hare'), 4500, 'calc quota with hare');
  is( $B->SetQuota('hare'), 7500, 'calc hare with different number of seats');
};

subtest 'STVFloor' => sub {
  my $A = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/biggerset1.txt'),
    FloorRule => 'Approval',
    FloorThresshold => 2,
  );

  is_deeply(
    [$A->STVFloor()],
    [qw/CHOCOANTS SOGGYCHIPS TOAD VOMIT/],
    'floor approval 2% eliminated 4 choices'
  );

  is_deeply(
    $A->GetActive,
    { 'CHOCOLATE' => 1, 'MINTCHIP' => 1, 'RUMRAISIN' => 1, 'VANILLA' => 1, 'CARAMEL' => 1, 'STRAWBERRY' => 1, 'ROCKYROAD' => 1, 'PISTACHIO' => 1 },
    'apply approval floor, check remaining ative set'
  );
  is( $A->GetChoiceStatus( 'TOAD')->{'state'},
    'withdrawn',
    'eliminated choice has a status of withdrawn'
  );

my $B = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/biggerset1.txt'),
    FloorRule => 'TopCount',
    FloorThresshold => 1,
  );
  is( scalar $B->STVFloor('Defeat'),
    5,
    'Top count with thresshold 1 eliminated 5'
  );
  is( $B->GetChoiceStatus( 'TOAD')->{'state'},
    'hopeful',
    'choice right at cutoff wasnt eliminated'
  );
  is( $B->GetChoiceStatus( 'SOGGYCHIPS')->{'state'},
    'defeated',
    'eliminated choice is defeated because it was requested instead of default withdrawn'
  );
};

done_testing;
