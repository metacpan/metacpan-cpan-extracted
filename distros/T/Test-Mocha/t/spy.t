#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 19;
use Test::Fatal;
#use Scalar::Util qw( blessed );

use lib 't/lib';
use TestClass;

BEGIN { use_ok 'Test::Mocha' }

my $FILE = __FILE__;

# ----------------------
# creating a spy

my $obj = TestClass->new;
my $spy = spy($obj);
ok( $spy, 'spy($obj) creates a simple spy' );
is( $spy->__object, $obj, 'spy wraps object' );

subtest 'spy() must be given a blessed object' => sub {
    like(
        my $e = exception { spy(1) },
        qr{^Can't spy on an unblessed reference},
        'error is thrown'
    );
    like( $e, qr{at \Q$FILE\E}, '... and error traces back to this file' );
};

# ----------------------
# spy acts as a wrapper to the real object

ok( $spy->isa('TestClass'),  'spy isa(TestClass)' );
ok( $spy->does('TestClass'), 'spy does(TestClass)' );
ok( $spy->DOES('TestClass'), 'spy DOES(TestClass)' );

is( ref($spy), 'TestClass', 'ref(spy)' );
#iis( blessed($spy), 'TestClass' );

ok( !$spy->isa('Foo'),  'spy does not isa(Anything)' );
ok( !$spy->does('Bar'), 'spy does not does(Anything)' );
ok( !$spy->DOES('Baz'), 'spy does not DOES(Anything)' );

# ----------------------
# spy delegates method calls to the real object

is( $spy->test_method( bar => 1 ),
    'bar', 'spy accepts methods that it can delegate' );

subtest 'spy can(test_method)' => sub {
    ok( my $coderef = $spy->can('test_method'), 'can() returns positively' );
    is( ref($coderef), 'CODE', '... and return value is a coderef' );
    is( $coderef->( $spy, 5 ),
        5, '... and coderef delegates method call by default' );
    my $line = __LINE__ - 2;
    is(
        $spy->__calls->[-1]->stringify_long,
        qq{test_method(5) called at $FILE line $line},
        '... and method call is recorded'
    );
};

subtest 'spy does not can(any_method)' => sub {
    is( $spy->can('foo'), undef, 'can() returns undef' );
    my $line = __LINE__ - 1;
    is(
        $spy->__calls->[-1]->stringify_long,
        qq{can("foo") called at $FILE line $line},
        '... and method call is recorded'
    );
};

# ----------------------
# spy doesn't handle method calls it can't handle

subtest 'spy does not accept calls to methods it cannot delegate' => sub {
    like(
        my $e = exception { $spy->foo( bar => 1 ) },
        qr{^Can't call object method "foo" because it can't be located via package "TestClass"},
        'error is thrown'
    );
    like( $e, qr{at \Q$FILE\E}, '... and error traces back to this file' );
};

subtest 'spy does not accept stubs to methods it cannot delegate' => sub {
    like(
        my $e = exception {
            stub { $spy->foo( bar => 1 ) } returns 1
        },
        qr{^Can't stub object method "foo" because it can't be located via package "TestClass"},
        'error is thrown'
    );
    like( $e, qr{at \Q$FILE\E}, '... and error traces back to this file' );
};

subtest 'spy does not verify methods it cannot delegate' => sub {
    like(
        my $e = exception {
            called_ok { $spy->foo( bar => 1 ) };
        },
        qr{^Can't verify object method "foo" because it can't be located via package "TestClass"},
        'error is thrown'
    );
    like( $e, qr{at \Q$FILE\E}, '... and error traces back to this file' );
};

subtest 'spy does not inspect methods it cannot delegate' => sub {
    like(
        my $e = exception {
            inspect { $spy->foo( bar => 1 ) };
        },
        qr{^Can't inspect object method "foo" because it can't be located via package "TestClass"},
        'error is thrown'
    );
    like( $e, qr{at \Q$FILE\E}, '... and error traces back to this file' );
};

$spy->DESTROY;
isnt( $spy->__calls->[-1]->stringify,
    'DESTROY()', 'DESTROY() is not AUTOLOADed' );
