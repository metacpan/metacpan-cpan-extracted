#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;
use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;

# my $json = JSON::MaybeXS->new( utf8 => 1, pretty => 1 );

use Path::Tiny;

use Vote::Count;
use Vote::Count::Matrix;
use Vote::Count::ReadBallots 'read_ballots';

my $M1 =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/ties1.txt'),
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

isa_ok( $M1, ['Vote::Count::Matrix'], 'The matrix is a Vote::Count::Matrix' );

note 'Testing with Condorcet removal including choices with a tie.' ;
my $N1 =
  Vote::Count::Matrix->new( 'BallotSet' => read_ballots('t/data/ties1.txt'),
  );
my $mmm = $N1->CondorcetLoser( 1 );
is( $mmm->{'eliminations'}, 11,
'11 eliminated Condorcet losers in sampe with ties');


subtest '_conduct_pair returns hash with pairing info' => sub {
  my $t1 = Vote::Count::Matrix::_conduct_pair( $M1->BallotSet, 'RUMRAISIN',
    'STRAWBERRY' );
  my $x1 = {
    loser      => "",
    margin     => 0,
    RUMRAISIN  => 4,
    STRAWBERRY => 4,
    tie        => 1,
    winner     => "",
  };
  is_deeply( $t1, $x1, 'A Tie' );
  my $t2 = Vote::Count::Matrix::_conduct_pair( $M1->BallotSet, 'RUMRAISIN',
    'FUDGESWIRL' );
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

  $M2->Active($xscored2);
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
  $KnotSet->Active( { 'VANILLA' => 1 } );
  is( $KnotSet->CondorcetWinner(), 'VANILLA',
'reduced Active of last winnerless set to one choice, now returned as winner'
  );
};


subtest 'GetPairResult' => sub {
  is(
    $M1->GetPairWinner( 'FUDGESWIRL', 'ROCKYROAD' ),
    'FUDGESWIRL',
    'Lookup the winner of a pairing with GetPairWinner');
  my  $STFS = {
        'FUDGESWIRL' =>  6,
        'loser'      =>  "STRAWBERRY",
        'margin'     =>  2,
        'STRAWBERRY' =>  4,
        'tie'        =>  0,
        'winner'     =>  "FUDGESWIRL"
    };
  is_deeply(
    $M1->GetPairResult( "FUDGESWIRL", "STRAWBERRY"),
    $STFS,
    "Check the hashref returned by GetPairResult");
};

subtest 'GreatestLoss' => sub {
  $M1->ResetActive();
  is( $M1->GreatestLoss( 'FUDGESWIRL'), 2, 'M1 fudgeswirl' );
  $KnotSet->ResetActive();
  is( $KnotSet->GreatestLoss( 'STRAWBERRY'), 13, 'knotset strawberry');
  is( $KnotSet->GreatestLoss( 'PISTACHIO'), 9 , 'knotset pistachio');
};

note( $KnotSet->RankGreatestLoss()->RankTable );

note( $KnotSet->PairingVotesTable );

done_testing();
