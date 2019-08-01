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
use Vote::Count::Redact 'RedactPair';

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


done_testing();