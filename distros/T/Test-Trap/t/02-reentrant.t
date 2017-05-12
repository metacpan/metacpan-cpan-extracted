#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/02-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 1 + 6*5 + 3;
use strict;
use warnings;

BEGIN {
  use_ok( 'Test::Trap' );
}

# Inner and outer traps with  different leaveby and context:
my $x = trap {
  trap { exit };
  die unless $trap->leaveby eq 'exit';
  $trap;
};
# outer trap
is( $trap->leaveby, 'return', 'Expecting to return' );
ok( !$trap->list, 'Not list context' );
ok( $trap->scalar, 'Scalar context' );
ok( !$trap->void, 'Not void context' );
is_deeply( $trap->return, [$x], 'Returned the trapped() object' );
# inner trap
is( $x->leaveby, 'exit', 'Inner: Exited' );
ok( !$x->list, 'Inner: Not list context' );
ok( !$x->scalar, 'Inner: Not scalar context' );
ok( $x->void, 'Inner: Void context' );
is_deeply( $x->return, undef, 'Inner: "Returned" ()' );

# An inner trap localizes $trap, then successfully calls a twice-inner
# trap.  After successful exit from the once-inner trap, $trap reverts
# to its previous value:
trap {
  trap { exit };
  is( $trap->leaveby, 'exit', 'Expecting to exit' );
  ok( !$trap->list, 'Not list context' );
  ok( !$trap->scalar, 'Not scalar context' );
  ok( $trap->void, 'Void context' );
  is_deeply( $trap->return, undef, 'No return' );
  {
    local $trap;
    trap { die };
    # If the trap / local $trap breaks again, these method calls will
    # raise an exception, which we might as well catch:
    is( eval { $trap->leaveby }, 'die', 'Expecting to die' );
    ok( eval { !$trap->list }, 'Not list context' );
    ok( eval { !$trap->scalar }, 'Not scalar context' );
    ok( eval { $trap->void }, 'Void context' );
    is_deeply( eval { $trap->return }, undef, 'No return' );
  }
  is( $trap->leaveby, 'exit', 'Revert: Expecting to exit' );
  ok( !$trap->list, 'Revert: Not list context' );
  ok( !$trap->scalar, 'Revert: Not scalar context' );
  ok( $trap->void, 'Revert: Void context' );
  is_deeply( $trap->return, undef, 'No return' );
};
is( $trap->leaveby, 'return', 'Expecting to return' );
ok( !$trap->list, 'Not list context' );
ok( !$trap->scalar, 'Not scalar context' );
ok( $trap->void, 'Void context' );
is_deeply( $trap->return, [], 'Void return' );

# exit compiled to CORE::GLOBAL::exit, which is undefined at runtime ...
my $flag;
trap {
  local *CORE::GLOBAL::exit;
  trap { exit };
  is( $trap->leaveby, 'exit', 'Expecting to have exited' );
  exit; # should die!
  $flag = 1;
  END { ok( !$flag, 'Code past (dying) exit should compile, but not run' ) }
};
like( $trap->die, qr/^Undefined subroutine &CORE::GLOBAL::exit called at /, 'Dies: Undefined exit()' );
