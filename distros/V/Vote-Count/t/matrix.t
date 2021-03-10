#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;

# my $json = JSON::MaybeXS->new( utf8 => 1, pretty => 1 );

use Path::Tiny;

use Vote::Count;
use Vote::Count::Matrix;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';

my $M1 =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/ties1.txt'),
  );

my $M1GJ = Vote::Count::Matrix->new(
  'BallotSet'      => read_ballots('t/data/ties1.txt'),
  'TieBreakMethod' => 'grandjunction',
);

my $M2 =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/data1.txt'),
  );

my $M3 =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/data2.txt'),
  );

my $LoopSet =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/loop1.txt'),
  );

my $KnotSet =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/knot1.txt'),
  );

my $FastFood =
  Vote::Count::Matrix->new(
  'BallotSet' => read_range_ballots('t/data/fastfood.range.json'), );

isa_ok( $M1, ['Vote::Count::Matrix'], 'The matrix is a Vote::Count::Matrix' );

note 'Testing with Condorcet removal including choices with a tie.';
my $N1 =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/ties1.txt'),
  );
my $mmm = $N1->CondorcetLoser(1);
is( $mmm->{'eliminations'},
  11, '11 eliminated Condorcet losers in sample with ties' );

subtest '_conduct_pair returns hash with pairing info' => sub {
  my $t1 =
    Vote::Count::Matrix::_conduct_pair( $M1, 'RUMRAISIN', 'STRAWBERRY' );
  my $x1 = {
    loser      => "",
    margin     => 0,
    RUMRAISIN  => 4,
    STRAWBERRY => 4,
    tie        => 1,
    winner     => "",
  };
  is_deeply( $t1, $x1, 'A Tie' );
  my $t2 =
    Vote::Count::Matrix::_conduct_pair( $M1, 'RUMRAISIN', 'FUDGESWIRL' );
  my $x2 = {
    FUDGESWIRL => 6,
    loser      => "RUMRAISIN",
    margin     => 2,
    RUMRAISIN  => 4,
    tie        => 0,
    winner     => "FUDGESWIRL",
  };
  is_deeply( $t2, $x2, 'has winner' );
};

subtest 'check some in the matrix' => sub {
  my $xVanMint = {
    loser    => "",
    margin   => 0,
    MINTCHIP => 6,
    tie      => 1,
    VANILLA  => 6,
    winner   => ""
  };
  my $xRockStraw = {
    loser      => "STRAWBERRY",
    margin     => 1,
    ROCKYROAD  => 5,
    STRAWBERRY => 4,
    tie        => 0,
    winner     => "ROCKYROAD"
  };
  my $VanMint = $M1->{'Matrix'}{'VANILLA'}{'MINTCHIP'};
  is_deeply( $xVanMint, $VanMint, 'check a tie' );
  my $RockStraw = $M1->{'Matrix'}{'ROCKYROAD'}{'STRAWBERRY'};
  is_deeply( $xRockStraw, $RockStraw, 'one with a winner' );
  is_deeply(
    $M1->{'Matrix'}{'FUDGESWIRL'}{'CHOCCHUNK'},
    $M1->{'Matrix'}{'CHOCCHUNK'}{'FUDGESWIRL'},
    'access a result in both possible pairing orders identical'
  );
};

subtest 'check that ties are broken with grandjunction' => sub {

  note $M1GJ->TieBreakMethod();
  my $xVanMint = {
    loser    => "MINTCHIP",
    margin   => 0,
    MINTCHIP => 6,
    tie      => 0,
    VANILLA  => 6,
    winner   => "VANILLA"
  };
  my $xRockStraw = {
    loser      => "STRAWBERRY",
    margin     => 1,
    ROCKYROAD  => 5,
    STRAWBERRY => 4,
    tie        => 0,
    winner     => "ROCKYROAD"
  };
  my $VanMint = $M1GJ->{'Matrix'}{'VANILLA'}{'MINTCHIP'};
  is_deeply( $VanMint, $xVanMint, 'check a tie' );
  my $RockStraw = $M1GJ->{'Matrix'}{'ROCKYROAD'}{'STRAWBERRY'};
  is_deeply( $xRockStraw, $RockStraw, 'one with a winner' );

  $M1GJ->LogTo('/tmp/m1gj_matrix');
  $M1GJ->WriteLog();
  # note $M1GJ->logv;
};

