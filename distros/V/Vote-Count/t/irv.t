#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
use Data::Printer;
# use Data::Dumper;

use Path::Tiny;
use Try::Tiny;
use Storable 'dclone';

use Vote::Count 0.020;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

my $B1 = Vote::Count->new( BallotSet => read_ballots('t/data/data2.txt'), );
my $B2 =
  Vote::Count->new( BallotSet => read_ballots('t/data/biggerset1.txt'), );
my $B3 = Vote::Count->new( BallotSet => read_ballots('t/data/irvtie.txt'), );

# Active is passed by reference the GetActive/SetActive
# methods break the reference for safety
# prove that this protects copies of the ActiveSet from
# changes IRV makes to it.
my $activebeforeB1      = $B1->GetActive();
my $save_activebeforeB1 = { $activebeforeB1->%* };
$B1->SetActive($activebeforeB1);

my $r1  = $B1->RunIRV();
my $ex1 = {
  'votes'     => 15,
  'winner'    => 'MINTCHIP',
  'winvotes'  => 8,
  'threshold' => 8,
};
is_deeply( $r1, $ex1, 'returns set with Mintchip winning 8 of 15 votes' );

is_deeply( $activebeforeB1, $save_activebeforeB1,
  'confirm that GetActive/SetActive broke reference links for safety' );

my $r2 = $B2->RunIRV();
# note $B2->logd();
my $ex2 = {
  'votes'     => 216,
  'winner'    => 'MINTCHIP',
  'winvotes'  => 122,
  'threshold' => 109,
};
is_deeply( $r2, $ex2, 'returns set with Mintchip winning 122 of 216 votes' );
# need test of tie at the top.

my $r3  = $B3->RunIRV();
my $ex3 = {
  tie    => 1,
  tied   => [ 'CHOCOLATE', 'VANILLA' ],
  winner => 0
};
is_deeply( $r3, $ex3, 'tie at top returns correct data' );

subtest 'check the logs' => sub {
  my $blv = $B1->logv();
  note "VERBOSE LOG: \n$blv";
  # crush the space out so that stupid spacing variances
  # don't break this test.
  $blv =~ tr/ \n//d;
  my $logcheck1 = q/|Winner|MINTCHIP|/;
  my $logcheck2 = q/Eliminating:PISTACHIO---IRVRound4/;
  for my $check ( $logcheck1, $logcheck2 ) {
    like( $blv, qr/$check/, "check verbose log for $check" );
  }
  my $tlv = $B1->logt();
  note "TERSE LOG:\n$tlv";
  my $expecttlv = q/
    Instant Runoff Voting
    Choices:
    CARAMEL, CHOCOLATE, MINTCHIP, PISTACHIO, ROCKYROAD, RUMRAISIN, STRAWBERRY, VANILLA
    ---
    | Winner                    | MINTCHIP |
    | Votes in Final Round      | 15       |
    | Votes Needed for Majority | 8        |
    | Winning Votes             | 8        |/;
  # crush the spaces.
  $expecttlv =~ tr/ \n//d;
  $tlv =~ tr/ \n//d;
  like( $tlv, qr/$expecttlv/, "compare terse log to expected log" );
};

subtest 'tie resolution' => sub {
  $B3->SetActive( $B3->BallotSet->{'choices'} );
  my $all = $B3->RunIRV( undef, 'all' );
  my $ex_all = {
    tie    => 1,
    tied   => [ 'CHOCOLATE', 'VANILLA' ],
    winner => 0
  };
  is_deeply( $all, $ex_all, 'tie at top with default all' );
  my $approval = $B3->RunIRV( undef, 'approval' );
  is_deeply( $approval, $ex_all, 'tie at top with approval' );
  my $gj = $B3->RunIRV( undef, 'grandjunction' );
  is( $gj->{'winner'}, 'VANILLA', 'grandjunction broke tie correctly' );

  my $ballotsirvtie2 = read_ballots('t/data/irvtie2.txt');
  my $B4             = Vote::Count->new(
    BallotSet      => $ballotsirvtie2,
    TieBreakMethod => 'approval'
  );
  my $B5 = Vote::Count->new(
    BallotSet      => $ballotsirvtie2,
    TieBreakMethod => 'approval'
  );
  my $B6 = Vote::Count->new( BallotSet => $ballotsirvtie2, );

  # note $B4->TopCount()->RankTable();
  # note $B4->Approval()->RankTable();

  my $b4expect = {
    'tie'    => 1,
    'tied'   => [ "CHOCOLATE", "VANILLA" ],
    'winner' => 0
  };

  note(
'the next 3 use the same ballotset, but all, approval, and grandjunction return a tie and different winners'
  );

  # B4 defaulted to approval, try it with all.
  my $b4all = undef;
  $B4->RunIRV( undef, 'all' );

# is_deeply( $b4all, $b4expect,
#   'with all specified over object setting approval tiebreaker irvties2 is a tie');

  my $b5expect = {
    'threshold' => 45,
    'votes'     => 89,
    'winner'    => "CHOCOLATE",
    'winvotes'  => 89
  };
  my $b5approval = $B5->RunIRV();
  is_deeply( $b5approval, $b5expect,
    "approval set in object run defaults expected result" );

  # note $B5->logv();
  # p $b5approval;

  # note $B6->TopCount()->RankTable();
  my $b6junction = $B6->RunIRV( undef, 'grandjunction' );
  my $b6expect = {
    'threshold' => 46,
    'votes'     => 90,
    'winner'    => "VANILLA",
    'winvotes'  => 90
  };
  is_deeply( $b6junction, $b6expect,
    'grandjunction as last 2 different winner' );
  # p $b6junction;
  # note $B6->logv();
  # note $b4all->logv();
};

my $fastfood =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json') );

my $tenrange =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/tennessee.range.json') );

subtest 'Range Ballot' => sub {
  my $fastexpect = {
    'threshold' => 8,
    'votes'     => 15,
    'winner'    => "INNOUT",
    'winvotes'  => 8
  };
  my $expecttenr = {
    threshold => 51,
    votes     => 100,
    winner    => "KNOXVILLE",
    winvotes  => 58
  };
  is_deeply( try { $fastfood->RunIRV() },
    $fastexpect, 'Ran IRV on fastfood Range BallotSet' );
  is_deeply( try { $tenrange->RunIRV() },
    $expecttenr, 'Ran IRV on converted Tennessee Range BallotSet' );
};

done_testing();
