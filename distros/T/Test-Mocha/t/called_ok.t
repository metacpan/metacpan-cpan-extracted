#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More 0.99 tests => 64;
use Test::Fatal;
use Test::Builder::Tester;
use Types::Standard qw( Any slurpy );

use lib 't/lib';
use TestClass;

BEGIN { use_ok 'Test::Mocha' }

my $FILE = __FILE__;

my $mock = mock;
my $spy  = spy( TestClass->new );

foreach my $subj ( $mock, $spy ) {
    subtest 'diagnostics with no method call history' => sub {
        my $test_name = 'test_method() was called 1 time(s)';
        my $line      = __LINE__ + 14;

        chomp( my $err = <<"ERR" );
#   Failed test '$test_name'
    #   at $FILE line $line.
    # Error: unexpected number of calls to 'test_method()'
    #          got: 0 time(s)
    #     expected: 1 time(s)
    # Complete method call history (most recent call last):
    #     (No methods were called)
ERR

        test_out("not ok 1 - $test_name");
        test_err($err);
        called_ok { $subj->test_method };
        test_test();
    };

    {
        $subj->once;
        $subj->twice() for 1 .. 2;
        $subj->thrice($_) for 1 .. 3;
    }
    chomp( my $diag_call_history = <<"END" );
    # Complete method call history (most recent call last):
    #     once() called at $FILE line 43
    #     twice() called at $FILE line 44
    #     twice() called at $FILE line 44
    #     thrice(1) called at $FILE line 45
    #     thrice(2) called at $FILE line 45
    #     thrice(3) called at $FILE line 45
END

    # -----------------
    # simple called_ok() (with no times() specified)

    subtest 'simple called_ok() that passes' => sub {
        test_out('ok 1 - once() was called 1 time(s)');
        called_ok { $subj->once };
        test_test();
    };

    subtest 'simple called_ok() that fails' => sub {
        my $test_name = 'test_method() was called 1 time(s)';
        my $line      = __LINE__ + 13;

        chomp( my $err = <<"ERR" );
#   Failed test '$test_name'
    #   at $FILE line $line.
    # Error: unexpected number of calls to 'test_method()'
    #          got: 0 time(s)
    #     expected: 1 time(s)
$diag_call_history
ERR

        test_out("not ok 1 - $test_name");
        test_err($err);
        called_ok { $subj->test_method };
        test_test();
    };

    subtest 'simple called_ok() with a test name' => sub {
        my $test_name = 'once() was called once';
        test_out("ok 1 - $test_name");
        called_ok { $subj->once } $test_name;
        test_test();
    };

    # -----------------
    # called_ok() with times()
    subtest 'called_ok() with times() that passes' => sub {
        test_out('ok 1 - twice() was called 2 time(s)');
        called_ok { $subj->twice } &times(2);
        test_test();
    };

    subtest 'called_ok() with times() that fails' => sub {
        my $test_name = 'twice() was called 1 time(s)';
        my $line      = __LINE__ + 13;

        chomp( my $err = <<"ERR" );
#   Failed test '$test_name'
    #   at $FILE line $line.
    # Error: unexpected number of calls to 'twice()'
    #          got: 2 time(s)
    #     expected: 1 time(s)
$diag_call_history
ERR

        test_out("not ok 1 - $test_name");
        test_err($err);
        called_ok { $subj->twice } &times(1);
        test_test();
    };

    subtest 'called_ok with invalid times() value' => sub {
        like(
            my $e = exception {
                called_ok { $subj->once } &times('string');
            },
            qr/^times\(\) must be given a number/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    # -----------------
    # called_ok() with atleast()

    subtest 'called_ok() with atleast() that passes' => sub {
        test_out('ok 1 - once() was called at least 1 time(s)');
        called_ok { $subj->once } atleast(1);
        test_test();
    };

    subtest 'called_ok() with atleast() that fails' => sub {
        my $test_name = 'once() was called at least 2 time(s)';
        my $line      = __LINE__ + 13;

        chomp( my $err = <<"ERR" );
#   Failed test '$test_name'
    #   at $FILE line $line.
    # Error: unexpected number of calls to 'once()'
    #          got: 1 time(s)
    #     expected: at least 2 time(s)
$diag_call_history
ERR

        test_out("not ok 1 - $test_name");
        test_err($err);
        called_ok { $subj->once } atleast(2);
        test_test();
    };

    subtest 'called_ok() with invalid atleast() value' => sub {
        like(
            my $e = exception {
                called_ok { $subj->twice } atleast('once');
            },
            qr/^atleast\(\) must be given a number/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    # -----------------
    # called_ok() with atmost()

    subtest 'called_ok() with atmost() that passes' => sub {
        test_out('ok 1 - twice() was called at most 2 time(s)');
        called_ok { $subj->twice } atmost(2);
        test_test();
    };

    subtest 'called_ok() with atmost() that fails' => sub {
        my $test_name = 'twice() was called at most 1 time(s)';
        my $line      = __LINE__ + 13;

        chomp( my $err = <<"ERR" );
#   Failed test '$test_name'
    #   at $FILE line $line.
    # Error: unexpected number of calls to 'twice()'
    #          got: 2 time(s)
    #     expected: at most 1 time(s)
$diag_call_history
ERR

        test_out("not ok 1 - $test_name");
        test_err($err);
        called_ok { $subj->twice } atmost(1);
        test_test();
    };

    subtest 'called_ok() with invalid atmost() value' => sub {
        like(
            my $e = exception {
                called_ok { $subj->twice } atmost('thrice');
            },
            qr/^atmost\(\) must be given a number/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };
    # -----------------
    # called_ok() with between()

    subtest 'called_ok() with between() that passes (lower boundary)' => sub {
        test_out('ok 1 - twice() was called between 1 and 2 time(s)');
        called_ok { $subj->twice } between( 1, 2 );
        test_test();
    };

    subtest 'called_ok() with between() that passes (upper boundary)' => sub {
        test_out('ok 1 - twice() was called between 2 and 3 time(s)');
        called_ok { $subj->twice } between( 2, 3 );
        test_test();
    };

    subtest 'called_ok() with between() that fails (lower boundary)' => sub {
        my $test_name = 'twice() was called between 0 and 1 time(s)';
        my $line      = __LINE__ + 13;

        chomp( my $err = <<"ERR" );
#   Failed test '$test_name'
    #   at $FILE line $line.
    # Error: unexpected number of calls to 'twice()'
    #          got: 2 time(s)
    #     expected: between 0 and 1 time(s)
$diag_call_history
ERR

        test_out("not ok 1 - $test_name");
        test_err($err);
        called_ok { $subj->twice } between( 0, 1 );
        test_test();
    };

    subtest 'called_ok() with between() that fails (upper boundary)' => sub {
        my $test_name = 'twice() was called between 3 and 4 time(s)';
        my $line      = __LINE__ + 13;

        chomp( my $err = <<"ERR" );
#   Failed test '$test_name'
    #   at $FILE line $line.
    # Error: unexpected number of calls to 'twice()'
    #          got: 2 time(s)
    #     expected: between 3 and 4 time(s)
$diag_call_history
ERR

        test_out("not ok 1 - $test_name");
        test_err($err);
        called_ok { $subj->twice } between( 3, 4 );
        test_test();
    };

    subtest
      'called_ok() with invalid between() value (pair are not numbers)' => sub {
        like(
            exception {
                called_ok { $subj->twice } between( 'one', 'two' );
            },
            qr/between\(\) must be given 2 numbers in ascending order/,
        );
      };

    subtest 'called_ok() with invalid between() value (pair not ordered)' =>
      sub {
        like(
            my $e = exception {
                called_ok { $subj->twice } between( 2, 1 );
            },
            qr/between\(\) must be given 2 numbers in ascending order/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
      };

    # -----------------
    # called_ok() with an option AND a name

    subtest 'called_ok() with times() and a name' => sub {
        my $test_name = 'name for my test';
        test_out("ok 1 - $test_name");
        called_ok { $subj->once } &times(1), $test_name;
        test_test();
    };

    subtest 'called_ok() with atleast() and a name' => sub {
        my $test_name = 'name for my test';
        test_out("ok 1 - $test_name");
        called_ok { $subj->once } atleast(1), $test_name;
        test_test();
    };

    subtest 'called_ok() with atmost() and a name' => sub {
        my $test_name = 'name for my test';
        test_out("ok 1 - $test_name");
        called_ok { $subj->twice } atmost(2), $test_name;
        test_test();
    };

    subtest 'called_ok() with between() and a name' => sub {
        my $test_name = 'name for my test';
        test_out("ok 1 - $test_name");
        called_ok { $subj->twice } between( 1, 2 ), $test_name;
        test_test();
    };

    subtest 'called_ok() with multiple method calls to verify' => sub {
        my $test_name = 'multiple 1';
        test_out("ok 1 - $test_name\n    ok 2 - $test_name");
        called_ok { $subj->once; $subj->twice } between( 1, 2 ), $test_name;
        test_test();
    };

    # -----------------
    # called_ok() with type constraint arguments

    subtest 'called_ok() accepts type constraints' => sub {
        test_out('ok 1 - thrice(Any) was called 3 time(s)');
        called_ok { $subj->thrice(Any) } &times(3);
        test_test();
    };

    subtest 'Disallow arguments after a slurpy type constraint' => sub {
        like(
            my $e = exception {
                called_ok { $subj->thrice( SlurpyArray, 1 ) };
            },
            qr/^No arguments allowed after a slurpy type constraint/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    # to complete test coverage - once() has no arguments
    subtest 'Disallow arguments after a slurpy type constraint' => sub {
        like(
            my $e = exception {
                called_ok { $subj->once( SlurpyArray, 1 ) };
            },
            qr/^No arguments allowed after a slurpy type constraint/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    subtest 'Invalid Slurpy argument for called_ok()' => sub {
        like(
            my $e = exception {
                called_ok { $subj->thrice( slurpy Any ) };
            },
            qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    # -----------------
    # conditional verifications - verify that failure diagnostics are not output

    subtest 'called_ok() in a TODO block' => sub {
        my $test_name = 'test_method() was called 1 time(s)';
        my $line      = __LINE__ + 10;

        chomp( my $out = <<"OUT" );
not ok 1 - $test_name # TODO should fail
    #   Failed (TODO) test '$test_name'
    #   at $FILE line $line.
OUT
        test_out($out);
      TODO: {
            local $TODO = "should fail";
            called_ok { $subj->test_method };
        }
        test_test();
    };

    subtest 'called_ok() in a SKIP block' => sub {
        my $test_name = "a verification in skip block";
        test_out("ok 1 # skip $test_name");
      SKIP: {
            skip $test_name, 1;
            called_ok { $subj->test_method };
        }
        test_test();
    };

    subtest 'called_ok() in a TODO_SKIP block' => sub {
        my $test_name = "a verification in todo_skip block";
        test_out("not ok 1 # TODO & SKIP $test_name");
      TODO: {
            todo_skip $test_name, 1;
            called_ok { $subj->method_not_called };
        }
        test_test();
    };
}

subtest
  'called_ok() with multiple method calls from multiple objects to verify' =>
  sub {
    my $test_name = 'multiple 2';
    test_out("ok 1 - $test_name\n    ok 2 - $test_name\n    ok 3 - $test_name");
    called_ok {
        $mock->once;
        $mock->twice;
        $spy->twice;
    }
    between( 1, 2 ), $test_name;
    test_test();
  };
