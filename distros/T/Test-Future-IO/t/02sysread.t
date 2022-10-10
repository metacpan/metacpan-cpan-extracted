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
      ->will_done( "Hello" );

   is( Future::IO->sysread( "dummyFH", 5 )->get, "Hello",
         'Future::IO->sysread yields data' );

   $test_fio->check_and_clear( '->sysread' );

   test_test( 'sysread OK' );
}

# Initial sysread via buffer
{
   test_out q[ok 1 - Future::IO->sysread yields buffered data];
   test_out q[# Subtest: ->sysread via buffer];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 2 - ->sysread via buffer];

   $test_fio->use_sysread_buffer( "dummyFH" );

   $test_fio->write_sysread_buffer( "dummyFH", "Buffered" );

   is( Future::IO->sysread( "dummyFH", 256 )->get, "Buffered",
         'Future::IO->sysread yields buffered data' );

   $test_fio->check_and_clear( '->sysread via buffer' );

   test_test( 'buffered sysread OK' );
}

# Deferred sysread via buffer
{
   test_out q[ok 1 - Future::IO->sysread yields buffered data later];
   test_out q[# Subtest: ->sysread via buffer later];
   test_out q[    ok 1 - ->sleep(5)];
   test_out q[    1..1];
   test_out q[ok 2 - ->sysread via buffer later];

   $test_fio->use_sysread_buffer( "dummyFH" );

   $test_fio->expect_sleep( 5 )
      ->will_done()
      ->will_write_sysread_buffer_later( "dummyFH", "Later" );

   Future::IO->sleep( 5 )->get;
   is( Future::IO->sysread( "dummyFH", 256 )->get, "Later",
         'Future::IO->sysread yields buffered data later' );

   $test_fio->check_and_clear( '->sysread via buffer later' );

   test_test( 'buffered later sysread OK' );
}

done_testing;
