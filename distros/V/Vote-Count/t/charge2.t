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

subtest 'Charge' => sub {
  my $E = Vote::Count::Charge->new(
    Seats     => 3,
    VoteValue => 1000,
    BallotSet => read_ballots( 't/data/data1.txt', )
  );

  # resetvotevalue and topcount need to be done before every new Charge.
  # $E->ResetVoteValue();    # undo partial charging from previous.
  $E->TopCount();          # init topcounts.
  is( $E->Charge( 'VANILLA', 3000, 1 )->{'surplus'}, -2997,
    'undercharge shows negative surplus');
  $E->ResetVoteValue();    # undo partial charging from previous.
  $E->TopCount();          # init topcounts.
  my $E1 = $E->Charge( 'MINTCHIP', 3000, 1000 );
  note('checking the return from the first charge attempt to E');
  is( $E1->{choice},   'MINTCHIP', '...the choice is included' );
  is( $E1->{surplus},  2000,       '...the surplus is correct' );
  is( $E1->{cntchrgd}, 5,          '...number of ballots charged' );
  is( $E1->{quota}, 3000, '...quota that was provided is in return' );
  is_deeply(
    [ sort( $E1->{ballotschrgd}->@* ) ],
    [ 'MINTCHIP', 'MINTCHIP:CARAMEL:RUMRAISIN' ],
    '...list of ballots that were charged'
  );
  is( $E->GetChoiceStatus('MINTCHIP')->{'votes'},
    5000, '...choice_status has updated votes' );
};

subtest 'Look at the Charges on some Ballots' => sub {
  my $B = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 1000,
    BallotSet => read_ballots( 't/data/biggerset1.txt', )
  );
  $B->TopCount();
  my $B1 = $B->Charge( 'VANILLA', 40000, 500 );
  $B->Elect('VANILLA');
  $B->TopCount();
  $B1 = $B->Charge( 'CHOCOLATE', .5 * 40000, 500 );
  $B->Elect('CHOCOLATE');
  $B->TopCount();
  $B1 = $B->Charge( 'MINTCHIP', 40000, 750 );
  $B->Elect('MINTCHIP');
  $B->TopCount();
  $B1 = $B->Charge( 'CARAMEL', 40000, 0 );
  $B->Elect('CARAMEL');
  $B->TopCount();
  my %Ballots = $B->GetBallots()->%*;
  is_deeply(
    $Ballots{'VANILLA:CHOCOLATE:STRAWBERRY'}->{charged},
    { VANILLA => 500, CHOCOLATE => 500 },
    'look at a split'
  );
  is( $Ballots{'VANILLA:CHOCOLATE:STRAWBERRY'}->{votevalue},
    0, 'this ballot has no value left' );
  is_deeply(
    $Ballots{'MINTCHIP'}->{charged},
    { MINTCHIP => 750 },
    'look at another split'
  );
  is( $Ballots{'MINTCHIP'}->{votevalue},
    250, 'this ballot has some value left' );
  is_deeply(
    $Ballots{'MINTCHIP:CARAMEL:RUMRAISIN'}->{charged},
    { MINTCHIP => 750, CARAMEL => 250 },
    'look at a split with below quota choice'
  );
  is( $Ballots{'MINTCHIP:CARAMEL:RUMRAISIN'}->{votevalue},
    0, 'this ballot can have no value left' );
  is_deeply(
    $Ballots{'VANILLA'}->{charged},
    { VANILLA => 500 },
    'look at one with no split'
  );
  is( $Ballots{'VANILLA'}->{votevalue},
    500, 'this ballot has half value left' );
};


done_testing();
