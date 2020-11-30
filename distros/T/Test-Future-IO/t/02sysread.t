#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Future::IO;

my $test_fio = Test::Future::IO->controller;

# pass
{
   test_out q[ok 1 - Future::IO->sysread yields data];
   test_out q[# Subtest: ->sysread];
   test_out q[    ok 1 - ->sysread(ignore(), 5)];
   test_out q[    1..1];
   test_out q[ok 2 - ->sysread];

   $test_fio->expect_sysread_anyfh( 5 )
      ->returns( "Hello" );

   is( Future::IO->sysread( "dummyFH", 5 )->get, "Hello",
         'Future::IO->sysread yields data' );

   $test_fio->check_and_clear( '->sysread' );

   test_test( 'sysread OK' );
}

done_testing;