subtest 'ScoreMatrix' => sub {
  my $scored1  = $M2->ScoreMatrix();
  my $xscored1 = {
    CARAMEL    => 1,
    CHOCOLATE  => 5,
    MINTCHIP   => 7,
    PISTACHIO  => 1,
    ROCKYROAD  => 0.001,
    RUMRAISIN  => 0.001,
    STRAWBERRY => 0.001,
    VANILLA    => 6
  };
  is_deeply( $scored1, $xscored1, 'check scoring for a dataset' );
  my $xscored2 = {
    CHOCOLATE => 1,
    MINTCHIP  => 3,
    PISTACHIO => 0,
    VANILLA   => 2
  };

  $M2->SetActive($xscored2);
  my $scored2 = $M2->ScoreMatrix();
  is_deeply( $scored2, $xscored2,
    'check scoring same data after eliminating some choices' );
};

subtest 'CondorcetLoser elimination' => sub {
  my $E2 = $M2->CondorcetLoser();
  is(
    $E2->{'terse'},
    "Eliminated Condorcet Losers: PISTACHIO, CHOCOLATE, VANILLA\n",
    "terse is list of eliminated losers"
  );

  like(
    $E2->{'verbose'},
    qr/^Removing Condorcet Losers/,
    'check verbose for expected first line'
  );
  like(
    $E2->{'verbose'},
    qr/Eliminationg Condorcet Loser: \*CHOCOLATE\*/,
    'check verbose for an elimination notice'
  );
  is_deeply(
    $M2->{'Active'},
    { 'MINTCHIP' => 3 },
    'only the condorcet winner remains in active'
  );

};

subtest '_getsmithguessforchoice' => sub {
  my %rumr = Vote::Count::Matrix::_getsmithguessforchoice( 'RUMRAISIN',
    $M1->{'Matrix'} );
  is( scalar( keys %rumr ),
    11, 'choice with a lot of losses proposed large smith set' );
  my %mchip = Vote::Count::Matrix::_getsmithguessforchoice( 'MINTCHIP',
    $M1->{'Matrix'} );
  is_deeply(
    [ sort keys %mchip ],
    [qw/ BUBBLEGUM MINTCHIP VANILLA/],
    'choice with 1 defeat and 1 tie returned correct 3 choices'
  );
};

subtest 'SmithSet' => sub {
  my $k     = $KnotSet->SmithSet();
  my @knot  = sort keys $k->%*;
  my @xknot = (qw/ CARAMEL CHOCOLATE MINTCHIP VANILLA/);
  is_deeply( \@knot, \@xknot,
    'Simple Knot test data returns 4 for Smith Set' );
  my $l     = $LoopSet->SmithSet();
  my @loop  = sort keys $l->%*;
  my @xloop = (qw/CHOCOLATE MINTCHIP VANILLA/);
  is_deeply( \@loop, \@xloop, 'Loop test data returns 3 element Smith Set' );
  my $m  = $M2->SmithSet();
  my @m  = sort keys $l->%*;
  my @xm = (qw/CHOCOLATE MINTCHIP VANILLA/);
  is_deeply( \@m, \@xm, 'Set with no winner' );
};

subtest 'CondorcetWinner' => sub {
  is( $M1->CondorcetWinner(),
    '', 'set with no condorcet winner returns empty string' );
  is( $M2->CondorcetWinner(),
    'MINTCHIP', 'set with  condorcet winner returns it' );
  is( $M3->CondorcetWinner(),
    'MINTCHIP', 'set with  condorcet winner returns it' );
  is( $LoopSet->CondorcetWinner(),
    '', 'set with no condorcet winner returns empty string' );
  is( $KnotSet->CondorcetWinner(),
    '', 'set with no condorcet winner returns empty string' );
  $KnotSet->SetActive( { 'VANILLA' => 1 } );
  is( $KnotSet->CondorcetWinner(), 'VANILLA',
'reduced Active of last winnerless set to one choice, now returned as winner'
  );
};

