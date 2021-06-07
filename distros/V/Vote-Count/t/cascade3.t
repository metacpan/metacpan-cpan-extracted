#!/usr/bin/env perl

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
# use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;
no warnings 'experimental';
# use Path::Tiny;
use Vote::Count::Charge::Cascade;
use Vote::Count::ReadBallots 'read_ballots';
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Warnings qw/warns warning warnings no_warnings/;
use Vote::Count::Helper::TestBalance 'balance_ok';
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

subtest 'exception' => sub {
  my $A = newA;
  $A->Elect( 'Allan_GRAHAM_Lab');
  like(
    dies { $A->CalcCharge(103957) },
    qr/LastTopCountUnWeighted failed/,
    "CalcCharge threw an exception when TopCount wasn't performed first"
  );
  my $recalc =
  Vote::Count::Charge::Cascade->new(
    Seats     => 4,
    BallotSet => dclone $set1,
    VoteValue => 100,
    LogTo     => '/tmp/votecount_recalc',
    EstimationRule => 'estimate',
    EstimationFresh => 1,
  );
  like(
    dies {
      $recalc->TopCount;
      my ( $est, $cap ) = Vote::Count::Charge::Cascade::_preEstimate( $recalc, 120301, 'William_GOLDIE_SNP', 'Allan_GRAHAM_Lab' ); },
    qr/Fresh Estimation/,
    "Fresh Estimation used with the estimate option throws exception"
  );

};

done_testing();
