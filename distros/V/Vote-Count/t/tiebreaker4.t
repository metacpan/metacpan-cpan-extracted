#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies lives/;
use File::Temp qw/tempfile tempdir/;
# use Test::Exception;
use Carp;
# use Data::Dumper;
use Data::Printer;

use Path::Tiny;
# use Storable 'dclone';

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

subtest 'Exceptions' => sub {

  like(
    dies {
      my $z = Vote::Count->new(
        BallotSet      => read_ballots('t/data/ties1.txt'),
        TieBreakMethod => 'approval'
      );
      $z->UnTieActive( ranking1 => 'topcount' );
    },
    qr/TieBreakerFallBackPrecedence/,
    "Precedence must be method or fallback to use UntieActive"
  );

  like(
    dies {
      my $z =
        Vote::Count->new( BallotSet => read_ballots('t/data/ties1.txt'), );
      $z->UnTieList( ranking1 => 'TopCount', tied => [ 'BANANA', 'FUDGE' ] );
    },
    qr/TieBreakerFallBackPrecedence/,
    "Precedence must be method or fallback to use UnTieList"
  );

  like(
    dies {
      my $z = Vote::Count->new(
        BallotSet      => read_ballots('t/data/ties1.txt'),
        TieBreakMethod => 'Precedence'
      );
    },
    qr/Precedence File must be defined/,
    "Using Precedence without specifying Precedence file is fatal"
  );

  like(
    dies {
      my $ties =
        Vote::Count->new( BallotSet => read_ballots('t/data/ties1.txt'), );
      $ties->PrecedenceFile('t/data/tiebreakerprecedence2.txt');
      $ties->TieBreaker( $ties->TieBreakMethod(),
        $ties->Active(), qw( FUDGESWIRL CARAMEL) );
    },
    qr/undefined tiebreak method/,
    "undefined tiebreak method is fatal when tiebreaker is called."
  );
};

subtest 'bad untie methods' => sub {

  for my $A (
    { ranking1 => undef, test => 'missing', tested => 'ranking1 undef' },
    {
      ranking1 => 'bucklin',
      ranking2 => '',
      test     => 'bucklin',
      tested   => 'ranking1 is unavailable ranking'
    },
    {
      ranking1 => 'borda',
      ranking2 => 'bucklin',
      test     => 'bucklin',
      tested   => 'ranking2 is unavailable ranking'
    }
    )
  {
    my $z = Vote::Count->new(
      BallotSet      => read_ballots('t/data/ties1.txt'),
      PrecedenceFile => 't/data/tiebreakerprecedence1.txt',
      TieBreakMethod => 'precedence'
    );
    like(
      dies {
        $z->UnTieActive(
          ranking1 => $A->{'ranking1'},
          ranking2 => $A->{'ranking2'}
        )
      },
      qr/$A->{'test'}/,
      "Tested ${\ $A->{'tested'} } -- RegexMatch /${\ $A->{'test'} }/"
    );
  }

  for my $B (
    {
      ranking1 => 'borda',
      ranking2 => undef,
      tested   => 'ranking2 undef which should live'
    },
    )
  {
    my $z = Vote::Count->new(
      BallotSet                    => read_ballots('t/data/ties1.txt'),
      TieBreakMethod               => 'borda',
      TieBreakerFallBackPrecedence => 1
    );
    ok(
      lives {
        $z->UnTieActive(
          ranking1 => $B->{'ranking1'},
          ranking2 => $B->{'ranking2'}
        )
      },
      "Tested ${\ $B->{'tested'} }"
    );
  }
};

