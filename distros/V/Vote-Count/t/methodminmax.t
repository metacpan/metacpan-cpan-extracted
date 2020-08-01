#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Dumper;
# use JSON::MaybeXS;
# use YAML::XS;
use feature qw /postderef signatures/;

use Path::Tiny;

use Vote::Count::Method::CondorcetDropping;
use Vote::Count::Method::MinMax;
use Vote::Count::ReadBallots 'read_ballots';

subtest '_scorewinningvotes' => sub {
  my $swv = Vote::Count::Method::MinMax->new(
    'BallotSet' => read_ballots('t/data/loop1.txt'),
  );
  note( Dumper $swv->PairingVotesTable() );
  ok 1;
};


# subtest 'Approval Dropping' => sub {

#   note "********** LOOPSET *********";
#   my $LoopSet = Vote::Count::Method::CondorcetDropping->new(
#     'BallotSet' => read_ballots('t/data/loop1.txt'),
#     'DropStyle' => 'all',
#     'DropRule'  => 'approval',
#   );
#   my $rLoopSet = $LoopSet->RunCondorcetDropping();
#   is( $rLoopSet->{'winner'}, 'VANILLA', 'loopset approval all winner' );
#   note $LoopSet->logd();
# };

done_testing();