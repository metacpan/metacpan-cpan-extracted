#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;

use lib 't/lib';
use TestClass;

use ok 'Test::Mocha';

my $FILE = __FILE__;

my $mock = mock;
my $spy  = spy( TestClass->new );

subtest 'calls are cleared' => sub {
    my $mock_calls = $mock->__calls;
    my $spy_calls  = $spy->__calls;

    $mock->set;
    $spy->get;
    is( ( @$mock_calls + @$spy_calls ),
        2, 'mock and spy have calls before clear()' );

    clear $mock, $spy;
    is( ( @$mock_calls + @$spy_calls ), 0, '... and no calls after clear()' );
};

# ----------------------
# exceptions

subtest 'throws if no arguments' => sub {
    like(
        my $e = exception { clear },
        qr/^clear\(\) must be given mock or spy objects/,
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};

subtest 'throws with invalid arguments' => sub {
    like(
        my $e = exception { clear 1 },
        qr/^clear\(\) accepts mock and spy objects only/,
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};
