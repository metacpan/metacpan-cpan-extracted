#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;
# use JSON::MaybeXS;
# use YAML::XS;
use feature qw /postderef signatures/;

# my $json = JSON::MaybeXS->new( utf8 => 1, pretty => 1 );

use Path::Tiny;

use Vote::Count;
use Vote::Count::Floor;
use Vote::Count::ReadBallots 'read_ballots';
use Vote::Count::Method::CondorcetVsIRV;

my $ballots_biggerset1 = read_ballots('t/data/biggerset1.txt');
my $ballots_smithirvunequal = read_ballots('t/data/irvdropsmithirvwinner.txt');
my $ballots_tennessee = read_ballots('t/data/tennessee.txt');
my $ballots_burlington = read_ballots('t/data/burlington2009.txt');
my $ballots_evils = read_ballots('t/data/evils.txt');


subtest 'simple set where irv winner and condorcet match' => sub {
  my $S1 =
  Vote::Count::Method::CondorcetVsIRV->new(
    'BallotSet' => $ballots_biggerset1,
  );
  my $winner1 =  $S1->CondorcetVsIRV() ;
  is( $winner1->{'winner'}, 'MINTCHIP', 'check the winner');
  like( 
    $S1->logt(), 
    qr/Electing MINTCHIP the winner by both Condorcet and IRV/,
    'check logging for Electing ... the winner by both Condorcet and IRV'
    );
};


subtest 'case where regular irv drops smith irv IRV winner' => sub {

  my $smithirvunequal = read_ballots('t/data/irvdropsmithirvwinner.txt');

  my $S2 =
    Vote::Count::Method::CondorcetVsIRV->new(
      'BallotSet' => $ballots_smithirvunequal,
    );

  my $S2smith =
    Vote::Count::Method::CondorcetVsIRV->new(
      'BallotSet' => $ballots_smithirvunequal,
      'TieBreakMethod' => 'grandjunction',
    );

  is(
    $S2->CondorcetVsIRV( 'smithsetirv' => 0 )->{'winner'},
    'CHOCOLATE',
    'The normal IRV winner.'
    );
  is(
    $S2smith->CondorcetVsIRV( 'smithsetirv' => 1 )->{'winner'},
    'VANILLA',
    'The better IRV winner.'
    );

  # note( '*'x60 . "\n" . '*'x60);
  # note $S2smith->logv();
  # $S2smith->Election()->WriteLog();

  my $S2tca = Vote::Count::Method::CondorcetVsIRV->new(
      'BallotSet' => $ballots_smithirvunequal,
      'TieBreakMethod' => 'grandjunction',
    );
  $S2tca->SetActive( $S2tca->Election()->TCA() ) ;
  my $S2tcarun = $S2tca->CondorcetVsIRV( 'smithsetirv' => 0 )->{'winner'};
  is( $S2tcarun, 'VANILLA', 'apply tca floor before running with regular irv.');

};

subtest 'condorcet winner does not violate later harm (evils)' =>
 sub {

  # note( '*'x60 . "\n" . '*'x60);

  my $T1 = Vote::Count::Method::CondorcetVsIRV->new(
      'BallotSet' => $ballots_evils,
      'TieBreakMethod' => 'none',
    );
  my $T1run1 = $T1->CondorcetVsIRV( 'smithsetirv' => 0 );
  is( $T1run1->{'winner'}, 'LESSER_EVIL', 'LESSER_EVIL is the winner.');
  # note $T1->logd();
  # note $T1->Election()->logt();

 #  my $T1 = Vote::Count::Method::CondorcetVsIRV->new(
 #      'BallotSet' => $ballots_tennessee,
 #      'TieBreakMethod' => 'none',
 #    );
 #  my $T1run1 = $T1->CondorcetVsIRV( 'smithsetirv' => 0 );
 #  is( $T1run1, 'NASHVILLE', 'NASHVILLE is the winner.');
 #  note $T1->logt();
};

subtest 'condorcet winner does violate later harm (burlington2009)' =>
 sub {

  # note( '*'x60 . "\n" . '*'x60);
  my $T2 = Vote::Count::Method::CondorcetVsIRV->new(
      'BallotSet' => $ballots_burlington,
      'TieBreakMethod' => 'none',
    );
  my $T2run1 = $T2->CondorcetVsIRV( 'smithsetirv' => 0 );
  is( $T2run1->{'winner'}, 'KISS', 'KISS is the winner.');
  note $T2->logd();
 };

subtest 'test relaxed' => sub {

  my $T1 = Vote::Count::Method::CondorcetVsIRV->new(
      'BallotSet' => $ballots_tennessee,
      'TieBreakMethod' => 'none',
    );
  my $T1run1 = $T1->CondorcetVsIRV( 'smithsetirv' => 0, 'relaxed' => 1 );
  is( $T1run1->{'winner'}, 'NASHVILLE', 'NASHVILLE is the winner.');
  note $T1->logt();
  $T1->WriteAllLogs();

  # note( '*'x60 . "\n" . '*'x60);
  my $T2 = Vote::Count::Method::CondorcetVsIRV->new(
      'BallotSet' => $ballots_burlington,
      'TieBreakMethod' => 'none',
      # 'relaxed' => 1,
    );
  my $T2run1 = $T2->CondorcetVsIRV( 'smithsetirv' => 0, 'relaxed' => 1 );
  is( $T2run1->{'winner'}, 'KISS', 'KISS is the winner.');

ok 1;
};



done_testing();