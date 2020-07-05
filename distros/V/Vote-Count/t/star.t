#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;
use Data::Dumper;
use feature qw /postderef signatures/;
use Path::Tiny;

# use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Vote::Count::Method::STAR;

my $tennessee =
  Vote::Count::Method::STAR->new(
  BallotSet => read_range_ballots('t/data/tennessee.range.json'), );
my $fastfood =
  Vote::Count::Method::STAR->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json'), );

my $tietop =
  Vote::Count::Method::STAR->new(
  BallotSet => read_range_ballots('t/data/range_tietop.range.json'), );

subtest '_best_two find top two for Automatic Runoff' => sub {
  is_deeply(
    [ $fastfood->_best_two( $fastfood->Score() ) ],
    [ 'INNOUT', 'BURGERKING' ],
    'example without tie returned expected choices'
  );
  is_deeply( [ $tietop->_best_two( $tietop->Score() ) ],
    [], 'example with 3 way tie returned empty array' );
};

subtest 'STAR' => sub {
  is( $tennessee->STAR(), 'NASHVILLE', 'STAR chose NASHVILLE for Tennessee' );
  is( $fastfood->STAR(),  'INNOUT',    'STAR chose InNOut for fastfood' );
  is( $tietop->STAR( $tietop->Active() ),
    0, 'STAR returned 0 when there was a tie' );
  is( $fastfood->STAR( { 'CARLS' => 1, 'KFC' => 1, 'WIMPY' => 1 } ),
    'CARLS', 'Changed ActiveSet for fastfood' );
  is( $fastfood->STAR( { 'QUICK' => 1, 'KFC' => 1, 'WENDYS' => 1 } ),
    'WENDYS', 'another ActiveSet for fastfood' );
};

done_testing();
