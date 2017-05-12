#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 9;
use Test::Fatal;

use lib 't/lib';
use TestClass;

BEGIN { use_ok 'Test::Mocha' }

my $FILE = __FILE__;

my $mock = mock;
my $spy  = spy( TestClass->new );

foreach my $subj ( $mock, $spy ) {
    $subj->once;
    $subj->twice(1)   for 1 .. 2;
    $subj->thrice($_) for 1 .. 3;

    my @expect = qw(
      once()
      twice(1)
      twice(1)
      thrice(1)
      thrice(2)
      thrice(3)
    );

    my @got = inspect_all $subj;

    isa_ok( $got[0], 'Test::Mocha::MethodCall' );
    #use DDP;
    #p $subj->__calls;
    #Carp::confess;
    is( @got, scalar(@expect), 'inspect_all() returns all method calls' );
    is_deeply( \@got, \@expect, '... in the right order' );

    subtest 'argument must be a mock/spy object' => sub {
        like(
            my $e = exception { inspect_all 'string' },
            qr/^inspect_all\(\) must be given a mock or spy object/,
        );
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    };
}
