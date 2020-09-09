#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
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
  is( scalar( $tietop->_best_two( $tietop->Score() ) ),
    3, 'example with 3 way  returned 3 element array' );
};

subtest 'STAR' => sub {
  is( $tennessee->STAR()->{'winner'}, 'NASHVILLE', 'STAR chose NASHVILLE for Tennessee' );
  is( $fastfood->STAR()->{'winner'},  'INNOUT',    'STAR chose InNOut for fastfood' );
  is( $tietop->STAR( $tietop->Active() )->{'tie'} ,
    1, 'STAR returned true for tie when there was a tie' );
  is( $tietop->STAR( $tietop->Active() )->{'winner'} ,
    0, 'STAR returned false for winner when there was a tie' );
  $fastfood->SetActive( 
    { 'CARLS' => 1, 'KFC' => 1, 'WIMPY' => 1 });
  my $result1 = $fastfood->STAR();
  is( $result1->{'winner'},
    'CARLS', 'Changed ActiveSet for fastfood, confirmed winner' );
  my $result2 = $fastfood->STAR( 
    { 'QUICK' => 1, 'KFC' => 1, 'WENDYS' => 1 } );
  is( $result2->{'winner'},
    'WENDYS', 'passed another ActiveSet as argument' );
  is( $result2->{'tie'}, 0, 'confirm that tie was false');
};

subtest 'Coverage Fix' => sub {
my $fixset = Vote::Count::Method::STAR->new(
  BallotSet => {
    'ballots' => [
        {   'votes' => {
                'A' => 4,
                'B' => 5,
            },
            'count' => 6
        },
        {   'count' => 2,
            'votes' => {
                'A' => 5,
                'C' => 4,
            }
        },
    ],
    'choices' => {
        'A' => 1,
        'B' => 1,
        'C' => 1,
    },
    'depth'   => 5,
    'options' => {
        'rcv'   => 0,
        'range' => 1
    },
    'votescast' => 8
} );

  # note( Dumper $fixset->BallotSet() );
  is( $fixset->STAR()->{'winner'}, 'B', "B wins" );
  $fixset->{'BallotSet'}{'ballots'} = [
        {   'votes' => {
                'A' => 4,
                'B' => 5,
            },
            'count' => 4
        },
        {   'count' => 4,
            'votes' => {
                'A' => 5,
                'C' => 2,
            }
        },
    ];
    
  is( $fixset->STAR()->{'winner'}, 0, "A Tie" );
};


done_testing();
