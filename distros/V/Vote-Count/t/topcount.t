#!/usr/bin/env perl

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Try::Tiny;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots;

use Data::Dumper;

my $VC1 = Vote::Count->new( BallotSet => read_ballots('t/data/data2.txt'), );

my $tc1 = $VC1->TopCount();

my $expecttc1 = {
  CARAMEL    => 0,
  CHOCOLATE  => 1,
  MINTCHIP   => 5,
  PISTACHIO  => 2,
  ROCKYROAD  => 0,
  RUMRAISIN  => 0,
  STRAWBERRY => 0,
  VANILLA    => 7
};

is_deeply( $tc1->RawCount(), $expecttc1,
  "Topcounted a small set with no active list as expected" );
is(  $VC1->BallotSet()->{ballots}{VANILLA}{topchoice}, 'VANILLA',
  'check the topchoice value for a choice');
# note( Dumper $VC1->BallotSet()->{ballots}{VANILLA});
my $tc2 = $VC1->TopCount(
  {
    'VANILLA'   => 1,
    'CHOCOLATE' => 1,
    'CARAMEL'   => 1,
    'PISTACHIO' => 1
  }
);
my $expecttc2 = {
  CARAMEL   => 1,
  CHOCOLATE => 1,
  PISTACHIO => 2,
  VANILLA   => 7
};
is_deeply( $tc2->RawCount(), $expecttc2,
  "Check rawcount to confirm Topcounted a small set with AN active list" );
is_deeply( $VC1->LastTopCountUnWeighted(), $expecttc2,
  'for non-weighted LastTopCountUnWeighted should match the TopCount');

is( $VC1->TopChoice('MINTCHIP:CARAMEL:RUMRAISIN'), 'CARAMEL',
  'check the topchoice value when topchoice isnt first choice');
is( $VC1->TopChoice('MINTCHIP'), 'NONE',
  'check the topchoice value is NONE when no choices remain active');

is_deeply(
  $VC1->TopCountMajority(),
  { threshold => 8, votes => 15 },
  'With full ballot TopCountMajority returns only votes and threshold'
);
is_deeply(
  $VC1->TopCountMajority($tc2),
  { threshold => 6, votes => 11, winner => 'VANILLA', winvotes => 7 },
'Topcount from saved subset topcount TopCountMajority also gives winner info'
);

is_deeply(
  $VC1->EvaluateTopCountMajority($tc2),
  { threshold => 6, votes => 11, winner => 'VANILLA', winvotes => 7 },
  'repeat last set with EvaluateTopCountMajority for same results'
);

my $fastfood =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json') );

my $rangeties =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/range_tietop.range.json') );

subtest 'Range Ballot' => sub {

  my $fastexpect1 = {
    BURGERKING => 0,
    CARLS      => 1,
    CHICKFILA  => 2,
    FIVEGUYS   => 0,
    INNOUT     => 8,
    KFC        => 0,
    MCDONALDS  => 1.5,
    POPEYES    => 0,
    QUICK      => 0,
    TACOBELL   => 1,
    WENDYS     => 1.5,
    WIMPY      => 0,
  };

  my $fastexpect2 = {
    BURGERKING => 0,
    CHICKFILA  => 3,
    FIVEGUYS   => 0,
    INNOUT     => 8,
    MCDONALDS  => 1.5,
    WENDYS     => 1.5,
  };

  my $fastexpect3 = {
    BURGERKING => 2,
    FIVEGUYS   => 6,
    TACOBELL   => 1,
    WENDYS     => 3,
  };

  my $rtexpect1 = {
    "DEE"    => 10,
    "DUM"    => 10,
    "DUMPTY" => 1,
    "THREE"  => 10
  };

  my $rtexpect2 = {
    "DEE"    => 10,
    "DUM"    => 10,
    "DUMPTY" => 11,
  };

  my $countedff1 = try { $fastfood->TopCount() };
  is_deeply( try { $countedff1->RawCount() },
    $fastexpect1, "Topcounted a set with no specified active list" );

  my $countedff2 = try { $fastfood->TopCount($fastexpect2) };
  is_deeply( try { $countedff2->RawCount() },
    $fastexpect2, "Topcounted a set with a specified active list" );
  is_deeply(
    $fastfood->TopCountMajority( $countedff2, $fastexpect2 ),
    {
      'threshold' => 8,
      'votes'     => 14,
      'winner'    => 'INNOUT',
      'winvotes'  => 8
    },
    'Check topcount majority for previous'
  );

  my $countedff3 = try { $fastfood->TopCount($fastexpect3) };
  is_deeply( try { $countedff3->RawCount() },
    $fastexpect3, "Topcounted same set with different active list" );

  my $countedrt1 = try { $rangeties->TopCount() };
  is_deeply( try { $countedrt1->RawCount() },
    $rtexpect1, "Topcounted a set with ties" );

  my $countedrt2 = try { $rangeties->TopCount($rtexpect2) };
  is_deeply( try { $countedrt2->RawCount() },
    $rtexpect2, "last set with 1 less choice" );

  is_deeply(
    $rangeties->TopCountMajority( $countedrt2, $rtexpect2 ),
    { 'threshold' => 16, 'votes' => 31 },
    'Check topcount majority for previous'
  );

};

