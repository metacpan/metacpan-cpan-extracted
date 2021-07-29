#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Class;

# use Test::Exception;
# use Test2::Tools::Exception qw/dies lives/;
use File::Temp qw/tempfile tempdir/;
# use Data::Dumper;
# use Data::Printer;

use Path::Tiny;
# use Storable 'dclone';

use Vote::Count;
use Vote::Count::Charge;
use Vote::Count::ReadBallots 'read_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

my $ties = Vote::Count->new( BallotSet => read_ballots('t/data/ties1.txt'), );
my $irvtie =
  Vote::Count->new( BallotSet => read_ballots('t/data/irvtie.txt'), );
my $set4 =
  Vote::Count->new( BallotSet => read_ballots('t/data/majority1.txt') );

subtest 'Precedence as tiebreakmethod' => sub {
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
    TieBreakMethod => 'grandjunction',
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
    Vote::Count->new(
      BallotSet => read_ballots('t/data/tweedles.txt'),
      TieBreakMethod => 'grandjunction');
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
    "fallback from none returns list of choices in tie"
  );
};

subtest 'Precedence method to return RankCount Object' => sub {
  my $tweedlesP =
    [ qw/ TWEEDLE_DUM TWEEDLE_DEE TWEEDLE_TWO TWEEDLE_THREE TWEEDLE_DO/ ];
  my $tweedles =
    Vote::Count->new(
      BallotSet => read_ballots('t/data/tweedles.txt'),
      TieBreakMethod => 'Precedence',
      PrecedenceFile => 't/data/tweedlesprecedence2.txt' );
  my $R = $tweedles->Precedence();
  isa_ok( $R,
          ['Vote::Count::RankCount'],
          'Precedence Method returned RankCount Object');
  is_deeply( [$R->OrderedList()],
    $tweedlesP,
    'Precedence sorted very tied activeset by precedence');
  my $twolessactive = {
    TWEEDLE_THREE => 1, TWEEDLE_DEE => 1, TWEEDLE_DO => 1};
  $R = $tweedles->Precedence( $twolessactive );
  is_deeply( [$R->OrderedList()],
    [ qw/TWEEDLE_DEE TWEEDLE_THREE TWEEDLE_DO/],
    'Precedence sorted with passed active hash by precedence');
  $tweedlesP =
    [ qw/ TWEEDLE_DUM TWEEDLE_DEE TWEEDLE_TWO TWEEDLE_THREE/ ];
  $tweedles->SetActiveFromArrayRef( $tweedlesP);
  $R = $tweedles->precedence();
    is_deeply( [$R->OrderedList()],
    $tweedlesP,
    'removed member from active set and sorted by precedence');
};

subtest 'changing tiebreakers and generating precedence' => sub {
  my $A = Vote::Count::Charge->new(
    Seats     => 5,
    VoteValue => 100,
    BallotSet => read_ballots('t/data/data1.txt')
  );
  like(
    $A->logd(),
    qr/TieBreakMethod is undefined, setting to precedence/,
    "Vote::Count::Charge tiebreak undefined logged forced precedence."
  );
  my $B = Vote::Count->new(
    BallotSet      => read_ballots('t/data/data1.txt'),
    VoteValue      => 1000000,
    TieBreakMethod => 'grandjunction',
    PrecedenceFile => 't/data/tiebreakerprecedence1.txt',
  );
  is( $B->TieBreakMethod, 'grandjunction', 'correct tiebreaker reported' );
  is(
    $B->PrecedenceFile,
    't/data/tiebreakerprecedence1.txt',
    'correct precedencefile reported'
  );
  my $C = Vote::Count->new(
    BallotSet      => read_ballots('t/data/data1.txt'),
  );
  $C->CreatePrecedenceRandom();
  $C->TieBreakMethod( 'precedence');
  is( $C->TieBreakMethod, 'precedence', 'correct tiebreaker reported' );
  is( $C->PrecedenceFile, '/tmp/precedence.txt',
    'precedencefile set when missing' );
};


done_testing();