subtest 'GetPairResult' => sub {
  is( $M1->GetPairWinner( 'FUDGESWIRL', 'ROCKYROAD' ),
    'FUDGESWIRL', 'Lookup the winner of a pairing with GetPairWinner' );
  my $STFS = {
    'FUDGESWIRL' => 6,
    'loser'      => "STRAWBERRY",
    'margin'     => 2,
    'STRAWBERRY' => 4,
    'tie'        => 0,
    'winner'     => "FUDGESWIRL"
  };
  is_deeply( $M1->GetPairResult( "FUDGESWIRL", "STRAWBERRY" ),
    $STFS, "Check the hashref returned by GetPairResult" );
};

subtest 'GreatestLoss' => sub {
  is( $M1->RankGreatestLoss()->Leader()->{'winner'},
    'CARAMEL', 'CARAMEL had greatest loss and is reported as the winner' );
  $M1->ResetActive();
  is( $M1->GreatestLoss('FUDGESWIRL'), 2, 'M1 fudgeswirl' );
  $KnotSet->ResetActive();
  is( $KnotSet->GreatestLoss('STRAWBERRY'), 13, 'knotset strawberry' );
  is( $KnotSet->GreatestLoss('PISTACHIO'),  9,  'knotset pistachio' );
};

subtest 'Range Ballots' => sub {
  my $ffr = $FastFood->_conduct_pair( 'BURGERKING', 'CHICKFILA' );
  my $expectffrpair = {
    BURGERKING => 11,
    CHICKFILA  => 3,
    loser      => "CHICKFILA",
    margin     => 8,
    tie        => 0,
    winner     => "BURGERKING"
  };
  is_deeply( $ffr, $expectffrpair, 'check pairing result _conduct_pair' );
  is( $FastFood->GetPairWinner( 'BURGERKING', 'MCDONALDS' ),
    'BURGERKING', 'use GetPairWinner to find winner of a pairing' );
  my $FastFood2 = Vote::Count::Matrix->new(
    TieBreakMethod => 'approval',
    BallotSet      => $FastFood->BallotSet()
  );
  my $scored1 = $FastFood->ScoreMatrix();
  my $scored2 = $FastFood2->ScoreMatrix();
  is( $scored1->{'CHICKFILA'},
    4, 'scorematrix count wins for a choice with no tiebreaker' );
  is( $scored2->{'CHICKFILA'},
    6, 'scorematrix count wins for same choice with approval tiebreaker' );
};

subtest 'ScoreTable' => sub {
  my $st = $FastFood->ScoreTable();
  like(
    $st,
    qr/\| INNOUT     \| 11    \|/,
    'check an expected formated line from ScoreTable'
  );
};

subtest 'weighted' => sub {
  is( $M1->GetPairResult( 'VANILLA','CHERRY')->{'tie'}, 1,
    'Unweighted Pair Result that is a tie');
  $M1->{'BallotSet'}{'ballots'}{'VANILLA:BUBBLEGUM:MINTCHIP:CHOCOLATE'}{'votevalue'} = .1;
  $M1->{'BallotSet'}{'ballots'}{'VANILLA:CHOCOLATE:STRAWBERRY'}{'votevalue'} = .1;
  my $W =
  Vote::Count::Matrix->new( 'BallotSet' => $M1->{'BallotSet'},
  )->GetPairResult( 'VANILLA','CHERRY');
  is( $W->{'tie'}, 0,
    'unweighted this pair was a tie, weighted it is not a tie');
  is( $W->{'winner'}, 'CHERRY',
    'unweighted this pair was a tie, weighted it has a winner');
  is( $W->{'VANILLA'}, 0.6, 'weight of choice reduced in weighting shows decimal');
};

done_testing();
