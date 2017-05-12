#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/10-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::Tester;
use Test::More tests => 2 + 3 + 7*15 + 5*3;
use strict;
use warnings;

use Test::Trap qw( trap $T );
use Test::Trap qw( diag_all $T :on_fail(diag_all) );
use Test::Trap qw( diag_all_once $T :on_fail(diag_all_once) );

# Trap with warning and return
my ($prem, @t) = run_tests
  ( sub {
      my $t = trap { warn "A warning"; 5 };
      $T->return_is_deeply( [5], '5 was returned' );
      $T->warn_like( 0, qr/^A warning\b/, 'A warning was given' );
    },
  );
is( $prem, '' );
is( $#t, 1 );
is( $t[0]{ok}, 1, '->return_is_deeply [5]');
is( $t[0]{actual_ok}, 1 );
is( $t[0]{name}, '5 was returned' );
is( $t[0]{diag}, '' );
is( $t[0]{depth}, 1 );
is( $t[1]{ok}, 1, '->warn_like');
is( $t[1]{actual_ok}, 1 );
is( $t[1]{name}, 'A warning was given' );
is( $t[1]{diag}, '' );
is( $t[1]{depth}, 1 );

# Trap with silent exit
($prem, @t) = run_tests
  ( sub {
      my $t = trap { exit };
      $T->return_is_deeply( [5], '5 was returned' );
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 0, '->return_is_deeply [5]');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, '5 was returned' );
is( $t[0]{diag}, <<'EOE' );
    Expecting to return(), but instead exit()ed with 0
EOE
is( $t[0]{depth}, 1 );

# Trap with exception and diag_all
($prem, @t) = run_tests
  ( sub {
      my $t = diag_all { die "Argh\n" };
      $T->return_nok(0, 'Return with (first) false value');
      $T->exit_nok(q/Exit with (Perl's idea of a) false value/);
    },
  );
is( $prem, '' );
is( $#t, 1 );
is( $t[0]{ok}, 0, '->return_nok');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, 'Return with (first) false value' );
is( $t[0]{diag}, sprintf <<'EOE', Data::Dump::dump($T) );
    Expecting to return(), but instead die()ed with "Argh\n"
%s
EOE
is( $t[0]{depth}, 1 );
is( $t[1]{ok}, 0, '->exit_nok');
is( $t[1]{actual_ok}, 0 );
is( $t[1]{name}, q/Exit with (Perl's idea of a) false value/ );
is( $t[1]{diag}, sprintf <<'EOE', Data::Dump::dump($T) );
    Expecting to exit(), but instead die()ed with "Argh\n"
%s
EOE
is( $t[1]{depth}, 1 );

# Trap with print, exit, and diag_all
($prem, @t) = run_tests
  ( sub {
      my $t = diag_all { print "Hello world"; exit };
      $T->exit_nok('Exit with false value');
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 1, '->exit_nok');
is( $t[0]{actual_ok}, 1 );
is( $t[0]{name}, 'Exit with false value' );
is( $t[0]{diag}, '' );
is( $t[0]{depth}, 1 );

# Capture some TB version dependent stuff:
($prem, @t) = run_tests sub { isnt 5, 5 };
my $diag5isnt5 = $t[0]{diag};

# Trap with print, and exit 5, and diag_all_once
($prem, @t) = run_tests
  ( sub {
      my $t = diag_all_once { print "Hello world"; exit 5 };
      $T->exit_nok('Exit with false value');
      $T->exit_isnt(5, 'Exit with non-5 value');
    },
  );
is( $prem, '' );
is( $#t, 1 );
is( $t[0]{ok}, 0, '->exit_nok');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, 'Exit with false value' );
is( $t[0]{diag}, sprintf <<'EOE', Data::Dump::dump($T) );
    Expecting false value in exit(), but got 5 instead
%s
EOE
is( $t[0]{depth}, 1 );
is( $t[1]{ok}, 0, '->exit_isnt');
is( $t[1]{actual_ok}, 0 );
is( $t[1]{name}, 'Exit with non-5 value' );
is( $t[1]{diag}, "$diag5isnt5(as above)\n" );
is( $t[1]{depth}, 1 );

# Trap with multiple return values and diag_all_once
($prem, @t) = run_tests
  ( sub {
      my ($t) = diag_all_once { return 3..7 };
      $T->return_like( 1, qr/4/, 'return[1] matches /4/' );
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 1, '->return_like');
is( $t[0]{actual_ok}, 1 );
is( $t[0]{name}, 'return[1] matches /4/' );
is( $t[0]{diag}, '' );
is( $t[0]{depth}, 1 );

# Quiet trap, with no on-test-failure callback
($prem, @t) = run_tests
  ( sub {
      my ($t) = trap { return 3..7 };
      $T->quiet;
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 1, '->quiet');
is( $t[0]{actual_ok}, 1 );
is( $t[0]{name}, '' );
is( $t[0]{diag}, '' );
is( $t[0]{depth}, 1 );

# Warning trap with diag_all_once
($prem, @t) = run_tests
  ( sub {
      my ($t) = diag_all_once { warn "Hello!\n" };
      $T->quiet('In denial about STDERR');
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 0, '->quiet');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, 'In denial about STDERR' );
is( $t[0]{diag}, sprintf <<'EOE', Data::Dump::dump($T) );
Expecting no STDERR, but got "Hello!\n"
%s
EOE
is( $t[0]{depth}, 1 );

# Printing trap with no on-test-failure callback
($prem, @t) = run_tests
  ( sub {
      my ($t) = trap { print "Hello!\n" };
      $T->quiet('In denial about STDOUT');
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 0, '->quiet');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, 'In denial about STDOUT' );
is( $t[0]{diag}, <<'EOE' );
Expecting no STDOUT, but got "Hello!\n"
EOE
is( $t[0]{depth}, 1 );

# Noisy trap
($prem, @t) = run_tests
  ( sub {
      my ($t) = trap { warn "world!\n"; print "Hello!\n" };
      $T->quiet('In denial about noise!');
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 0, '->quiet');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, 'In denial about noise!' );
is( $t[0]{diag}, <<'EOE' );
Expecting no STDOUT, but got "Hello!\n"
Expecting no STDERR, but got "world!\n"
EOE
is( $t[0]{depth}, 1 );

# Noisy trap
($prem, @t) = run_tests
  ( sub {
      my ($t) = trap { warn "world!\n"; print "Hello!\n" };
      $T->did_return('Should return');
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 1, '->did_return');
is( $t[0]{actual_ok}, 1 );
is( $t[0]{name}, 'Should return' );
is( $t[0]{diag}, '' );
is( $t[0]{depth}, 1 );

# Exiting trap
($prem, @t) = run_tests
  ( sub {
      my ($t) = trap { exit };
      $T->did_exit('Should exit');
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 1, '->did_exit');
is( $t[0]{actual_ok}, 1 );
is( $t[0]{name}, 'Should exit' );
is( $t[0]{diag}, '' );
is( $t[0]{depth}, 1 );

# Exiting trap
($prem, @t) = run_tests
  ( sub {
      my ($t) = trap { exit };
      $T->did_die('In denial about death');
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 0, '->did_die');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, 'In denial about death' );
is( $t[0]{diag}, <<'EOE' );
    Expecting to die(), but instead exit()ed with 0
EOE
is( $t[0]{depth}, 1 );

# Exiting TODO trap
($prem, @t) = run_tests
  ( sub {
    TODO: {
	local $TODO = 'Testing TODOs';
	my ($t) = trap { exit };
	$T->did_die('In denial about death');
      }
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 1, '->did_die, TODO');
is( $t[0]{actual_ok}, 0 );
is( $t[0]{name}, 'In denial about death' );
is( $t[0]{diag}, <<'EOE' );
    Expecting to die(), but instead exit()ed with 0
EOE
is( $t[0]{depth}, 1 );
# extra 2:
is( $t[0]{type}, 'todo', 'type = todo' );
is( $t[0]{reason}, 'Testing TODOs', 'reason' );

my $really_skipped = 1;
# Exiting SKIPPED trap
($prem, @t) = run_tests
  ( sub {
    SKIP: {
	skip 'Testing SKIP', 1;
	undef $really_skipped;
	my ($t) = trap { exit };
	$T->did_die('In denial about death');
      }
    },
  );
is( $prem, '' );
is( $#t, 0 );
is( $t[0]{ok}, 1, '->did_die, SKIPPED');
is( $t[0]{actual_ok}, 1 );
is( $t[0]{name}, '' );
is( $t[0]{diag}, '' );
is( $t[0]{depth}, 1 );
# extra 3:
is( $t[0]{type}, 'skip', 'type = skip' );
is( $t[0]{reason}, 'Testing SKIP', 'reason' );
is( $really_skipped, 1, 'Asserting that SKIPPED code has not been run');
