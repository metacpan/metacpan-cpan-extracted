#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;
use feature qw /postderef signatures/;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Vote::Count::Borda;

my $RangeElection =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/tennessee.range.json') );
my $rangescored = $RangeElection->Score();

subtest 'Score Range Ballots' => sub {
  note "Testing Range Ballot Scoring with Tennessee.";
  is( $rangescored->{'ordered'}{'MEMPHIS'},
    4, 'Memphis scores 4th in ordered' );
  is( $rangescored->{'rawcount'}{'CHATTANOOGA'},
    289, 'CHATTANOOGA scored 289' );
  is( $rangescored->ArrayTop()->[0],
    'NASHVILLE', 'ArrayTop returns Nashville' );
  is( scalar $rangescored->ArrayTop()->@*, 1, 'ArrayTop has only 1 element' );
  is( $rangescored->ArrayBottom()->[0],
    'MEMPHIS', 'Memphis is in the bottom array' );
  is( scalar $rangescored->ArrayBottom()->@*,
    1, 'ArrayBottom has only 1 element' );
  my $ranked = $rangescored->HashByRank();
  is( $ranked->{2}[0], "KNOXVILLE",
    'From hashbyrank see that Knoxville is 2nd' );
};

subtest 'RangeBallotPair' => sub {
  my $VC1 =
    Vote::Count->new(
    BallotSet => read_range_ballots('t/data/fastfood.range.json') );
  subtest 'RangeBallotPair' => sub {
    is( $VC1->BallotSetType(),
      'range', 'BallotSetType option is set to range' );
    my ( $votesKFC, $votesTACOBELL ) =
      $VC1->RangeBallotPair( 'KFC', 'TACOBELL' );
    is( $votesKFC,      0, 'check one of the choices' );
    is( $votesTACOBELL, 1, 'check the other one' );
    my ( $votesINNOUT, $votesMcD ) =
      $VC1->RangeBallotPair( 'INNOUT', 'MCDONALDS' );
    is( $votesINNOUT, 10, 'check one of the choices' );
    is( $votesMcD,    3,  'check the other one' );
  };
};

done_testing();
