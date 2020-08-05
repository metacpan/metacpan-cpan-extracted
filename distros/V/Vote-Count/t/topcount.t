#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Try::Tiny;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots;

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
    $fastexpect1, "Topcounted a set with no active list" );

  my $countedff2 = try { $fastfood->TopCount($fastexpect2) };
  is_deeply( try { $countedff2->RawCount() },
    $fastexpect2, "Topcounted a set with an active list" );
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

done_testing();
