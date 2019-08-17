#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
use Data::Printer;
# use Data::Dumper;

use Path::Tiny;
# use Storable 'dclone';

use Vote::Count 0.020;
use Vote::Count::ReadBallots 'read_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

my $ties = Vote::Count->new(
  BallotSet => read_ballots('t/data/ties1.txt'), );
# my $knot = Vote::Count->new(
#   BallotSet => read_ballots('t/data/knot1.txt'), );
my $irvtie = Vote::Count->new(
  BallotSet => read_ballots('t/data/irvtie.txt'), );
# my $brexit = Vote::Count->new(
#   BallotSet => read_ballots('t/data/brexit1.txt'), );
my $set4 = Vote::Count->new(
  BallotSet => read_ballots('t/data/majority1.txt') );

subtest 'Modified GrandJunction TieBreaker' => sub {

  my @all4ties = qw(VANILLA CHOCOLATE STRAWBERRY FUDGESWIRL PISTACHIO ROCKYROAD MINTCHIP CARAMEL RUMRAISIN BUBBLEGUM CHERRY CHOCCHUNK);
  my $allintie = $ties->TieBreakerGrandJunction( @all4ties);
  is( $allintie->{'winner'}, 0, 'tiebreaker with no winner returned 0');
  is( $allintie->{'tie'}, 1, 'tiebreaker with no winner tie is true');
  is_deeply( $allintie->{'tied'}, [ 'FUDGESWIRL', 'VANILLA' ],
    'tiebreaker (multi tie) with no winner tied contains remaining tied choices');

  is ( $irvtie->TieBreakerGrandJunction( qw/ VANILLA CHOCOLATE /)->{'winner'},
    'VANILLA', 'check winner of a tie break vanilla');
  my $textrsltB = $irvtie->logd();
  like( $textrsltB, qr/CHOCOLATE: 31/, 'from log chocolate had 31 votes.' );
  like( $textrsltB, qr/VANILLA: 40/, 'from log vanilla had 40 votes.' );
  is ( $irvtie->TieBreakerGrandJunction( qw/  CARAMEL RUMRAISIN /)->{'winner'},
    'RUMRAISIN', 'RUMRAISIN check winner of a tie break ');
  is ( $irvtie->TieBreakerGrandJunction( qw/  STRAWBERRY PISTACHIO ROCKYROAD /)->{'winner'},
    'PISTACHIO', 'PISTACHIO check winner of a tie break');

  my $s4 = $set4->TieBreakerGrandJunction( 'SUZIEQ', 'YODEL' );
  is ( $s4->{'winner'}, 'SUZIEQ', 'a tiebreaker that went down 3 levels');
};

done_testing();
=pod
