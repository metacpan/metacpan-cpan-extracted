#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Future::IO;

my $test_fio = Test::Future::IO->controller;

# pass
{
   test_out q[ok 1 - Future::IO->syswrite consumes data];
   test_out q[# Subtest: ->syswrite];
   test_out q[    ok 1 - ->syswrite(ignore(), 'Hello')];
   test_out q[    1..1];
   test_out q[ok 2 - ->syswrite];

   $test_fio->expect_syswrite_anyfh( "Hello" );

   is( Future::IO->syswrite( "dummyFH", "Hello" )->get, 5,
         'Future::IO->syswrite consumes data' );

   $test_fio->check_and_clear( '->syswrite' );

   test_test( 'syswrite OK' );
}

done_testing;
