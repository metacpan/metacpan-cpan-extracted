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
use Try::Tiny;
use Vote::Count::Charge;
# use Vote::Count::Helper::FullCascadeCharge;
# use Vote::Count::Helper::NthApproval;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Warnings qw/warns warning warnings no_warnings/;

use Data::Dumper;

subtest '_setTieBreaks' => sub {
  my $A = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/data1.txt')
  );
  like(
    $A->logd(),
    qr/TieBreakMethod is undefined, setting to precedence/,
    "Logged: TieBreakMethod is undefined, setting to precedence"
  );
  note(
    'this subtest is just for coverage, but did find error by writing it.');
  my $B = Vote::Count::Charge->new(
    BallotSet      => read_ballots('t/data/data1.txt'),
    Seats          => 2,
    VoteValue      => 1000000,
    TieBreakMethod => 'grandjunction',
    PrecedenceFile => 't/data/tiebreakerprecedence1.txt',
  );
  is( $B->TieBreakMethod, 'grandjunction', 'correct tiebreaker reported' );
  is(
    $B->PrecedenceFile,
    't/data/tiebreakerprecedence1.txt',
    'correct precedencefile reported'
  );
  my $C = Vote::Count::Charge->new(
    BallotSet      => read_ballots('t/data/data1.txt'),
    TieBreakMethod => 'precedence',
    Seats          => 4,
  );
  is( $C->TieBreakMethod, 'precedence', 'correct tiebreaker reported' );
  is( $C->PrecedenceFile, '/tmp/precedence.txt',
    'precedencefile set when missing' );
};

subtest '_inits' => sub {
  my $D = Vote::Count::Charge->new(
    Seats     => 4,
    VoteValue => 1000,
    BallotSet => read_ballots('t/data/data1.txt')
  );
  is( $D->BallotSet()->{ballots}{'MINTCHIP'}{'votevalue'},
    1000, 'init correctly set votevalue for a choice' );
  my $DExpect = {
    'STRAWBERRY' => 1000,
    'PISTACHIO'  => 1000,
    'VANILLA'    => 5000,
    'CHOCOLATE'  => 3000,
    'CARAMEL'    => 1000,
    'MINTCHIP'   => 7000,
    'ROCKYROAD'  => 1000,
    'RUMRAISIN'  => 1000
  };
  my $APV = $D->Approval->RawCount();
  is_deeply( $APV, $DExpect,
    'Use Approval to show correct weights were set' );
  my $DX2 = {};
  for my $k ( keys $DExpect->%* ) {
    $DX2->{$k} = { 'state' => 'hopeful', 'votes' => 0 };
  }
  is_deeply( $D->GetChoiceStatus(), $DX2, 'Inited states and votes' );
  $D->SetChoiceStatus( 'CARAMEL',   { state => 'withdrawn' } );
  $D->SetChoiceStatus( 'ROCKYROAD', { state => 'suspended', votes => 12 } );
  is_deeply(
    $D->GetChoiceStatus('CARAMEL'),
    { state => 'withdrawn', votes => 0 },
    'changed choice status for a choice'
  );
  is_deeply(
    $D->GetChoiceStatus('ROCKYROAD'),
    { state => 'suspended', votes => 12 },
    'changed both status status values for a choice'
  );

  $D->Defer( 'RUMRAISIN' );
  is( $D->GetChoiceStatus('RUMRAISIN')->{state}, 'deferred');

  $D->Defeat('STRAWBERRY');
  is_deeply(
    $D->GetChoiceStatus('STRAWBERRY'),
    { state => 'defeated', votes => 0 },
    'Defeated a choice'
  );
  is_deeply( [$D->Withdrawn()], ['CARAMEL'],
    'withdrawn method with 1 withdrawn');
  $D->Withdraw( 'STRAWBERRY' );
  is_deeply( [$D->Withdrawn()], ['CARAMEL', 'STRAWBERRY'],
    'withdrawn method with 2 withdrawn');
  undef $D;
  like(
    dies {
      Vote::Count::Charge->new(
        Seats     => 4,
        BallotSet => read_range_ballots('t/data/tennessee.range.json')
      );
    },
    qr/only supports rcv/,
    "Attempt to use range ballots was fatal."
  );

};

done_testing();
