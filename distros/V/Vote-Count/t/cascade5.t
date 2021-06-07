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
use Vote::Count::ReadBallots 'read_ballots';
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Warnings qw/warns warning warnings no_warnings/;
use Vote::Count::Helper::TestBalance 'balance_ok';
use Storable 3.15 'dclone';
use Data::Dumper;
# use Carp::Always;

package TestC {
  use Moose;
  extends 'Vote::Count::Charge::Cascade';
  use namespace::autoclean;
  with 'Vote::Count::Helper::NthApproval';
  __PACKAGE__->meta->make_immutable;
};

my $dumbarton = read_ballots('t/data/Scotland2017/Dumbarton.txt');
my $burlington = read_ballots('t/data/burlington2009.txt');

sub newB ( $lname='burlington') {
  TestC->new(
    Seats     => 3,
    BallotSet => dclone $burlington,
    VoteValue => 100,
    LogTo     => '/tmp/votecount_$lname',
  );
}

subtest 'setup' => sub {
  my $B = newB();
  is_deeply( [ $B->NthApproval() ],
    [ 'WRITEIN'],
    'sure loser defeated a choice at setup for burlington');
  $B->Defeat( 'WRITEIN' ) ;

  $B->NewRound();
  my $quotaB = $B->SetQuota();
  my @electB = sort $B->QuotaElectDo( $quotaB );
  is_deeply( \@electB, [ 'KISS', 'WRIGHT'], 'burl winners with first quota'
  );
  my $chargedb = $B->CalcCharge ($quotaB );
  while (my ($choice, $charge) = each $chargedb->%* ) {
    $B->Charge( $choice, $quotaB, $charge);
  }

  $B->NewRound();
  is_deeply( [  $B->NthApproval() ], [ 'SIMPSON' ],
      'burl Nth Approval defeated a choice in second round');
  $B->Defeat( 'SIMPSON');
  $B->NewRound();
  $quotaB = $B->SetQuota();
  is_deeply( [$B->GetActiveList], ['MONTROLL','SMITH'],
    'burl two choices are left');
  my ($burlfinal) = $B->QuotaElectDo($quotaB);
  is( $burlfinal, 'MONTROLL', 'burl QuotaElectDo picks the winner' );

};

done_testing();
