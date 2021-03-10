#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
use Test2::Tools::Exception qw/dies lives/;

use Path::Tiny;
use File::Temp;
use Data::Dumper;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';

my $VC1 = Vote::Count->new( BallotSet => read_ballots('t/data/data1.txt') );

my @ChoicesVC1 = sort ( qw/VANILLA CHOCOLATE STRAWBERRY PISTACHIO ROCKYROAD MINTCHIP CARAMEL RUMRAISIN/);
is_deeply(
  [$VC1->GetChoices()],
  \@ChoicesVC1,
  'GetChoices method returns expected list' );

is( $VC1->BallotSet()->{'options'}{'rcv'},
  1, 'BallotSet option is set to rcv' );

is( $VC1->VotesCast(), 10, 'Get the number of ballots in the set' );
is( $VC1->VotesActive(), $VC1->VotesCast(),
  'with default active set votesactive should match votescast' );
$VC1->SetActiveFromArrayRef(
  [qw( CHOCOLATE STRAWBERRY PISTACHIO ROCKYROAD)] );
is( $VC1->VotesActive(), 3, 'with short activelist VotesActive is only 3' );

$VC1->ResetActive();
is_deeply(
  $VC1->GetActive(),
  $VC1->BallotSet()->{'choices'},
  'After resetting active the Active Set matches the BallotSet choices'  );
is( $VC1->VotesActive(), 10, 'after reset VotesActive is 10' );

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

is_deeply( [ $VC2->GetActiveList() ],
           [ $VC2->PairMatrix->GetActiveList() ],
           'active lists are the same between main object and pairmatrix');

$VC2->SetActive( { 'CHOCOLATE' => 1, 'CARAMEL' => 1, 'VANILLA' => 1 } );

is_deeply( [ $VC2->GetActiveList() ],
           [ $VC2->PairMatrix->GetActiveList() ],
           'after SetActive to main object, active lists are the same between main object and pairmatrix');

is_deeply(
  $VC2->PairMatrix()->ScoreMatrix(),
  { 'CARAMEL' => 0, 'CHOCOLATE' => 1, 'VANILLA' => 2 },
  'Matrix only scores current choices'
);

# is_deeply needs the array as an arrayref
is_deeply( [ $VC2->GetActiveList() ],
           [ qw/CARAMEL CHOCOLATE VANILLA/],
           'GetActiveList returns list of active choices');

$VC2->SetActiveFromArrayRef( [ 'CHOCOLATE', 'MINTCHIP' ]);
is_deeply( $VC2->Active(), { 'CHOCOLATE' => 1, 'MINTCHIP' => 1},
  'SetActiveFromArrayRef' );

is( $VC2->GetBallots()->{'VANILLA'}{'count'}, 2,
  'Confirm a value from GetBallots');

my $withdraws = Vote::Count->new(
    BallotSet => read_ballots('t/data/biggerset1.txt'),
    WithdrawalList => 't/data/biggerset1withdrawn.txt',
  );
my $wda = $withdraws->GetActive;
is( $wda->{'RUMRAISIN'},
    undef,
    'a choice removed by withdrawalist isnt in active set') ;

done_testing();
