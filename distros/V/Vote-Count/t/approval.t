#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';

my $VC1 = Vote::Count->new( BallotSet => read_ballots('t/data/data2.txt'), );

my $A1       = $VC1->Approval();
my $expectA1 = {
  CARAMEL    => 1,
  CHOCOLATE  => 8,
  MINTCHIP   => 8,
  PISTACHIO  => 2,
  ROCKYROAD  => 2,
  RUMRAISIN  => 1,
  STRAWBERRY => 5,
  VANILLA    => 10
};

is_deeply( $A1->RawCount(), $expectA1,
  "Approval counted for a small set with no active list" );

my $A2 = $VC1->Approval(
  {
    'VANILLA'   => 1,
    'CHOCOLATE' => 1,
    'CARAMEL'   => 1,
    'PISTACHIO' => 0
  }
);
my $expectA2 = {
  CARAMEL   => 1,
  CHOCOLATE => 8,
  PISTACHIO => 2,
  VANILLA   => 10
};

is_deeply( $A2->RawCount(), $expectA2,
  "Approval counted a small set with AN active list" );

my $Range1 =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/tennessee.range.json') );
my $R1A       = $Range1->Approval();
my $expectR1A = {
  CHATTANOOGA => 100,
  KNOXVILLE   => 100,
  MEMPHIS     => 100,
  NASHVILLE   => 100
};
is_deeply( $R1A->RawCount(), $expectR1A,
  'counted approval for a range ballotset' );

my $R1B =
  $Range1->Approval( { KNOXVILLE => 1, MEMPHIS => 1, NASHVILLE => 1 }, 3 );
my $expectR1B = {
  KNOXVILLE => 58,
  MEMPHIS   => 42,
  NASHVILLE => 100
};
is_deeply( $R1B->RawCount(), $expectR1B,
  'appplied activeset and cutoff to same range ballotset' );

my $Range2 =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json') );
my $R2A       = $Range2->Approval();
my $expectR2A = {
  "FIVEGUYS"   => 6,
  "MCDONALDS"  => 5,
  "WIMPY"      => 0,
  "WENDYS"     => 3,
  "QUICK"      => 3,
  "BURGERKING" => 11,
  "INNOUT"     => 10,
  "CARLS"      => 7,
  "KFC"        => 4,
  "TACOBELL"   => 4,
  "CHICKFILA"  => 6,
  "POPEYES"    => 4,
};
is_deeply( $R2A->RawCount(), $expectR2A,
  'counted approval for a second range ballotset' );

my $R2B = $Range2->Approval( undef, 2 );
my $expectR2B = {
  "FIVEGUYS"   => 6,
  "MCDONALDS"  => 3,
  "WIMPY"      => 0,
  "WENDYS"     => 3,
  "QUICK"      => 3,
  "BURGERKING" => 3,
  "INNOUT"     => 10,
  "CARLS"      => 1,
  "KFC"        => 1,
  "TACOBELL"   => 1,
  "CHICKFILA"  => 2,
  "POPEYES"    => 0,
};
is_deeply( $R2B->RawCount(), $expectR2B,
  'counted approval with a cutoff for second range ballotset' );

done_testing();
