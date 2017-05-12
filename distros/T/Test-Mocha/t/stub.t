#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 46;
use Test::Fatal;
use Types::Standard qw( Any Int slurpy );

use lib 't/lib';
use MyNonThrowable;
use MyThrowable;
use TestClass;

BEGIN { use_ok 'Test::Mocha' }

# setup
my $FILE = __FILE__;
my $mock = mock;
my $spy  = spy( TestClass->new );

foreach my $subj ( $mock, $spy ) {
    # stub() argument checks
    subtest 'stub() responses must be coderefs' => sub {
        like(
            my $e = exception {
                stub { $subj->any } 1, 2, 3;
            },
            qr/^stub\(\) responses should be supplied using returns\(\), throws\(\) or executes\(\)/,
            'error is thrown'
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    subtest 'stub() coderef must contain a method call specification' => sub {
        like(
            my $e = exception { stub {} },
            qr/Coderef must have a method invoked on a mock or spy object/,
            'error is thrown'
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    subtest 'create stub that returns a scalar' => sub {
        stub { $subj->test_method(1) } returns 4;

        is( $subj->__stubs->{test_method}[0]->stringify, 'test_method(1)' );
        is( $subj->test_method(1), 4, '... and stub returns the scalar' );
        is_deeply( [ $subj->test_method(1) ],
            [4], '...or the single-element in a list' );
    };

    subtest 'create stub that returns an array' => sub {
        stub { $subj->test_method(2) } returns 1, 2, 3;

        is( $subj->__stubs->{test_method}[0]->stringify, 'test_method(2)' );
        is_deeply(
            [ $subj->test_method(2) ],
            [ 1, 2, 3 ],
            '... and stub returns the array'
        );
        is( $subj->test_method(2),
            3, '... or the array size in scalar context' );
    };

    subtest 'create stub that returns nothing' => sub {
        stub { $subj->test_method(3) } returns;

        is( $subj->__stubs->{test_method}[0]->stringify, 'test_method(3)' );
        is( $subj->test_method(3), undef, '... and stub returns undef' );
        is_deeply( [ $subj->test_method(3) ], [], '... or an empty list' );
    };

    subtest 'create stub that throws' => sub {
        stub { $subj->test_method(4) } throws 'error, ', 'stopped';

        is( $subj->__stubs->{test_method}[0]->stringify, 'test_method(4)' );

        my $e = exception { $subj->test_method(4) };
        like( $e, qr/^error, stopped at /, '... and stub does die' );
        like( $e, qr/\Q$FILE\E/, '... and error traces back to this script' );
    };

    subtest 'create stub that throws with no arguments' => sub {
        stub { $subj->test_method('4a') } throws;

        is( $subj->__stubs->{test_method}[0]->stringify, 'test_method("4a")' );

        my $e = exception { $subj->test_method('4a') };
        like( $e, qr/^ at /, '... and stub does die' );
    };

    subtest 'create stub that throws with an exception object' => sub {
        stub { $subj->test_method(5) } throws(
            MyThrowable->new('my exception'),
            qw( remaining args are ignored ),
        );
        like(
            my $e = exception { $subj->test_method(5) },
            qr/^my exception/,
            '... and the exception is thrown'
        );
      TODO: {
            # Carp BUGS section:
            # The Carp routines don't handle exception objects currently.
            # If called with a first argument that is a reference,
            # they simply call die() or warn(), as appropriate.
            local $TODO = 'Carp does not handle objects';
            like( $e, qr/\Q$FILE\E/,
                '... and error traces back to this script' );
        }
    };

    subtest 'create stub throws with a non-exception object' => sub {
        stub { $subj->test_method(6) } throws( MyNonThrowable->new );
        like( my $e = exception { $subj->test_method(6) },
            qr/^died/, '... and stub does throw' );
      TODO: {
            local $TODO = 'Carp does not handle objects';
            like(
                $e,
                qr/at \Q$FILE\E/,
                '... and error traces back to this script'
            );
        }
    };

    subtest 'create stub with no specified response' => sub {
        stub { $subj->test_method(7) };
        is( $subj->__stubs->{test_method}[0]->stringify, 'test_method(7)' );
        is( $subj->test_method(7), undef, '... and stub returns undef' );
        is_deeply( [ $subj->test_method(7) ], [], '... or an empty list' );
    };

    subtest 'stub applies to the exact name and arguments specified' => sub {
        stub { $subj->get(0) } returns 'first';
        stub { $subj->get(1) } returns 'second';

        is( $subj->get(0), 'first' );
        is( $subj->get(1), 'second' );
        is( $subj->get(2), undef );
        is( $subj->get(),  undef );
        is( $subj->get( 1, 2 ), undef );
        is( $subj->set(0), undef );
    };

    subtest 'stub response persists until it is overridden' => sub {
        stub { $subj->test_method(1) } returns 10;
        is( $subj->test_method(1), 10 ) for 1 .. 3;

        stub { $subj->test_method(1) } returns 20;
        is( $subj->test_method(1), 20 ) for 1 .. 3;
    };

    subtest 'stub can chain responses' => sub {
        stub { $subj->next } returns(1), returns(2), returns(3),
          throws('exhausted');

        is( $subj->next, 1 );
        is( $subj->next, 2 );
        is( $subj->next, 3 );
        like( exception { $subj->next }, qr/exhausted/ );
    };

    subtest 'stub() coderef may contain multiple method call specifications' =>
      sub {
        stub {
            $subj->test_method(8);
            $subj->test_method(9);
        }
        returns 1;
        is( $subj->test_method(8), 1 );
        is( $subj->test_method(9), 1 );
      };

    subtest 'stub with callback' => sub {
        my @returns = qw( first second );

        stub { $subj->get(Int) }
        executes {
            my ( $subj, $i ) = @_;
            die "index out of bounds" if $i < 0;
            return $returns[$i];
        };

        is( $subj->get(0), 'first', 'returns value' );
        is( $subj->get(1), 'second' );
        is( $subj->get(2), undef,   'no return value specified' );

        like(
            exception { $subj->get(-1) },
            qr/^index out of bounds/,
            'exception is thrown'
        );
    };

    subtest 'add a stub over an existing one' => sub {
        stub { $subj->next(SlurpyArray) } returns(1), returns(2);
        stub { $subj->next(Any) } throws 'invalid';

        like( exception { $subj->next(1) }, qr/^invalid/ );
        is( $subj->next, 1 );
    };

    subtest 'add a stub over an existing one that throws' => sub {
        stub { $subj->next(SlurpyArray) } throws('exception'), returns(2);
        stub { $subj->next(Any) } throws 'invalid';

        like( exception { $subj->next(1) }, qr/^invalid/ );
        like( exception { $subj->next },    qr/^exception/ );
    };

    stub { $subj->set(Int) } returns 'any';
    is( $subj->set(1), 'any', 'stub() accepts type constraints' );

    # ----------------------
    # stub() with slurpy type constraint

    stub { $subj->set(SlurpyArray) };
    is(
        $subj->__stubs->{set}[0],
        'set({ slurpy: ArrayRef })',
        'stub() accepts slurpy ArrayRef'
    );

    stub { $subj->set(SlurpyHash) };
    is(
        $subj->__stubs->{set}[0],
        'set({ slurpy: HashRef })',
        'stub() accepts slurpy HashRef'
    );

    subtest 'Arguments after a slurpy type constraint are not allowed' => sub {
        like(
            my $e = exception {
                stub { $subj->set( SlurpyArray, 1 ) };
            },
            qr/^No arguments allowed after a slurpy type constraint/,
            'error is thrown'
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    subtest 'Slurpy argument must be an arrayref of hashref' => sub {
        like(
            my $e = exception {
                stub { $subj->set( slurpy Any ) };
            },
            qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
            'error is thrown'
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };
}

subtest
  'stub() coderef may contain multiple method call specifications for multiple objects'
  => sub {
    stub {
        $mock->test_method(10);
        $spy->test_method(11);
    }
    returns(2), returns(1);

    is( $mock->test_method(10), 2 );
    is( $spy->test_method(11),  2 );

    is( $mock->test_method(10), 1 );
    is( $spy->test_method(11),  1 );
  };
