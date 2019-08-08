#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
use Data::Printer;
# use Data::Dumper;

use Path::Tiny;

use Vote::Count::Method::IRV;
use Vote::Count::ReadBallots 'read_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

my $B1 = Vote::Count::Method::IRV->new(
  BallotSet => read_ballots('t/data/data2.txt'), );
my $B2 = Vote::Count::Method::IRV->new(
  BallotSet => read_ballots('t/data/biggerset1.txt'), );
my $B3 = Vote::Count::Method::IRV->new(
  BallotSet => read_ballots('t/data/irvtie.txt'), );

my $r1 = $B1->RunIRV();
my $ex1 = {
  'votes'      => 15,
  'winner'     => 'MINTCHIP',
  'winvotes'   => 8,
  'thresshold' => 8,
};
is_deeply( $r1, $ex1, 'returns set with Mintchip winning 8 of 15 votes');


  # { thresshold => 6, votes => 11, winner => 'VANILLA', winvotes => 7 },

my $r2 = $B2->RunIRV();
# note $B2->logd();
my $ex2 = {
  'votes'      => 216,
  'winner'     => 'MINTCHIP',
  'winvotes'   => 122,
  'thresshold' => 109,
};
is_deeply( $r2, $ex2, 'returns set with Mintchip winning 122 of 216 votes');
# need test of tie at the top.

my $r3 = $B3->RunIRV();
my $ex3 = {
  tie => 1, tied => [ 'CHOCOLATE','VANILLA' ], winner => 0
};
is_deeply( $r3, $ex3, 'tie at top returns correct data');

subtest 'check the logs' => sub {
  my $blv = $B1->logv();
  note "VERBOSE LOG: \n$blv";
  # crush the space out so that stupid spacing variances
  # don't break this test.
  $blv =~ tr/ \n//d;
my $logcheck1 = q/|Winner|MINTCHIP|/;
my $logcheck2 = q/Eliminating:PISTACHIO---IRVRound4/;
  for my $check ( $logcheck1, $logcheck2 ) {
    like( $blv, qr/$check/, "check verbose log for $check" );
  }
  my $tlv = $B1->logt();
  note "TERSE LOG:\n$tlv";
  my $expecttlv =q/
    Instant Runoff Voting
    Choices:
    CARAMEL, CHOCOLATE, MINTCHIP, PISTACHIO, ROCKYROAD, RUMRAISIN, STRAWBERRY, VANILLA
    ---
    | Winner                    | MINTCHIP |
    | Votes in Final Round      | 15       |
    | Votes Needed for Majority | 8        |
    | Winning Votes             | 8        |/;
# crush the spaces.
  $expecttlv =~ tr/ \n//d;
  $tlv =~ tr/ \n//d;
  like( $tlv, qr/$expecttlv/,
    "compare terse log to expected log" );
};

subtest 'tiebreakers' => sub {
  my $active = {
    PISTACHIO => 0,
    ROCKYROAD => 0,
    CHOCOLATE => 0,
    VANILLA => 0,
  };
  my $I5 = Vote::Count::Method::IRV->new(
  BallotSet => read_ballots('t/data/irvtie.txt'));
  my @resolve1 = sort $I5->_TieBreaker(
    'all', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply(
    \@resolve1,
    [ 'CHOCOLATE', 'VANILLA'],
    'All returns both tied choices' );
  my @resolve2 = sort $I5->_TieBreaker(
    'borda', $active,
    ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply(
    \@resolve2,
    [ 'CHOCOLATE'],
    'Borda returns choice that won' );
  my @resolve3 = sort
    $I5->_TieBreaker( 'borda_all', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply(
    \@resolve3,
    [ 'VANILLA'],
    'borda_all returns choice that won (different winner than borda on active!)' );
  my @resolve4 = sort
    $I5->_TieBreaker( 'approval', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply(
    \@resolve4,
    [ 'CHOCOLATE', 'VANILLA'],
    'approval returns a tie for the top2' );
  my @resolve5 = sort
    $I5->_TieBreaker( 'approval', $active, ( 'VANILLA', 'ROCKYROAD' ) );
  is_deeply(
    \@resolve5,
    [ 'VANILLA'],
    'approval winner for a non-tied pair' );
};

done_testing();