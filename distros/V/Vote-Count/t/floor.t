#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots;

use feature qw /postderef signatures/;
no warnings 'experimental';

my $B1 =
  Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );
my $B2 =
  Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );
my $B3 =
  Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );

is( $B3->_FloorMin(10), 22, 'test _FloorMin' );

my $floor1 = $B1->ApprovalFloor();
my @f1     = sort( keys $floor1->%* );
is_deeply(
  \@f1,
  [
    qw/CARAMEL CHOCOLATE MINTCHIP PISTACHIO ROCKYROAD RUMRAISIN
      STRAWBERRY VANILLA/
  ],
  'Approval Floor (defaulted to 5%) of set'
);

my $floor2 = $B2->TopCountFloor(4);
my @f2     = sort( keys $floor2->%* );
is_deeply(
  \@f2,
  [qw/CHOCOLATE MINTCHIP PISTACHIO  VANILLA/],
  'TopCount Floor at 4% of set'
);

my $floor3 = $B3->TCA();
my @f3     = sort( keys $floor3->%* );
is_deeply(
  \@f3,
  [qw/CHOCOLATE MINTCHIP STRAWBERRY VANILLA/],
  'TCA Approval on highest TopCount '
);

my $B4 = Vote::Count->new(
  'BallotSet' => read_ballots('t/data/data2.txt'),
  'Floor'     => 'approval',
  'FloorPct'  => 20,
);
my $B4Approval = do {
  my $total = 0;
  for ( values $B4->Approval()->RawCount()->%* ) {
    $total += $_;
  }
  $total;
};

my $Range1 =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json') );

my $Range2 =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json') );

my $e1 = {
  BURGERKING => 1,
  CARLS      => 1,
  CHICKFILA  => 1,
  FIVEGUYS   => 1,
  INNOUT     => 1,
  KFC        => 1,
  MCDONALDS  => 1,
  POPEYES    => 1,
  QUICK      => 1,
  TACOBELL   => 1,
  WENDYS     => 1
};

is_deeply( $Range1->ApprovalFloor(.15),
  $e1, 'check a range ballot with approval floor' );

my $e2 = {
  BURGERKING => 1,
  CHICKFILA  => 1,
  FIVEGUYS   => 1,
  INNOUT     => 1,
  MCDONALDS  => 1,
  QUICK      => 1,
  WENDYS     => 1
};
is_deeply( $Range2->ApprovalFloor( 15, 2 ),
  $e2, 'same range ballot with a cutoff leaves fewer choices' );

done_testing();
