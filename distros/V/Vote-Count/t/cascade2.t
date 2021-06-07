#!/usr/bin/env perl

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
# use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;
no warnings 'experimental';
# use Path::Tiny;
use Vote::Count::Charge::Cascade;
use Vote::Count::Helper::FullCascadeCharge;
use Vote::Count::ReadBallots 'read_ballots';
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Warnings qw/warns warning warnings no_warnings/;
use Vote::Count::Helper::TestBalance;
use Storable 3.15 'dclone';
use Data::Dumper;
# use Carp::Always;

my $set1 = read_ballots('t/data/Scotland2012/Cumbernauld_South.txt');
my $data2 = read_ballots('t/data/data2.txt') ;

sub newA ( $lname='cascadeA') {
  Vote::Count::Charge::Cascade->new(
    Seats     => 4,
    BallotSet => dclone $set1,
    VoteValue => 100,
    LogTo     => '/tmp/votecount_$lname',
  );
}

sub newB ( $lname='cascadeA') {
  Vote::Count::Charge::Cascade->new(
      Seats     => 2,
      BallotSet => dclone $data2,
      VoteValue => 100,
      LogTo     => '/tmp/votecount_$lname',
    );
}
subtest '_chargeInsight' => sub {
  my $A = newA;
  my $B = newB;
  # $B->TopCount;
  $B->Elect( 'VANILLA');
  $B->Elect( 'MINTCHIP');
  my $estimate = { 'MINTCHIP' => 83, 'VANILLA' => 44 };
  my $cap = { 'MINTCHIP' => 100, 'VANILLA' => 100 };
  my $bottom = { 'MINTCHIP' => 0, 'VANILLA' => 0 };
  my $freeze = {};
  my $C1 = $B->_chargeInsight( 375, $estimate, $cap, $bottom, $freeze, 'MINTCHIP', 'VANILLA' );
  is_deeply( $C1->{result}{VANILLA},
    { 'count' => 7, 'surplus' => -67, 'value' => 308 },
    'look at the result for a choice' );
  is_deeply( $C1->{estimate},
    { 'MINTCHIP' => 75, 'VANILLA' => 54 },
    'check the estimate no caps or freezes in play' );
  $cap = { 'MINTCHIP' => 100, 'VANILLA' => 50 };
  my $C2 = $B->_chargeInsight( 375, $estimate, $cap, $bottom, $freeze, 'MINTCHIP', 'VANILLA' );
  is_deeply( $C2->{estimate},
    { 'MINTCHIP' => 75, 'VANILLA' => 50 },
    'check the estimate with a cap in play' );
  $bottom->{ 'VANILLA' } = 71 ;
  my $C4 =  $B->_chargeInsight( 375, $estimate, $cap, $bottom, {}, 'MINTCHIP', 'VANILLA' );
  is_deeply ( $C4->{'estimate'}, { 'MINTCHIP' => 75, 'VANILLA' => 71 },
    'check application of bottom bound' );
};

subtest 'calc charge simple data' => sub {
  my $B = newB;
  $B->TopCount;
  $B->Elect( 'VANILLA');
  $B->Elect( 'MINTCHIP');
  is_deeply( $B->CalcCharge( 375 ),
    { 'MINTCHIP' => 75, 'VANILLA' => 54 },
    'calculate the charge with the simple set two quota choices');
  $B->Elect( 'CHOCOLATE');
  is_deeply( $B->CalcCharge( 375 ),
    { 'MINTCHIP' => 75, 'VANILLA' => 54, 'CHOCOLATE' => 100 },
    'calculate the charge with the simple set two quota choices with 1 under');
};

subtest 'calc charge bigger data' => sub {
  my $A = newA;
  $A->IterationLog( '/tmp/cascade_iteration');
  $A->NewRound();
  $A->Elect( 'William_GOLDIE_SNP');
  $A->Elect( 'Allan_GRAHAM_Lab');
  my $ACharge1 = $A->CalcCharge(120301);
  is_deeply( $ACharge1, #1203
    { Allan_GRAHAM_Lab => 83, William_GOLDIE_SNP => 67 },
    'Calculate the charge for the first 2 elected with the larger test set'
  );
  FullCascadeCharge( $A->GetBallots, 120301, $ACharge1, $A->GetActive, 100 );
  my $roundnum = $A->NewRound( 120301, $ACharge1 );
  my $TC = $A->TopCount();
  my @newly = $A->QuotaElectDo( 120301 );
  my $lastcharge = $A->{'roundstatus'}{$roundnum -1 }{'charge'};
  my $ACharge2 = $A->CalcCharge(120301);
  is_deeply( $ACharge2, #1203
    { Allan_GRAHAM_Lab => 78, William_GOLDIE_SNP => 67, Stephanie_MUIR_Lab => 93 },
    'Calculate the charge adding the next quota winner'
  );
  my $Charge2F = FullCascadeCharge( $A->GetBallots, 120301, $ACharge2, $A->GetActive, 100 );
  my $balance = $A->VotesCast * 100;
  balance_ok( $A->GetBallots, $Charge2F, $balance, [$A->Elected()] );
};

done_testing();

=pod

"name"                      stage1  stage2  stage3  stage4  stage5  stage6  stage7
"rounds"                    round1  ------  round2  round3  round4  round5  round6
  "GOLDIE, William (SNP)"     1779 1204.00 1204.00 1204.00 1204.00 1204.00 1204.00
  "GRAHAM, Allan (Lab)"       1413 1413.00 1204.00 1204.00 1204.00 1204.00 1204.00
  "HOGG, Paddy (SNP)"          444  810.20  815.82  816.32  836.42  857.55  926.39
  "HOMER, Willie (SNP)"        653  783.58  792.45  792.87  819.18  832.46  916.95
  "MASTERTON, Donald (CICA)"   344  358.54  363.13  363.68  392.87  486.34    0.00
  "MCARTHUR, David (Con)"      225  228.88  232.13  232.41  235.75    0.00    0.00
  "MCVEY, Kevin (SSP)"         140  147.76  152.34  153.14    0.00    0.00    0.00
  "MUIR, Stephanie (Lab)"     1017 1044.47 1210.43 1204.00 1204.00 1204.00 1204.00
  "non-transferable"             0   24.57   40.70   44.58  118.77  226.65  559.67
