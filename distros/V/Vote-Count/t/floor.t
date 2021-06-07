#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots;

use Data::Dumper;

use feature qw /postderef signatures/;
no warnings 'experimental';

# my $B2 =
#   Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );

subtest '_FloorMin and FloorRounding' => sub {
  my $E = Vote::Count->new(
    BallotSet     => read_ballots('t/data/biggerset1.txt'),
    FloorRounding => 'down'
  );
  note( 'VotesCast is: ' . $E->VotesCast() );
  is( $E->_FloorMin(10),   22, 'test _FloorMin with rounding down' );
  is( $E->_FloorRnd(11),   11, '_FloorRnd rounding down 11 is 11' );
  is( $E->_FloorRnd(11.1), 11, '_FloorRnd rounding up 11.1 is 11' );
  $E->FloorRounding('up');
  is( $E->_FloorMin(10),    23, 'test _FloorMin with rounding up' );
  is( $E->_FloorRnd(11),    11, '_FloorRnd rounding up 11 is 11' );
  is( $E->_FloorRnd(11.00), 11, '_FloorRnd rounding up 11.00 is 11' );
  is( $E->_FloorRnd(11.1),  12, '_FloorRnd rounding up 11.1 is 12' );
  $E->FloorRounding('round');
  is( $E->FloorRounding(), 'round',
    'just checking rounding method set to round' );
  is( $E->_FloorMin(10),   23, 'test _FloorMin with real rounding' );
  is( $E->_FloorRnd(11),   11, '_FloorRnd rounding 11 to 11' );
  is( $E->_FloorRnd(11.1), 11, '_FloorRnd rounding 11.1 to 11' );
  is( $E->_FloorRnd(11.7), 12, '_FloorRnd rounding 11.7 is 12' );

  $E->FloorRounding('nextint');
  is( $E->_FloorRnd(11),   12, '_FloorRnd nextint 11 = 12' );
  is( $E->_FloorRnd(11.1), 12, '_FloorRnd nextint 11.1 = 12' );
  is( $E->_FloorRnd(11.7), 12, '_FloorRnd nextint 11.7 = 12' );

  $E->FloorRounding('fake method');
  dies_ok( sub { $E->_FloorRnd(11.1) },
    'dies because a fake rounding method was requested' );
};

subtest 'Approval and TopCount Floors' => sub {
  my $B1 =
    Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );
  my $B2 =
    Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );
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
};

subtest 'TCA' => sub {
  my $B3 =
    Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt') );
  my $floor3 = $B3->TCA();
  my @f3     = sort( keys $floor3->%* );
  is_deeply(
    \@f3,
    [qw/CHOCOLATE MINTCHIP STRAWBERRY VANILLA/],
    'TCA Approval on highest TopCount (default 1/2)'
  );

  my $TCAOne =
    Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );
  $floor3 = $TCAOne->TCA(1);
  @f3     = sort( keys $floor3->%* );
  is_deeply(
    \@f3,
    [qw/CHOCOLATE MINTCHIP VANILLA/],
    'TCA Approval on highest TopCount EQUAL TopCount Leader'
  );

  dies_ok( sub { my $f = $TCAOne->TCA(1.11) },
    'Dies with a TCA greater than 1' );
};

subtest 'Applying floors to Range ballots' => sub {
  my $Range1 =
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
    FIVEGUYS   => 1,
    INNOUT     => 1,
    MCDONALDS  => 1,
    QUICK      => 1,
    WENDYS     => 1
  };

  is_deeply( $Range1->ApprovalFloor( 15, 2 ),
    $e2, 'same range ballot with a cutoff leaves fewer choices' );

  $e2->{CHICKFILA} = 1;
  $Range1->FloorRounding('down');
  is_deeply( $Range1->ApprovalFloor( 15, 2 ),
    $e2, 'Changing Rounding from default *up* to *down* adds a choice' );
};

subtest 'ApplyFloor' => sub {
  my $A4 =
    Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt') );
  my $floor4 = $A4->ApplyFloor( 'TCA', .25 );
  is_deeply( $floor4, $A4->Active(),
    'ApplyFloor should have set the active list it returned');
  my @f4     = sort( keys $floor4->%* );
  is_deeply(
    \@f4,
    [qw/CARAMEL CHOCOLATE MINTCHIP RUMRAISIN STRAWBERRY VANILLA/],
    'TCA Approval on highest TopCount (.25)'
  );
  is_deeply(
    [ sort keys $A4->ApplyFloor( 'TopCountFloor' )->%* ],
    [qw/CHOCOLATE MINTCHIP VANILLA/],
    'Apply a TopCount Floor '
    );
  is_deeply(
    [ sort keys $A4->ApplyFloor( 'ApprovalFloor' )->%* ],
    [qw/CHOCOLATE MINTCHIP VANILLA/],
    'Apply Approval Floor '
    );
  dies_ok( sub { $A4->ApplyFloor( 'Approval' ) },
    'invalid methodname as rule dies');
  };

done_testing();
