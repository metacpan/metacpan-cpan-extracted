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

# my $json = JSON::MaybeXS->new( utf8 => 1, pretty => 1 );

use Path::Tiny;

use Vote::Count::Method::CondorcetDropping;
use Vote::Count::ReadBallots 'read_ballots';

subtest 'Plurality Loser Dropping (TopCount)' => sub {

  my $M3 = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet'     => read_ballots('t/data/biggerset1.txt'),
    'DropStyle'     => 'all',
    'DropRule'      => 'topcount',
    'SkipLoserDrop' => 1,
  );
  isa_ok(
    $M3,
    ['Vote::Count::Method::CondorcetDropping'],
    'ISA Vote::Count::Method::CondorcetDropping'
  );
  my $rM3 = $M3->RunCondorcetDropping();
  is( $rM3->{'winner'}, 'MINTCHIP', 'winner for biggerset1 topcount/all' );
  note $M3->logv();

  my $LoopSet =
    Vote::Count::Method::CondorcetDropping->new(
    'BallotSet' => read_ballots('t/data/loop1.txt'), );
  my $rLoopSet = $LoopSet->RunCondorcetDropping();
  is( $rLoopSet->{'winner'}, 'MINTCHIP',
    'loopset plurality leastwins winner' );
  note $LoopSet->logd();

  my $LoopSetA = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet' => read_ballots('t/data/loop1.txt'),
    'DropStyle' => 'all',
    'DropRule'  => 'topcount',
  );
  my $rLoopSetA = $LoopSetA->RunCondorcetDropping();
  is( $rLoopSetA->{'winner'}, 'MINTCHIP', 'loopset plurality all' );
  note $LoopSetA->logd();

  my $KnotSet =
    Vote::Count::Method::CondorcetDropping->new(
    'BallotSet' => read_ballots('t/data/knot1.txt'), );

  my $rKnotSet = $KnotSet->RunCondorcetDropping();
  is( $rKnotSet->{'winner'}, 'CHOCOLATE', 'knotset winner with defaults' );
  note $KnotSet->logd();
};

subtest 'Approval Dropping' => sub {

  note "********** LOOPSET *********";
  my $LoopSet = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet' => read_ballots('t/data/loop1.txt'),
    'DropStyle' => 'all',
    'DropRule'  => 'approval',
  );
  my $rLoopSet = $LoopSet->RunCondorcetDropping();
  is( $rLoopSet->{'winner'}, 'VANILLA', 'loopset approval all winner' );
  note $LoopSet->logd();
};

subtest 'Boorda Dropping' => sub {

  note "\n********** LOOPSET BORDA *********";
  my $LoopSetB = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet' => read_ballots('t/data/loop1.txt'),
    'DropStyle' => 'leastwins',
    'DropRule'  => 'borda',
  );
  my $rLoopSetB = $LoopSetB->RunCondorcetDropping();
  is( $rLoopSetB->{'winner'},
    'MINTCHIP', 'loopset plurality leastwins winner is the same' );
  note $LoopSetB->logd();

  note "\n********** KNOTSET BORDA *********";
  my $KnotSet = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet' => read_ballots('t/data/knot1.txt'),
    'DropStyle' => 'all',
    'DropRule'  => 'borda',
  );

  my $rKnotSet = $KnotSet->RunCondorcetDropping();
  is( $rKnotSet->{'winner'}, 'MINTCHIP', 'knotset winner with defaults' );
  note $KnotSet->logd();
};

my $BB = read_ballots('t/data/benham.txt');
subtest 'Benham' => sub {
  note(
    q/Compare Benham to Dropping with Condorcet loser dropping
  with dataset that will produce different results with the method variation./
  );
  my $B1 = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet'     => $BB,
    'DropStyle'     => 'all',
    'DropRule'      => 'topcount',
    'SkipLoserDrop' => 1,
  );
  my $rB1 = $B1->RunCondorcetDropping();
  is( $rB1->{'winner'}, 'RINGDING', 'Benham Winner' );
  like(
    $B1->logv(),
    qr/Eliminating DEVILDOG/,
    'In the Log Benham run eliminated TopCount Loser'
  );
  # note $B1->logv();
  my $B2 = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet'     => $BB,
    'DropStyle'     => 'all',
    'DropRule'      => 'topcount',
    'SkipLoserDrop' => 0,
  );
  my $rB2 = $B2->RunCondorcetDropping();
  is( $rB2->{'winner'}, 'DEVILDOG',
    'Different winner when normal Condorcet Loser dropping in effect' );
  note $B2->logv();
};

done_testing();