subtest 'test precedence with matrix and pairmatrix' => sub {
  my $t3 = Vote::Count->new(
    BallotSet                    => read_ballots('t/data/ties3.txt'),
    PrecedenceFile               => 't/data/ties3precedence.txt',
    TieBreakMethod               => 'approval',
    TieBreakerFallBackPrecedence => 0,
  );

  ok(
    !$t3->PairMatrix()->GetPairWinner( 'CHOCOLATE', 'CHERRY' ),
    'without precedence CHOCOLATE and CHERRY tie '
      . $t3->PairMatrix()->GetPairWinner( 'CHOCOLATE', 'CHERRY' )
  );
  $t3->TieBreakerFallBackPrecedence(1);
  $t3->UpdatePairMatrix();
  is( $t3->PairMatrix()->GetPairWinner( 'CHOCOLATE', 'CHERRY' ),
    'CHOCOLATE', 'with precedence fallback CHOCOLATE wins' );

  is( $t3->PairMatrix()->GetPairWinner( 'ROCKYROAD', 'RUMRAISIN' ),
    'ROCKYROAD',
    'ROCKYROAD defeats RUMRAISIN when approval is first tiebreaker' );
  $t3->TieBreakMethod('Precedence');
  $t3->UpdatePairMatrix();
  is(
    $t3->PairMatrix()->GetPairWinner( 'ROCKYROAD', 'RUMRAISIN' ),
    'RUMRAISIN',
    'RUMRAISIN will continue when the tiebreaker is changed to precedence'
  );

  my $t4 = Vote::Count->new(
    BallotSet                    => read_ballots('t/data/ties3.txt'),
    PrecedenceFile               => 't/data/ties3revprecedence.txt',
    TieBreakMethod               => 'approval',
    TieBreakerFallBackPrecedence => 1,
  );
  is(
    $t4->PairMatrix()->GetPairWinner( 'CHOCOLATE', 'CHERRY' ),
    'CHERRY',
'precedence fallback set at object creation, with reversed file: CHERRY wins'
  );
};

subtest 'code in pod' => sub {

  my $initial       = 't/data/ties3precedence.txt';
  my $ballots       = 't/data/ties3.txt';
  my $newprecedence = '/tmp/topapproveprecedence.txt';
  my %pairsthatchange = (
    'MINTCHIP' => 'VANILLA',
    'STRAWBERRY' => 'CHOCCHUNK',
    'CARAMEL' =>   'PISTACHIO',
  );
  my $Election = Vote::Count->new(
    BallotSet      => read_ballots($ballots),
    PrecedenceFile => $initial,
    TieBreakMethod => 'Precedence',
  );
  while ( my ( $win1, $win2 ) = each %pairsthatchange ) {
    is(
      $Election->PairMatrix()->GetPairWinner( $win2, $win1 ),
      $win1,
"Check pairings decided by Precedence in inital Matrix $win1 > $win2"
    );
  }

  my @newbreaker = $Election->UnTieActive(
    'ranking1' => 'TopCount',
    'ranking2' => 'Approval'
  );
  local $" = ' > ';    # set list separator to >
  $Election->logv("Setting Tie Break Order to: @newbreaker");
  # note "@newbreaker";
  local $" = "\n";     # set list separator to new line.
  path($newprecedence)->spew("@newbreaker");
  $Election->PrecedenceFile($newprecedence);
  $Election->UpdatePairMatrix();
### Testing that it ran
  is_deeply(
    [ $Election->Precedence()->OrderedList ],
    [
      qw/FUDGESWIRL VANILLA MINTCHIP ROCKYROAD RUMRAISIN PISTACHIO CHOCCHUNK BUBBLEGUM CHOCOLATE CHERRY STRAWBERRY CARAMEL /
    ],
    'Setting TopCount Approval Precdence has new Precedence order'
  );
  while ( my ( $win1, $win2 ) = each %pairsthatchange ) {
    is(
      $Election->PairMatrix()->GetPairWinner( $win2, $win1 ),
      $win2,
"Check pairings decided by Precedence changed with precedence file $win2 > $win1"
    );
  }

  # note $Election->PairMatrix()->PairingVotesTable;

};

done_testing;
