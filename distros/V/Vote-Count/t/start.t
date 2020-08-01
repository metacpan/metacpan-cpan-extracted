#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;
# use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;

# use Path::Tiny;
use Vote::Count::Start;
use Vote::Count::ReadBallots 'read_ballots';
# use Vote::Count::Method::CondorcetDropping;

my $tenesseechoices = {
  CHATTANOOGA => 1,
  KNOXVILLE   => 1,
  MEMPHIS     => 1,
  NASHVILLE   => 1
};

my $Election1 = StartElection( 'BallotFile' => 't/data/tennessee.txt', );

# p $Election1;
is_deeply(
  $Election1->BallotSet()->{'choices'},
  $tenesseechoices, 'verify read of data file by StartElection with filename',
);

my $ballotset2 = read_ballots('t/data/irvtie.txt');
my $Election2  = StartElection(
  'BallotSet'  => $ballotset2,
  'FloorRule'  => 'Approval',
  'FloorValue' => 6
);

note $Election2->logv;
# p $Election;

done_testing();
