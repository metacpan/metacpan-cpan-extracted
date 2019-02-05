#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 11;
use Test::Fatal;
use Types::Standard qw( Int slurpy );

use lib 't/lib';
use TestClass;

use ok 'Test::Mocha';

my $FILE = __FILE__;
my $mock = mock;
my $spy  = spy( TestClass->new );

foreach my $subj ( $mock, $spy ) {
    $subj->once;
    $subj->twice(1)   for 1 .. 2;
    $subj->thrice($_) for 1 .. 3;

    subtest 'inspect() returns method call' => sub {
        my @once = inspect { $subj->once };
        is( @once, 1 );
        isa_ok( $once[0], 'Test::Mocha::MethodCall' );
        is(
            $once[0]->stringify_long,
            "once() called at $FILE line 20",
            '... and method call stringifies'
        );
    };

    is_deeply( [ inspect { $subj->twice(1) } ],
        [qw( twice(1) twice(1) )],
        'inspect() with argument, returns the right method calls' );

    is_deeply(
        [ inspect { $subj->thrice(Int) } ],
        [qw( thrice(1) thrice(2) thrice(3) )],
        'inspect() with argument matcher, returns calls the right method calls, in the right order'
    );

    # ----------------------
    # inspect() with slurpy type constraint arguments

    subtest 'Disallow arguments after a slurpy type constraint' => sub {
        like(
            my $e = exception {
                inspect { $subj->twice( SlurpyArray, 1 ) };
            },
            qr/^No arguments allowed after a slurpy type constraint/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };

    subtest 'Invalid Slurpy argument' => sub {
        like(
            my $e = exception {
                inspect { $subj->twice( slurpy Int ) };
            },
            qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };
}
