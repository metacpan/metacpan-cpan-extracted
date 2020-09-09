#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use feature qw /postderef signatures/;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';
use Vote::Count::Method::CondorcetIRV;

my $S1 = Vote::Count::Method::CondorcetIRV->new(
  'BallotSet' => read_ballots('t/data/biggerset1.txt'),
   'TieBreakMethod' => 'grandjunction'
);

my $winner1 = $S1->SmithSetIRV();
is( $winner1->{'winner'}, 'MINTCHIP', 'simple set with condorcet winner' );
note $S1->logt;

my $S2 = Vote::Count::Method::CondorcetIRV->new(
  'BallotSet' => read_ballots('t/data/loop1.txt'),
);

my $winner2 = $S2->SmithSetIRV();
is( $winner2->{'winner'}, 'MINTCHIP', 'set with no condorcet winner' );
note $S2->logt;

my $S3 = Vote::Count::Method::CondorcetIRV->new(
  'BallotSet' => read_ballots('t/data/ties1.txt'),
);

my $result3 = $S3->SmithSetIRV();
is( $result3->{'winner'}, 0,
  'set that ends with a tie returns a false value winner' );
# my $tiechoices = { 'FUDGESWIRL', 1,'VANILLA',1};
is_deeply(
  $result3->{'tied'},
  [ 'FUDGESWIRL', 'VANILLA' ],
  'tied choices in $result->{tied}'
);
note $S3->logv;

subtest 'synpsis' => sub {
  my $someballotset = read_ballots('t/data/biggerset1.txt');

  my $SmithIRV = Vote::Count::Method::CondorcetIRV->new(
    'BallotSet' => $someballotset,
  );
  my $result = $SmithIRV->SmithSetIRV() ;
  say "Winner is: " . $result->{'winner'};
  is( $result->{'winner'}, 'MINTCHIP' );

};

done_testing();