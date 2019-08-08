#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';
use Vote::Count::Redact qw/RedactPair RedactBullet RedactSingle/;

use feature qw /postderef signatures/;
no warnings 'experimental';

my $B1 = Vote::Count->new(
  BallotSet => read_ballots('t/data/biggerset1.txt'), );

my $newBallot1 = RedactPair( $B1->BallotSet(), 'VANILLA', 'CHOCOLATE' );
my $newBallot2 = RedactPair( $B1->BallotSet(), 'VOMIT',   'TOAD' );

subtest
  'Compare a new ballotsets accross 2 different pairs for RedactPair'
  => sub {
  is_deeply(
    $newBallot1->{'ballots'}{'VANILLA:CHOCOLATE:STRAWBERRY'}{'votes'},
    [qw/VANILLA STRAWBERRY/], );
  is_deeply(
    $newBallot2->{'ballots'}{'VANILLA:CHOCOLATE:STRAWBERRY'}{'votes'},
    [qw/VANILLA CHOCOLATE STRAWBERRY/],
  );

  is_deeply( $newBallot1->{'ballots'}{'CHOCOANTS:CHOCOLATE'}{'votes'},
    [qw/CHOCOANTS CHOCOLATE/], );
  is_deeply( $newBallot2->{'ballots'}{'CHOCOANTS:CHOCOLATE'}{'votes'},
    [qw/CHOCOANTS CHOCOLATE/], );

  is_deeply(
    $newBallot1->{'ballots'}{'MINTCHIP:CARAMEL:RUMRAISIN'}{'votes'},
    [qw/MINTCHIP CARAMEL RUMRAISIN/],
  );
  is_deeply(
    $newBallot2->{'ballots'}{'MINTCHIP:CARAMEL:RUMRAISIN'}{'votes'},
    [qw/MINTCHIP CARAMEL RUMRAISIN/],
  );

  is_deeply(
    $newBallot1->{'ballots'}{'VOMIT:TOAD'}{'votes'},
    [ 'VOMIT', 'TOAD' ],
  );
  is_deeply( $newBallot2->{'ballots'}{'VOMIT:TOAD'}{'votes'}, ['VOMIT'] );
};

subtest 'bullet redaction'  => sub {
  my $apbefore = $B1->Approval();
  my $t1 = Vote::Count->new(
    BallotSet => RedactBullet(
    $B1->BallotSet(), 'VANILLA', 'CHOCOLATE' ) );
  my $apafter = $t1->Approval();
  isnt( $apbefore->RawCount()->{'CHOCOLATE'}, $apafter->RawCount()->{'CHOCOLATE'},
    'Approval for a choice is changed by the redaction');
  my $vote2chk =$t1->BallotSet()->{'ballots'}{'VANILLA:CHOCOLATE:STRAWBERRY'};
  is_deeply( $vote2chk->{'votes'}, [ 'VANILLA'],
    'multivote ballot no longer has following votes');
  };

subtest 'single redaction' => sub {
  my $S1 = Vote::Count->new(
  BallotSet => read_ballots('t/data/biggerset1.txt'), );
  my $newBallot3 = RedactSingle(
      $S1->BallotSet(), 'VANILLA');
  my $newBallot4 = RedactSingle(
      $S1->BallotSet(), 'VOMIT');
  is_deeply(
    $newBallot3->{'ballots'}{'VOMIT:TOAD'}{'votes'},
    [ 'VOMIT', 'TOAD' ],
    'ballot that shouldnt change isnt changed'
  );
  is_deeply(
    $newBallot4->{'ballots'}{'VOMIT:TOAD'}{'votes'},
    [ 'VOMIT' ],
    'one that should change is'
  );
  is_deeply(
    $newBallot3->{'ballots'}{'VANILLA:CHOCOLATE:STRAWBERRY'}{'votes'},
    [ 'VANILLA'],
    'another that should truncate'
  );
  is_deeply(
    $newBallot3->{'ballots'}{'PISTACHIO:ROCKYROAD:MINTCHIP:VANILLA:CHOCOLATE'}{'votes'},
    [ qw/PISTACHIO ROCKYROAD MINTCHIP VANILLA/],
    'a truncation later in the vote'
  );
};

done_testing();