#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
# use Test2::Tools::Exception qw/dies lives/;

# Tests written to improve Devel::Cover stats.

use Data::Dumper;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots;

my $RCV1 = Vote::Count->new( BallotSet => read_ballots('t/data/data1.txt'), );
my $Range1 =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json') );

is( $RCV1->BallotSetType(),
  'rcv', 'confirm ballotset type for an rcv ballotset.' );

my $invalid =
  Vote::Count->new( BallotSet => read_ballots('t/data/data1.txt'), );
$invalid->{'BallotSet'}{'options'} = { 'ordrange' => 1 };
dies_ok( sub { $invalid->BallotSetType(); },
  "unkown ballot type dies on call of BallotSetType" );

$Range1->SetActiveFromArrayRef( [ "FIVEGUYS", "MCDONALDS", "WIMPY" ] );
is_deeply( $Range1->Active(),
  { 'WIMPY' => 1, 'MCDONALDS' => 1, 'FIVEGUYS' => 1 },
  'SetActiveFromArrayRef' );

done_testing();
