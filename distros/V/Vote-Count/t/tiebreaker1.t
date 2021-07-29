#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use File::Temp qw/tempfile tempdir/;
# use Data::Dumper;

use Path::Tiny;
# use Storable 'dclone';

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

my $ties = Vote::Count->new( BallotSet => read_ballots('t/data/ties1.txt'), );
my $irvtie =
  Vote::Count->new( BallotSet => read_ballots('t/data/irvtie.txt'), );
my $set4 =
  Vote::Count->new( BallotSet => read_ballots('t/data/majority1.txt') );

subtest 'Modified GrandJunction TieBreaker' => sub {

  my @all4ties =
    qw(VANILLA CHOCOLATE STRAWBERRY FUDGESWIRL PISTACHIO ROCKYROAD MINTCHIP CARAMEL RUMRAISIN BUBBLEGUM CHERRY CHOCCHUNK);
  my $allintie = $ties->TieBreakerGrandJunction(@all4ties);
  is( $allintie->{'winner'}, 0, 'tiebreaker with no winner returned 0' );
  is( $allintie->{'tie'},    1, 'tiebreaker with no winner tie is true' );
  is_deeply(
    $allintie->{'tied'},
    [ 'FUDGESWIRL', 'VANILLA' ],
'tiebreaker (multi tie) with no winner tied contains remaining tied choices'
  );

  is( $irvtie->TieBreakerGrandJunction(qw/ VANILLA CHOCOLATE /)->{'winner'},
    'VANILLA', 'check winner of a tie break vanilla' );
  my $textrsltB = $irvtie->logd();
  like( $textrsltB, qr/CHOCOLATE: 31/, 'from log chocolate had 31 votes.' );
  like( $textrsltB, qr/VANILLA: 40/,   'from log vanilla had 40 votes.' );
  is( $irvtie->TieBreakerGrandJunction(qw/  CARAMEL RUMRAISIN /)->{'winner'},
    'RUMRAISIN', 'RUMRAISIN check winner of a tie break ' );
  is(
    $irvtie->TieBreakerGrandJunction(qw/  STRAWBERRY PISTACHIO ROCKYROAD /)
      ->{'winner'},
    'PISTACHIO', 'PISTACHIO check winner of a tie break'
  );

  my $s4 = $set4->TieBreakerGrandJunction( 'SUZIEQ', 'YODEL' );
  is( $s4->{'winner'}, 'SUZIEQ', 'a tiebreaker that went down 3 levels' );
};

subtest 'object tiebreakers' => sub {
  my $active = {
    PISTACHIO => 1,
    ROCKYROAD => 1,
    CHOCOLATE => 1,
    VANILLA   => 1,
  };
  my $I5 = Vote::Count->new( BallotSet => read_ballots('t/data/irvtie.txt') );
  my @resolve1 =
    sort $I5->TieBreaker( 'none', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply(
    \@resolve1,
    [ 'CHOCOLATE', 'VANILLA' ],
    'none returns both tied choices'
  );
  my @resolve2 =
    sort $I5->TieBreaker( 'borda', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply( \@resolve2, ['CHOCOLATE'], 'Borda returns choice that won' );
  my @resolve3 =
    sort $I5->TieBreaker( 'borda_all', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply( \@resolve3, ['VANILLA'],
'borda_all returns choice that won (different winner than borda on active!)'
  );
  my @resolve4 =
    sort $I5->TieBreaker( 'Approval', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is_deeply(
    \@resolve4,
    [ 'CHOCOLATE', 'VANILLA' ],
    'approval returns a tie for the top2'
  );
  my @resolve5 =
    sort $I5->TieBreaker( 'approval', $active, ( 'VANILLA', 'ROCKYROAD' ) );
  is_deeply( \@resolve5, ['VANILLA'], 'approval winner for a non-tied pair' );

  my @resolve6 = sort $I5->TieBreaker( 'grandjunction', $active,
    ( 'VANILLA', 'ROCKYROAD' ) );
  is_deeply( \@resolve6, ['VANILLA'], 'modified grand junction' );

  my @resolve7 =
    $I5->TieBreaker( 'all', $active, ( 'VANILLA', 'ROCKYROAD' ) );
  is( @resolve7, 0, 'all returns an empty array.' );

  my @resolve8 =
    $I5->TieBreaker( 'topcount_active', $active, ( 'VANILLA', 'ROCKYROAD' ) );
  is_deeply( \@resolve8, ['VANILLA'], 'topcount_active' );
  my @resolve9 =
    $I5->TieBreaker( 'topcount_active', $active, ( 'VANILLA', 'CHOCOLATE' ) );
  is( @resolve9, 2, 'topcount_active with choices that tie returns both' );
};

done_testing();
