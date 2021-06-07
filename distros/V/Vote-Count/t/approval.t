#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Dumper;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';

my $VC1 = Vote::Count->new( BallotSet => read_ballots('t/data/data2.txt'), );

my $expectA1 = {
  CARAMEL    => 1,
  CHOCOLATE  => 8,
  MINTCHIP   => 8,
  PISTACHIO  => 2,
  ROCKYROAD  => 2,
  RUMRAISIN  => 1,
  STRAWBERRY => 5,
  VANILLA    => 10
};

my $expectNonA1 = {
  CARAMEL    => 14,
  CHOCOLATE  => 7,
  MINTCHIP   => 7,
  PISTACHIO  => 13,
  ROCKYROAD  => 13,
  RUMRAISIN  => 14,
  STRAWBERRY => 10,
  VANILLA    => 5
};

is_deeply( $VC1->Approval()->RawCount(),
  $expectA1, "Approval counted for a small set with no active list" );

# done_testing();
# =pod

is_deeply( $VC1->NonApproval()->RawCount(),
  $expectNonA1, "the NonApproval count from the same set" );

my $A2 = $VC1->Approval(
  {
    'VANILLA'   => 1,
    'CHOCOLATE' => 1,
    'CARAMEL'   => 1,
    'PISTACHIO' => 1,
  }
);
my $expectA2 = {
  CARAMEL   => 1,
  CHOCOLATE => 8,
  PISTACHIO => 2,
  VANILLA   => 10
};

is_deeply( $A2->RawCount(), $expectA2,
  "Approval counted a small set with AN active list" );

my $Range1 =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/tennessee.range.json') );
my $R1A       = $Range1->Approval();
my $expectR1A = {
  CHATTANOOGA => 100,
  KNOXVILLE   => 100,
  MEMPHIS     => 100,
  NASHVILLE   => 100
};
is_deeply( $R1A->RawCount(), $expectR1A,
  'counted approval for a range ballotset' );

my $R1B =
  $Range1->Approval( { KNOXVILLE => 1, MEMPHIS => 1, NASHVILLE => 1 }, 3 );
my $expectR1B = {
  KNOXVILLE => 58,
  MEMPHIS   => 42,
  NASHVILLE => 100
};
is_deeply( $R1B->RawCount(), $expectR1B,
  'appplied activeset and cutoff to same range ballotset' );

my $Range2 =
  Vote::Count->new(
  BallotSet => read_range_ballots('t/data/fastfood.range.json') );
my $R2A       = $Range2->Approval();
my $expectR2A = {
  "FIVEGUYS"   => 6,
  "MCDONALDS"  => 5,
  "WIMPY"      => 0,
  "WENDYS"     => 3,
  "QUICK"      => 3,
  "BURGERKING" => 11,
  "INNOUT"     => 10,
  "CARLS"      => 7,
  "KFC"        => 4,
  "TACOBELL"   => 4,
  "CHICKFILA"  => 6,
  "POPEYES"    => 4,
};
is_deeply( $R2A->RawCount(), $expectR2A,
  'counted approval for a second range ballotset' );

my $expectR2NONA = {
  "FIVEGUYS"   => 6,
  "MCDONALDS"  => 5,
  "WIMPY"      => 0,
  "WENDYS"     => 3,
  "QUICK"      => 3,
  "BURGERKING" => 11,
  "INNOUT"     => 10,
  "CARLS"      => 7,
  "KFC"        => 4,
  "TACOBELL"   => 4,
  "CHICKFILA"  => 6,
  "POPEYES"    => 4,
};

my $R2B = $Range2->Approval( undef, 2 );
my $expectR2B = {
  "FIVEGUYS"   => 6,
  "MCDONALDS"  => 3,
  "WIMPY"      => 0,
  "WENDYS"     => 3,
  "QUICK"      => 3,
  "BURGERKING" => 3,
  "INNOUT"     => 10,
  "CARLS"      => 1,
  "KFC"        => 1,
  "TACOBELL"   => 1,
  "CHICKFILA"  => 2,
  "POPEYES"    => 0,
};
is_deeply( $R2B->RawCount(), $expectR2B,
  'counted approval with a cutoff for second range ballotset' );

subtest 'weighted approval' => sub {
  my $B1 =  read_ballots('t/data/data2.txt');
  my %bweight = (
    'MINTCHIP:CARAMEL:RUMRAISIN' => 11,
    'CHOCOLATE:MINTCHIP:VANILLA' => 6,
    'VANILLA:CHOCOLATE:STRAWBERRY' => 4,
    'MINTCHIP' => 2,
    'VANILLA' => 1,
    'PISTACHIO:ROCKYROAD:MINTCHIP:VANILLA:CHOCOLATE' => 3,
  );
  for my $b1 ( keys %bweight ) { $B1->{'ballots'}{$b1}{'votevalue'} = $bweight{$b1} }
  # note( Dumper $B1->{'ballots'}->%* );
  my $W1 = Vote::Count->new( BallotSet => $B1 );
  my $W1Expect = {
          'VANILLA' => 34,
          'MINTCHIP' => 31,
          'STRAWBERRY' => 20,
          'PISTACHIO' => 6,
          'RUMRAISIN' => 11,
          'ROCKYROAD' => 6,
          'CHOCOLATE' => 32,
          'CARAMEL' => 11,
  };
  my $W1Result = $W1->Approval();
  is_deeply( $W1Result->RawCount(), $W1Expect,
    'Assigned Integer weights to data2' );
  is( $W1Result->Leader()->{'winner'}, 'VANILLA', 'picked winner with int weights.');

  # Do it again with Floats.
  %bweight = (
    'MINTCHIP:CARAMEL:RUMRAISIN' => .5,
    'CHOCOLATE:MINTCHIP:VANILLA' => 1.6,
    'VANILLA:CHOCOLATE:STRAWBERRY' => 4,
    'MINTCHIP' => 2.2,
    'VANILLA' => 1,
    'PISTACHIO:ROCKYROAD:MINTCHIP:VANILLA:CHOCOLATE' => 3.1,
  );
  for my $b1 ( keys %bweight ) { $B1->{'ballots'}{$b1}{'votevalue'} = $bweight{$b1} }
  my $W2 = Vote::Count->new( BallotSet => $B1 );
  my $W2Expect = {
          'VANILLA' => 29.8,
          'MINTCHIP' => 17.1,
          'STRAWBERRY' => 20,
          'PISTACHIO' => 6.2,
          'RUMRAISIN' => .5,
          'ROCKYROAD' => 6.2,
          'CHOCOLATE' => 27.8,
          'CARAMEL' => .5,
  };
  my $W2Result = $W2->Approval();
  is_deeply( $W2Result->RawCount(), $W2Expect,
    'Assigned Floating Point weights to data2' );
  is( $W2Result->Leader()->{'winner'}, 'VANILLA', 'picked winner with float weights.');
  is_deeply( $expectA1, $W2->LastApprovalBallots(),
      "LastApprovalBallots returns the same result as an earlier unweighted run");


};

done_testing();
