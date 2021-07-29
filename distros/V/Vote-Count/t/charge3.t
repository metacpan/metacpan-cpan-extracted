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

subtest 'Elect, Defeat, et al' => sub {
  my $F = Vote::Count::Charge->new(
    Seats     => 3,
    VoteValue => 1000,
    BallotSet => read_ballots( 't/data/data1.txt', )
  );
  is_deeply( [ $F->Elect('VANILLA') ],
    ['VANILLA'], 'returns elected choice in list' );
  is_deeply( [ $F->Pending('RUMRAISIN') ],
    ['RUMRAISIN'], 'set a choice pending' );
  is( $F->GetActive()->{'RUMRAISIN'}, undef, 'Rumraisin is pending and not in Active Set' );
  is_deeply(
    [ $F->Elect('RUMRAISIN') ],
    [ 'VANILLA', 'RUMRAISIN' ],
    'electing second choice returns both in correct order'
  );
  is_deeply(
    [ $F->GetActiveList() ],
    [qw/CARAMEL CHOCOLATE MINTCHIP PISTACHIO ROCKYROAD STRAWBERRY /],
    'Active List no longer contains 2 elected choices'
  );
  is( $F->GetChoiceStatus()->{'RUMRAISIN'}{'state'},
    'elected', 'choice status for a newly elected choice is elected' );
  is( $F->GetChoiceStatus('MINTCHIP')->{'state'},
    'hopeful', 'choice status for an unelected choice is still hopeful' );
  is( $F->Pending(), 0, 'after electing pending choice, pending is empty' );
  is_deeply(
    [ $F->Elected() ],
    [ 'VANILLA', 'RUMRAISIN' ],
    'Elected method Returns current list'
  );
  $F->Defeat('CARAMEL');
  $F->Withdraw('CHOCOLATE');
  is_deeply( [ $F->Suspend('ROCKYROAD') ],
    ['ROCKYROAD'], 'suspending a choice returns suspended list' );
  is_deeply(
    [ $F->GetActiveList() ],
    [qw/MINTCHIP PISTACHIO STRAWBERRY /],
    'Active reduced by Elect, Defeat, Withdraw and Suspend'
  );
  is( $F->GetChoiceStatus('CARAMEL')->{state},
    'defeated', 'Confirm defeat with GetChoiceStatus' );
  is( $F->GetChoiceStatus('CHOCOLATE')->{state},
    'withdrawn', 'Confirm withdrawal with GetChoiceStatus' );
  is( $F->GetChoiceStatus('ROCKYROAD')->{state},
    'suspended', 'Confirm suspension with GetChoiceStatus' );
  $F->Reinstate('ROCKYROAD');
  is( $F->GetChoiceStatus('ROCKYROAD')->{state},
    'hopeful', 'Confirm resinstatement with GetChoiceStatus' );
  $F->Reinstate('CARAMEL');
  is( $F->GetChoiceStatus('CARAMEL')->{state},
    'defeated', 'Confirm that Reinstate will not reactivate a defeated choice' );
  is( $F->GetActive()->{'ROCKYROAD'},
    1, 'confirm reinstated back in active list' );
  $F->Suspend('ROCKYROAD');
  $F->Suspend('PISTACHIO');
  $F->Suspend('STRAWBERRY');
  $F->Suspend('STRAWBERRY');    # a second time to prove it wont be in list twice.
  is_deeply(
    [ sort( $F->Suspended() ) ],
    [qw/PISTACHIO ROCKYROAD STRAWBERRY/],
    'confirm list of suspended choices'
  );
  $F->Reinstate('STRAWBERRY');
  $F->Defer('STRAWBERRY');
  is_deeply(
    [ sort( $F->Suspended() ) ],
    [qw/PISTACHIO ROCKYROAD/],
    'moved strawberry to deferred, no longer in suspended'
  );

  is_deeply(
    [ sort( $F->Deferred() ) ],
    [qw/STRAWBERRY/],
    'moved strawberry to deferred, in deferred now'
  );
  is_deeply( [sort $F->Reinstate()], ['PISTACHIO', 'ROCKYROAD','STRAWBERRY'],
    'check list of reinstated choices from reinstate');
  is( $F->Suspended(), 0,
    'group reinstated choices no longer on suspended list' );
  is( $F->GetChoiceStatus('STRAWBERRY')->{state},
    'hopeful', 'Confirm resinstatement with GetChoiceStatus' );
};

subtest 'VCUpdateActive' => sub {
  my $G = Vote::Count::Charge->new(
    Seats     => 3,
    VoteValue => 1000,
    BallotSet => read_ballots( 't/data/data1.txt', )
  );
  for (qw( PISTACHIO RUMRAISIN STRAWBERRY)) {
    $G->{'choice_status'}->{$_}{'state'} = 'defeated';
  }
  $G->{'choice_status'}->{'ROCKYROAD'}{'state'} = 'withdrawn';
  $G->{'choice_status'}->{'CARAMEL'}{'state'}   = 'withdrawn';
  $G->Suspend('MINTCHIP');
  $G->VCUpdateActive();
  is_deeply(
    $G->GetActive(),
    { VANILLA => 1, CHOCOLATE => 1 },
    'VCUPDATEACTIVE set active list to the two hopeful choices'
  );
  $G->{'choice_status'}->{'MINTCHIP'}{'state'} = 'hopeful';
  $G->{'choice_status'}->{'VANILLA'}{'state'} = 'elected';
  $G->VCUpdateActive();
  is_deeply(
    $G->GetActive(),
    { CHOCOLATE => 1, MINTCHIP => 1 },
    'VCUPDATEACTIVE set active with slightly different list'
  );
  $G->{'choice_status'}->{'CARAMEL'}{'state'} = 'pending';
  $G->{'choice_status'}->{'CHOCOLATE'}{'state'} = 'elected';
  $G->VCUpdateActive();
  is_deeply(
    $G->GetActive(),
    { MINTCHIP => 1 },
    'VCUPDATEACTIVE pending choice is no longer active ');
};

done_testing();
