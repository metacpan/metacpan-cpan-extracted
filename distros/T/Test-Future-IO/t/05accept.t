#!/usr/bin/perl

use v5.14;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

use Test::Future::IO;

my $test_fio = Test::Future::IO->controller;

# pass
{
   test_out q[ok 1 - Future::IO->accept is done];
   test_out q[# Subtest: ->accept];
   test_out q[    ok 1 - ->accept('dummyFH')];
   test_out q[    1..1];
   test_out q[ok 2 - ->accept];

   $test_fio->expect_accept( "dummyFH" )
      ->will_done;

   ok( eval { Future::IO->accept( "dummyFH" )->is_done; 1 },
      'Future::IO->accept is done' ) or
      diag( "Failure was $@" );
   $test_fio->check_and_clear( '->accept' );

   test_test 'accept OK';
}

# fail not called
{
   test_out q[# Subtest: ->accept];
   test_out q[    not ok 1 - ->accept('dummyFH')];
   test_out q[    1..1];
   test_out q[not ok 1 - ->accept];
   test_err q[    #   Failed test '->accept('dummyFH')'];
   test_err qr/    #   at .* line \d+\.\n/;
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail( +4 );

   $test_fio->expect_accept( "dummyFH" )
      ->will_done;
   $test_fio->check_and_clear( '->accept' );

   test_test 'accept fail not called';
}

# fail wrong args
{
   test_out q[ok 1 - ->accept with wrong args dies];
   test_out q[# Subtest: ->accept fails];
   test_out q[    not ok 1 - ->accept('dummyFH')];
   test_out q[    1..1];
   test_out q[not ok 2 - ->accept fails];
   test_err q[    #   Failed test '->accept('dummyFH')'];
   test_err qr/    #   at .* line \d+\.\n/;
   test_err q[    # Compared $data->[0]];
   test_err q[    #    got : 'differentFH'];
   test_err q[    # expect : 'dummyFH'];
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail( +5 );

   $test_fio->expect_accept( "dummyFH" )
      ->will_done;
   ok( !defined eval { Future::IO->accept( "differentFH" ) }, '->accept with wrong args dies' );
   $test_fio->check_and_clear( '->accept fails' );

   test_test 'accept fail wrong args';
}

# fail unexpected
{
   test_out q[ok 1 - unexpected ->accept dies];
   test_out q[# Subtest: ->accept fails];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 2 - ->accept fails];

   ok( !defined eval { Future::IO->accept( "dummyFH" ) }, 'unexpected ->accept dies' );
   $test_fio->check_and_clear( '->accept fails' );

   test_test 'accept fail unexpected';
}

done_testing;
