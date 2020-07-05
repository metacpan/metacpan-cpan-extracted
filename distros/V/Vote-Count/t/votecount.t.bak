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
use Vote::Count::ReadBallots 'read_ballots';

my $VC1 = Vote::Count->new( BallotSet => read_ballots('t/data/data1.txt'), );

is( $VC1->BallotSet()->{'options'}{'rcv'},
  1, 'BallotSet option is set to rcv' );

is( $VC1->VotesCast(), 10, 'Get the number of ballots in the set' );
is( $VC1->VotesActive(), $VC1->VotesCast(), 'with default active set votesactive should match votescast');
$VC1->SetActiveFromArrayRef( [ qw( CHOCOLATE STRAWBERRY PISTACHIO ROCKYROAD) ]);
is( $VC1->VotesActive(), 3, 'with short activelist VotesActive is only 3');

$VC1->logt('A Terse Entry');
$VC1->logv('A Verbose Entry');
$VC1->logd('A Debug Entry');

unlink "/tmp/election.full";
ok( lives { $VC1->WriteLog() }, "did not die from writing a log" )
  or note($@);
ok( stat("/tmp/votecount.full"),
  'the default temp file for the full log exists' );
my $tmp = File::Temp::tempdir();
my $VC2 = Vote::Count->new(
  BallotSet => read_ballots('t/data/data1.txt'),
  LogTo     => "$tmp/vc2"
);

$VC2->logt('A Terse Entry');
$VC2->logv('A Verbose Entry');
$VC2->logd('A Debug Entry');
$VC2->WriteLog();
ok( stat("$tmp/vc2\.brief"),
  "created brief log to specified path $tmp/vc2\.brief" );

isa_ok( $VC2->PairMatrix(), ['Vote::Count::Matrix'], 'Confirm Matrix' );

$VC2->SetActive( { 'CHOCOLATE' => 1, 'CARAMEL' => 1, 'VANILLA' => 1 } );

$VC2->UpdatePairMatrix();
is_deeply(
  $VC2->PairMatrix()->ScoreMatrix(),
  { 'CARAMEL' => 0, 'CHOCOLATE' => 1, 'VANILLA' => 2 },
  'Updated Matrix only scores current choices'
);

$VC2->UpdatePairMatrix( { 'CARAMEL' => 1, 'VANILLA' => 2 });
is_deeply(
  $VC2->PairMatrix()->ScoreMatrix(),
  { 'CARAMEL' => 0, 'VANILLA' => 1 },
  'UpdatePairMatrix with an explicit active set'
);



done_testing();