subtest 'weighted topcount' => sub {
  my $B1 =  read_ballots('t/data/data2.txt');
  my %bweight = (
    'MINTCHIP:CARAMEL:RUMRAISIN' => 11,
    'CHOCOLATE:MINTCHIP:VANILLA' => 6,
    'VANILLA:CHOCOLATE:STRAWBERRY' => 4,
    'MINTCHIP' => 2,
    'VANILLA' => 1,
    'PISTACHIO:ROCKYROAD:MINTCHIP:VANILLA:CHOCOLATE' => 3,
  );
  for my $b1 ( keys %bweight ) { $B1->{'ballots'}{$b1}{'votevalue'} = $bweight{$b1} }
  my $W1 = Vote::Count->new( BallotSet => $B1 );
  my $W1Expect = {
          'VANILLA' => 22,
          'MINTCHIP' => 19,
          'STRAWBERRY' => 0,
          'PISTACHIO' => 6,
          'RUMRAISIN' => 0,
          'ROCKYROAD' => 0,
          'CHOCOLATE' => 6,
          'CARAMEL' => 0,
  };
  my $W1Result = $W1->TopCount();
  is_deeply(
    $W1Result->RawCount(), $W1Expect, 'Assigned Integer weights to data2' );
  is(
    $W1Result->Leader()->{'winner'},
    'VANILLA',
    'picked winner with int weights.');
  is( $W1->TopCountMajority()->{'winner'}, undef, 'does not have majority winner');
  is_deeply( $W1->TopCountMajority(), { 'votes' => 53, 'threshold' => 27 },
    'check votes and threshold from TopCountMajority');
  my $W1ExpectLastTopCountUnWeighted = {
          'VANILLA' => 7,
          'MINTCHIP' => 5,
          'STRAWBERRY' => 0,
          'PISTACHIO' => 2,
          'RUMRAISIN' => 0,
          'ROCKYROAD' => 0,
          'CHOCOLATE' => 1,
          'CARAMEL' => 0,
  };
  is_deeply(
    $W1->LastTopCountUnWeighted(),
    $W1ExpectLastTopCountUnWeighted,
    'LastTopCountUnWeighted returns the number of ballots voting equivalent to unweighted'
  );
  # Do it again with Floats.
  %bweight = (
    'MINTCHIP:CARAMEL:RUMRAISIN' => .5,
    'CHOCOLATE:MINTCHIP:VANILLA' => 1.6,
    'VANILLA:CHOCOLATE:STRAWBERRY' => 4,
    'MINTCHIP' => 2.2,
    'VANILLA' => 1,
    'PISTACHIO:ROCKYROAD:MINTCHIP:VANILLA:CHOCOLATE' => 3.1,
  );
  for my $b1 ( keys %bweight ) { $B1->{'ballots'}{$b1}{'votevalue'} = $bweight{$b1} }
  my $W2 = Vote::Count->new( BallotSet => $B1 );
  my $W2Active =  {
          'MINTCHIP' => 1,
          'STRAWBERRY' => 1,
          'RUMRAISIN' => 1,
          'ROCKYROAD' => 1,
          'CHOCOLATE' => 1,
          'CARAMEL' => 1,
  };
  my $W2Expect = {
          'MINTCHIP' => 9.3,
          'STRAWBERRY' => 0,
          'RUMRAISIN' => 0,
          'ROCKYROAD' => 6.2,
          'CHOCOLATE' => 21.6,
          'CARAMEL' => 0,
  };
  my $W2Result = $W2->TopCount( $W2Active );
  is_deeply( $W2Result->RawCount(), $W2Expect,
    'Assigned Floating Point weights to data2 with arbitrary active set' );
  is( $W2Result->Leader()->{'winner'},
    'CHOCOLATE', 'picked winner with float weights and choices inactive');
  is( $W2->TopCountMajority( $W2Result )->{'winner'},
    'CHOCOLATE', 'has majority winner');
  is( $W2->TopCountMajority( $W2Result )->{'votes'}, 37.1,
     'fractional number of votes reported by TopCountMajority');
};

subtest 'odd situations' => sub {
  $VC1->SetActive({});
  is_deeply( $VC1->TopCount(),
  { 'error' => 'no active choices'},
  'No active set returns a hashref containing an error instead of a rankcount.');
  isa_ok( $VC1->topcount( { 'CARAMEL' => 1 }),
  ['Vote::Count::RankCount'],
  'while object active is empty, alternate active still gets a rankcount, used lowercase alias');
};

done_testing();
