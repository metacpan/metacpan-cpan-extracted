#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
use Test2::Tools::Exception qw/dies lives/;
use Data::Printer;

use Path::Tiny;
use File::Temp;

use Vote::Count;
use Vote::Count::ReadBallots 'read_range_ballots';

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

done_testing;
