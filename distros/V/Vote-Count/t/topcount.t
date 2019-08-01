#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
# use Data::Printer;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';

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
  { thresshold => 8, votes => 15 },
  'With full ballot TopCountMajority returns only votes and thresshold'
);
is_deeply(
  $VC1->TopCountMajority($tc2),
  { thresshold => 6, votes => 11, winner => 'VANILLA', winvotes => 7 },
'Topcount from saved subset topcount TopCountMajority also gives winner info'
);

is_deeply(
  $VC1->EvaluateTopCountMajority($tc2),
  { thresshold => 6, votes => 11, winner => 'VANILLA', winvotes => 7 },
'repeat last set with EvaluateTopCountMajority for same results'
);

done_testing();
