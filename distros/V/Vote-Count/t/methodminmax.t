#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Dumper;
# use JSON::MaybeXS;
# use YAML::XS;
no warnings 'experimental';
use feature qw /postderef signatures/;

use Path::Tiny;

use Vote::Count::Method::CondorcetDropping;
use Vote::Count::Method::MinMax;
use Vote::Count::ReadBallots 'read_ballots';

my $tennessee = Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/tennessee.txt') );
my $loop1 =  Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/loop1.txt') );

# useful for debugging 
sub note_scores ( $minmaxobj, $method ) {
  my $score = $minmaxobj->ScoreMinMax($method );
  note( $minmaxobj->_pairmatrixtable2( $score));
}

subtest 'ScoreMinMax winning' => sub {

  # note( Dumper $loop1->ScoreMinMax( 'winning' ) );
  my $A = $tennessee->ScoreMinMax( 'winning' );
  my $L = $loop1->ScoreMinMax( 'winning' );
  is_deeply( $A->{'NASHVILLE'}{'score'}, [ 0, 0, 0 ], 
  'TN Nashville didnt lose @score is [ 0, 0, 0 ]');
  is_deeply( $A->{'KNOXVILLE'}{'score'}, [ 83, 68, 0 ], 
  'TN Knoxville  @score is [ 83, 68, 0 ]');
  for my $othertn ( qw/NASHVILLE KNOXVILLE CHATTANOOGA/) {
    is( $A->{'MEMPHIS'}{$othertn}, 58,
    "TN all other choices scored 58 vs Memphis, check $othertn");
  }
  my $xmintchip = {
    'ROCKYROAD'=> 0,
    'score' => [ 9, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'CHOCOLATE'=> 9,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 0,
    'PISTACHIO'=> 0
    };
  my $xchocolate = {
    'ROCKYROAD'=> 0,
    'score' => [ 9, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'MINTCHIP'=> 0,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 9,
    'PISTACHIO'=> 0
    };
  is_deeply( $L->{'MINTCHIP'}, $xmintchip, 
    'loop1 Mintchip 1 loss at 9.');
  is_deeply( $L->{'CHOCOLATE'}, $xchocolate, 
    'loop1 Chocolate also 1 loss at 9.');  
}; # 'ScoreMinMax winning'

subtest 'ScoreMinMax margin' => sub {

  my $A = $tennessee->ScoreMinMax( 'margin' );
  # note( Dumper $A );
  my $L = $loop1->ScoreMinMax( 'margin' );
  is_deeply( $A->{'NASHVILLE'}{'score'}, [ 0, 0, 0 ], 
  'TN Nashville didnt lose @score is [ 0, 0, 0 ]');
  is_deeply( $A->{'KNOXVILLE'}{'score'}, [ 66, 36, 0 ], 
  'TN Knoxville  @score is [  66, 36, 0 ]');
  for my $othertn ( qw/NASHVILLE KNOXVILLE CHATTANOOGA/) {
    is( $A->{'MEMPHIS'}{$othertn}, 16,
    "TN all other choices scored 16 vs Memphis, check $othertn");
  }
  my $xmintchip = {
    'ROCKYROAD'=> 0,
    'score' => [ 2, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'CHOCOLATE'=> 2,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 0,
    'PISTACHIO'=> 0
    };
  my $xchocolate = {
    'ROCKYROAD'=> 0,
    'score' => [ 5, 0, 0, 0, 0, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 0,
    'MINTCHIP'=> 0,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 5,
    'PISTACHIO'=> 0
    };
  is_deeply( $L->{'MINTCHIP'}, $xmintchip, 
    'loop1 Mintchip 1 loss at 2.');
  is_deeply( $L->{'CHOCOLATE'}, $xchocolate, 
    'loop1 this time Chocolate 1 loss at 5.');  
}; # 'ScoreMinMax margin'


subtest 'ScoreMinMax opposition' => sub {

  my $A = $tennessee->ScoreMinMax( 'opposition' );
  # note( Dumper $A );
  my $L = $loop1->ScoreMinMax( 'opposition' );
  is_deeply( $A->{'NASHVILLE'}{'score'}, [ 42, 32, 32 ], 
  'TN Nashville scores [ 42, 32, 32 ]');
  is_deeply( $A->{'KNOXVILLE'}{'score'}, [ 83, 68, 42 ], 
  'TN Knoxville  @score is [  83, 68, 42 ]');
  for my $othertn ( qw/NASHVILLE KNOXVILLE CHATTANOOGA/) {
    is( $A->{'MEMPHIS'}{$othertn}, 58,
    "TN all other choices scored 58 vs Memphis, check $othertn");
  }
  my $xmintchip = {
    'ROCKYROAD'=> 2,
    'score' => [ 9, 7, 5, 2, 2, 0, 0 ],
    'CARAMEL'=> 0,
    'STRAWBERRY' => 5,
    'CHOCOLATE'=> 9,
    'RUMRAISIN'=> 0,
    'VANILLA'=> 7,
    'PISTACHIO'=> 2
    };
  my $xchocolate = {
    'ROCKYROAD'=> 2,
    'score' => [ 9, 7, 2, 2, 1, 1, 0 ],
    'CARAMEL'=> 1,
    'STRAWBERRY' => 0,
    'MINTCHIP'=> 7,
    'RUMRAISIN'=> 1,
    'VANILLA'=> 9,
    'PISTACHIO'=> 2
    };
  is_deeply( $L->{'MINTCHIP'}, $xmintchip, 
    'loop1 Mintchip worst is 9 best is 0.');
  is_deeply( $L->{'CHOCOLATE'}, $xchocolate, 
    'loop1 this time Chocolate worst is also 9 best is 0.');
  is_deeply( $L->{'STRAWBERRY'}{'score'}, [ 13, 11, 11, 2, 2, 1, 1 ],
    "Stawberry score should be [ 13, 11, 11, 2, 2, 1, 1 ], but once there was a bug where it wasnt.");
}; # 'ScoreMinMax opposition'

subtest 'MinMaxPairingVotesTable' => sub {
  my $A = $tennessee->ScoreMinMax( 'opposition' );
  my $output = $tennessee->MinMaxPairingVotesTable( $A );
  # note( $output );
  $output =~ m/(.*)\n/;
  my $head = $1;
  note( $head);
  like( $head, 
        qr/| Score |/, 
        "Score is in first (heading) row of table");
  $output =~ m/(KNOXVILLE.*CHATTANOOGA.*)\n/;
  my $knoxvchtga = $1;
  my $kcmatches = () = $knoxvchtga =~ m/83 /g;
  note( $knoxvchtga);
  is( $kcmatches, 2, 
    'Two matches for 83 in knoxville loses to chattanooga' );
};

subtest 'minmax method tennessee' => sub {
  my $tnwins = $tennessee->MinMax( 'winning');
  # note( $tennessee->logv() );
  is( $tnwins->{'winner'}, 'NASHVILLE', 
    'Check tennessee with \'winning\' that Nashville is winner');
  my $tnmargin = $tennessee->MinMax( 'margin');
  # note( $tennessee->logv() );
  is( $tnmargin->{'winner'}, 'NASHVILLE', 
    'Check tennessee with \'margin\' that Nashville is winner');
  my $tnopposition = $tennessee->MinMax( 'opposition');
  # note( $tennessee->logv() );
  is( $tnopposition->{'winner'}, 'NASHVILLE', 
    'Check tennessee with \'opposition\' that Nashville is winner');
};

subtest '"Loop 1 dataset, winning score"' => sub {
  my $loop11 =  Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/loop1.txt') );
  # note_scores( $loop11, 'winning');
  is_deeply(
    $loop11->MinMax('winning'),
      { 'tie' => 1, 
        'tied' => [ 'CHOCOLATE', 'MINTCHIP'], 
        'winner' => 0 },
    "Tie with this method."
    );
  like( $loop11->logv, 
    qr/Tiebreaker Round 1/,
    'This set goes 1 tiebreaker round');
  unlike( $loop11->logv, 
    qr/Tiebreaker Round 2/,
    'This set *only* goes 1 tiebreaker round, no 2nd round');
};

subtest "Loop 1 dataset, margin score" => sub {
  my $loop11 =  Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/loop1.txt') );
  # note_scores( $loop11, 'margin');
  is_deeply(
    $loop11->MinMax('margin'),
      { 'tie' => 0, 'winner' => 'MINTCHIP' },
    "Immediate Winner with this method."
    );
  unlike( $loop11->logv, 
    qr/Tiebreaker Round/,
    'No tiebreaker round');
  like( $loop11->logv, 
    qr/Winner is MINTCHIP/,
    'log reports Winner');
};

subtest "Loop 1 dataset, opposition score" => sub {
  my $loop11 =  Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/loop1.txt') );
  # note_scores( $loop11, 'opposition');
  is_deeply(
    $loop11->MinMax('opposition'),
      { 'tie' => 0, 'winner' => 'CHOCOLATE' },
    "Winner with this method (2 rounds tiebreaker)."
    );
  like( $loop11->logv, 
    qr/Tiebreaker Round 2/,
    'This set goes 2 tiebreaker rounds');
  unlike( $loop11->logv, 
    qr/Tiebreaker Round 3/,
    'This set *only* goes 2 tiebreaker rounds, no 3rd round');
  # note( $loop11->logv);
};

subtest 'setting active to other than the default' => sub {
  my $bigger = Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/biggerset1.txt') );
  my $remaining = $bigger->TopCountFloor(1);
  $bigger->SetActive( $remaining );
  my $bigscores = $bigger->ScoreMinMax( 'opposition' );
  is_deeply(
    [ sort keys $bigscores->%* ],
    [ qw/CHOCOANTS CHOCOLATE MINTCHIP PISTACHIO TOAD VANILLA VOMIT / ],
    'set with active set changed only scored the correct choices');
  is_deeply(
    $bigscores->{'TOAD'}{'score'},
    [ 149, 122, 108, 21, 3, 3 ],
    'check the scores for one of those choices');
};

done_testing();
