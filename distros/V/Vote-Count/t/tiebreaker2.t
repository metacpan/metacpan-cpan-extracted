#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
# use Test2::Tools::Exception qw/dies lives/;
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

subtest 'Precedence' => sub {
  $ties->TieBreakMethod('precedence');
  $ties->PrecedenceFile('t/data/tiebreakerprecedence1.txt');

  my @all4ties =
    qw(VANILLA CHOCOLATE STRAWBERRY PISTACHIO FUDGESWIRL ROCKYROAD MINTCHIP CARAMEL RUMRAISIN BUBBLEGUM CHERRY CHOCCHUNK);

  my $allintie = $ties->TieBreakerPrecedence(@all4ties);
  is( $allintie->{'winner'}, 'FUDGESWIRL',
    'all choices in tie chose #1 precedence choice' );
  my @mostinties =
    qw(VANILLA CHOCOLATE STRAWBERRY MINTCHIP CARAMEL RUMRAISIN BUBBLEGUM CHERRY CHOCCHUNK);
  my @mosttied =
    $ties->TieBreaker( $ties->TieBreakMethod(), $ties->Active(),
    @mostinties );
  is_deeply( \@mosttied, ['MINTCHIP'],
    'shorter choices without precedence leaders returned right choice' );
  my @tryagain = $ties->TieBreaker( $ties->TieBreakMethod(),
    $ties->Active(), qw( BUBBLEGUM CARAMEL) );
  is_deeply( \@tryagain, ['CARAMEL'],
    'shorter choices without precedence leaders returned right choice' );
};

subtest 'utility method to generate a Predictable Random Precedence File.' =>
  sub {
  unlink('/tmp/precedence.txt');
  my @prec1 = $set4->CreatePrecedenceRandom();
  my $expectprec1 =
    [qw/ YODEL RINGDING DEVILDOG KRIMPET HOHO TWINKIE SUZIEQ/];
  is_deeply( \@prec1, $expectprec1,
    'Predictable Randomized order for ballotfile majority1.txt' );
  my @readback = path('/tmp/precedence.txt')->lines({chomp=>1});
  is_deeply( \@readback, $expectprec1,
    'readback of precedence written to default /tmp/precedence.txt' );

  my ( $dst, $tmp2 ) = tempfile();
  close $dst;
  my @prec2 = Vote::Count->new( BallotSet => $ties->BallotSet )
    ->CreatePrecedenceRandom($tmp2);
  my $expectprec2 = [
    qw/BUBBLEGUM CHOCOLATE PISTACHIO CARAMEL VANILLA STRAWBERRY
      MINTCHIP RUMRAISIN FUDGESWIRL CHERRY CHOCCHUNK ROCKYROAD/
  ];
  is_deeply( \@prec2, $expectprec2,
    'Predictable Randomized order for ballotfile ties1.txt' );
  @readback = path($tmp2)->lines({chomp=>1});
  is_deeply( \@readback, $expectprec2,
    "readback of precedence written to generated $tmp2" );
  };

subtest 'TieBreakerFallBackPrecedence' => sub {
  my $ties = Vote::Count->new(
    BallotSet                    => read_ballots('t/data/ties1.txt'),
    TieBreakerFallBackPrecedence => 1,
  );
  ok( $ties->TieBreakerFallBackPrecedence(), 'fallback precedence is set' );
  is( $ties->PrecedenceFile(),
    '/tmp/precedence.txt', 'precedence file set when not provided' );
  my @thetie   = qw(PISTACHIO RUMRAISIN BUBBLEGUM);
  my $allintie = $ties->TieBreakerGrandJunction(@thetie);
  is( $allintie->{'winner'}, 'PISTACHIO',
    'GrandJunction Method goes to fallback.' );
  note('Verify fallback with the tied TWEEDLES set');
  my $tweedles =
    Vote::Count->new( BallotSet => read_ballots('t/data/tweedles.txt'), );
  $tweedles->TieBreakerFallBackPrecedence(1);
  for my $method (qw /borda topcount approval grandjunction borda_all/) {
    is(
      $tweedles->TieBreaker(
        $method, $tweedles->Active(), $tweedles->GetActiveList
      ),
      ('TWEEDLE_THREE'),
      "fallback from $method picks precedence winner"
    );
  }

  $tweedles->PrecedenceFile('t/data/tweedlesprecedence2.txt');
  # Coverage: Making sure the trigger is tested when changing precedence file.
  $tweedles->TieBreakerFallBackPrecedence(1);
  for my $method (qw /borda topcount approval grandjunction borda_all/) {
    is(
      $tweedles->TieBreaker(
        $method, $tweedles->Active(), $tweedles->GetActiveList
      ),
      ('TWEEDLE_DUM'),
      "fallback from $method picks winner with different precedence file"
    );
  }
  my $method = 'all';
  is_deeply(
    [
      $tweedles->TieBreaker(
        $method,
        {
          TWEEDLE_DEE   => 1,
          TWEEDLE_DUM   => 1,
          TWEEDLE_TWO   => 1,
          TWEEDLE_THREE => 1
        },
        $tweedles->GetActiveList()
      )
    ],
    [],
    "fallback from all returns list of choices in tie"
  );
  $method = 'none';
  is_deeply(
    [
      $tweedles->TieBreaker(
        $method,
        {
          TWEEDLE_DEE   => 1,
          TWEEDLE_DUM   => 1,
          TWEEDLE_TWO   => 1,
          TWEEDLE_THREE => 1
        },
        $tweedles->GetActiveList()
      )
    ],
    [qw/TWEEDLE_DEE TWEEDLE_DO TWEEDLE_DUM TWEEDLE_THREE TWEEDLE_TWO/],
    "fallback from all returns list of choices in tie"
  );
};

done_testing();
