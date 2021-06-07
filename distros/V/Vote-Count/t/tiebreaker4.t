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
use Data::Dumper;

use Path::Tiny;
# use Storable 'dclone';

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

subtest 'Exceptions' => sub {

  like(
    dies {
      my $z =
        Vote::Count->new( BallotSet => read_ballots('t/data/ties1.txt'), );
      $z->UntieActive( 1, 2 );
    },
    qr/TieBreakerFallBackPrecedence/,
    "Precedence must be method or fallback to use UntieActive"
  );

  like(
    dies {
      my $z =
        Vote::Count->new( BallotSet => read_ballots('t/data/ties1.txt'), );
      $z->UnTieList( 'TopCount', 'BANANA', 'FUDGE' );
    },
    qr/TieBreakerFallBackPrecedence/,
    "Precedence must be method or fallback to use UnTieList"
  );
  like(
    dies {
      my $ties = Vote::Count->new(
        BallotSet => read_ballots('t/data/ties1.txt'), );
      $ties->PrecedenceFile('t/data/tiebreakerprecedence2.txt');
      $ties->TieBreaker( $ties->TieBreakMethod(),
        $ties->Active(), qw( FUDGESWIRL CARAMEL) );
    },
    qr/undefined tiebreak method/,
     "undefined tiebreak method is fatal when tiebreaker is called."
  );
};
done_testing;
