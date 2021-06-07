#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Warnings qw/warns warning warnings no_warnings/;

# use Test::Exception;
# use Data::Dumper;

use Path::Tiny;
use Try::Tiny;
use Storable 'dclone';

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
# use Vote::Count::Helper::BottomRunOff;

use feature qw /postderef signatures/;
no warnings 'experimental';

use Data::Printer;

my $B1 =  Vote::Count->new(
  BallotSet => read_ballots('t/data/biggerset1.txt'),
    TieBreakerFallBackPrecedence => 0 );
my $B2 = Vote::Count->new(
  BallotSet => read_ballots( 't/data/biggerset1.txt'),
  PrecedenceFile => 't/data/biggerset1precedence.txt',
  TieBreakerFallBackPrecedence => 1 );
my $Invert = Vote::Count->new(
  BallotSet => read_ballots( 't/data/tcinvertapproval.txt'),
  PrecedenceFile => 't/data/tcinvertapproval.prec.txt',
  TieBreakMethod => 'precedence' );

like(
  dies { $B1->BottomRunOff() },
  qr/TieBreakerFallBackPrecedence must be enabled/,
  "BottomRunOff dies if Precedence isnt available."
);

my $eliminate = $B2->BottomRunOff;
my $etable = qq/Elimination Runoff:
| Rank | Choice    | Votes |
|------|-----------|-------|
| 1    | RUMRAISIN | 36    |
| 2    | ROCKYROAD | 21    |
/;
is_deeply(  $B2->BottomRunOff(),
 { eliminate => 'ROCKYROAD', continuing => 'RUMRAISIN', runoff => $etable },
 'BottomRunOff picked the winner and eliminate and had the right message'
 );

note( 'Delete some of the bottom choices');
for my $eliminate ( qw( ROCKYROAD RUMRAISIN STRAWBERRY TOAD) ) {
  $B2->Defeat( $eliminate );
}
my $r = $B2->BottomRunOff(  );
is( $r->{'continuing'}, 'CARAMEL', 'check continuing after some eliminations');
is( $r->{'eliminate'}, 'SOGGYCHIPS', 'check the new eliminate too');

note( 'Delete more of the bottom choices');
for my $eliminate ( qw( CARAMEL SOGGYCHIPS CHOCOANTS VOMIT) ) {
  $B2->Defeat( $eliminate );
}

$r = $B2->BottomRunOff();
is( $r->{'continuing'}, 'CHOCOLATE', 'check continuing after more eliminations');
is( $r->{'eliminate'}, 'PISTACHIO', 'check the new loser too');

note( 'Now checking with Data where the ranking of choices is inverted between
topcount and approval!');
$r = $Invert->BottomRunOff( 'TopCount' );
is( $r->{'continuing'}, 'STRAWBERRY', 'With these choices STRAWBERRY beats');
is( $r->{'eliminate'}, 'CARAMEL', 'CARAMEL');
$r = $Invert->BottomRunOff( 'Approval' );
note( 'switching to approval changes who is at the bottom:');
is( $r->{'continuing'}, 'VANILLA', 'With approval VANILLA beats');
is( $r->{'eliminate'}, 'CHOCOLATE', 'CHOCOLATE');
note( 'now reduce to 2 choices');
$Invert->Defeat('CHOCOLATE');
$Invert->Defeat('STRAWBERRY');

subtest 'runoff with approval' => sub {
  my $r = $Invert->BottomRunOff('Approval');
  $r->{runoff} =~ /CARAMEL \| (\d+)/;
  my $caravotes = $1;
  is( $caravotes, 16, 'correct votes 16 for CARAMEL with approval');
  is( $r->{'continuing'}, 'CARAMEL', 'CARAMEL won with approval,');
  is( $r->{'eliminate'}, 'VANILLA', 'VANILLA lost with approval,');
};

note( 'now leave only one choice' );
$Invert->Defeat('VANILLA');
$r = $Invert->BottomRunOff();
is( $r->{'continuing'}, 'CARAMEL', 'only 1 choice remains, so wins runoff');
is( $r->{'eliminate'}, '', 'loser is the empty string with only 1 choice');

done_testing();
