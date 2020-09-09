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

use Vote::Count;
use Vote::Count::Floor;
use Vote::Count::ReadBallots 'read_ballots';
use Vote::Count::Method::CondorcetVsIRV;

my $ballots_biggerset1 = read_ballots('t/data/biggerset1.txt');
my $ballots_smithirvunequal
    = read_ballots('t/data/irvdropsmithirvwinner.txt');
my $ballots_tennessee  = read_ballots('t/data/tennessee.txt');
my $ballots_burlington = read_ballots('t/data/burlington2009.txt');
my $ballots_evils      = read_ballots('t/data/evils.txt');
my $ballots_tied       = read_ballots('t/data/ties1.txt');
my $ballots_cwinner_irvtied    = read_ballots('t/data/ties2.txt');
my $ballots_twobeatirv = read_ballots('t/data/twobeatirv.txt');
my $ballots_redactfixloop = read_ballots('t/data/redactfixloop.txt');

my $ballots_drops_winner = read_ballots('t/data/irvdropscondorcetwinner.txt');
my $ballots_drops_wrong = read_ballots('t/data/irvdropswrongclone.txt');

subtest 'simple set where irv winner and condorcet match' => sub {
    my $S1 = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet' => $ballots_biggerset1,);
    my $winner1 = $S1->CondorcetVsIRV( 'simple' => 1);
    is( $winner1->{'winner'}, 'MINTCHIP', 'check the winner' );
    like(
        $S1->logt(),
        qr/Electing MINTCHIP the winner by both Condorcet and IRV/,
        'check logging for Electing ... the winner by both Condorcet and IRV'
    );
};

subtest 'case where regular irv drops smith irv IRV winner' => sub {

    my $S2 = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet' => $ballots_smithirvunequal,
    );

    my $S2smith = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_smithirvunequal,
        'TieBreakMethod' => 'grandjunction',
    );

    is( $S2->CondorcetVsIRV( 'smithsetirv' => 0, 'simple' => 1 )->{'winner'},
        'CHOCOLATE', 'The normal IRV winner.' );
    is( $S2smith->CondorcetVsIRV( 'smithsetirv' => 1 , 'simple' => 1 )->{'winner'},
        'VANILLA', 'The better IRV winner.' );
    my $S2tca = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_smithirvunequal,
        'TieBreakMethod' => 'grandjunction',
    );
    $S2tca->SetActive( $S2tca->Election()->TCA() );
    my $S2tcarun = $S2tca->CondorcetVsIRV( 'smithsetirv' => 0, 'simple' => 1 )->{'winner'};
    is( $S2tcarun, 'VANILLA',
        'apply tca floor before running with regular irv.' );

};

subtest 'condorcet winner does not violate later harm (evils)' => sub {
    my $T1 = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_evils,
        'simple' => 1,
        'TieBreakMethod' => 'none',
    );
    my $T1run1 = $T1->CondorcetVsIRV( 'smithsetirv' => 0 );
    is( $T1run1->{'winner'}, 'LESSER_EVIL', 'LESSER_EVIL is the winner.' );
};

subtest 'irv drops condorcet winner' => sub {
    my $U1 = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_drops_winner,
        'TieBreakMethod' => 'none',
    );
    my $U1run1 = $U1->CondorcetVsIRV( 'smithsetirv' => 0, 'simple' => 1 );
    is( $U1run1->{'winner'}, 'VANILLA', '? is the winner.' );
    note( $U1->logt() );
};

subtest 'irv drops wrongclone' => sub {
    my $U2 = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_drops_wrong,
        'TieBreakMethod' => 'none',
    );
    my $U2run1 = $U2->CondorcetVsIRV( 'smithsetirv' => 0, 'simple' => 1 );
    is( $U2run1->{'winner'}, 'VANILLA', '? is the winner.' );
    note( $U2->logt() );
};

subtest 'condorcet winner does violate later harm (burlington2009)' => sub {
    my $T2 = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_burlington,
        'TieBreakMethod' => 'none',
        'simple' => 1,
    );
    my $T2run1 = $T2->CondorcetVsIRV( 'smithsetirv' => 0 );
    is( $T2run1->{'winner'}, 'KISS', 'KISS is the winner.' );
    note $T2->logd();
};

subtest 
  'Edge Cases where Later votes of IRV winner change Condorcet Winner' 
  => sub {
    my $beatby2 = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_twobeatirv,
        'TieBreakMethod' => 'none',
    );
    my $fixesloop = Vote::Count::Method::CondorcetVsIRV->new(
        'BallotSet'      => $ballots_redactfixloop,
        'TieBreakMethod' => 'none',
    );
    {
    my $todo = todo "this should expose a bug";
    {
        my $winb2 = $beatby2->CondorcetVsIRV( 
            'simple' => 1, 'debug' => 1 );
        is($winb2->{'winner'}, 
            'CONDORCET1',
            "The first Condorcet winner should be the winner not the second.");
    };
        my $fixloop = $fixesloop->CondorcetVsIRV( 'simple' => 1);
        is($fixloop->{'winner'}, 
            'IRV', 
            "Because the unredacted ballots did not have a condorcet winner, the IRV winner should win.");

};

};

done_testing();
