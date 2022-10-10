#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Future::IO;

my $test_fio = Test::Future::IO->controller;

# pass
{
   test_out q[ok 1 - Future::IO->sleep is done];
   test_out q[# Subtest: ->sleep];
   test_out q[    ok 1 - ->sleep('0.5')];
   test_out q[    1..1];
   test_out q[ok 2 - ->sleep];

   $test_fio->expect_sleep( 0.5 )
      ->will_done;

   ok( eval { Future::IO->sleep( 0.5 )->is_done; 1 }, 'Future::IO->sleep is done' ) or
      diag( "Failure was $@" );
   $test_fio->check_and_clear( '->sleep' );

   test_test 'sleep OK';
}

# fail not called
{
   test_out q[# Subtest: ->sleep];
   test_out q[    not ok 1 - ->sleep('0.5')];
   test_out q[    1..1];
   test_out q[not ok 1 - ->sleep];
   test_err q[    #   Failed test '->sleep('0.5')'];
   test_err qr/    #   at .* line \d+\.\n/;
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail( +4 );

   $test_fio->expect_sleep( 0.5 )
      ->will_done;
   $test_fio->check_and_clear( '->sleep' );

   test_test 'sleep fail not called';
}

# fail wrong args
{
   test_out q[ok 1 - ->sleep with wrong args dies];
   test_out q[# Subtest: ->sleep fails];
   test_out q[    not ok 1 - ->sleep('0.5')];
   test_out q[    1..1];
   test_out q[not ok 2 - ->sleep fails];
   test_err q[    #   Failed test '->sleep('0.5')'];
   test_err qr/    #   at .* line \d+\.\n/;
   test_err q[    # Compared $data->[0]];
   test_err q[    #    got : '1'];
   test_err q[    # expect : '0.5'];
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail( +5 );

   $test_fio->expect_sleep( 0.5 )
      ->will_done;
   ok( !defined eval { Future::IO->sleep( 1.0 ) }, '->sleep with wrong args dies' );
   $test_fio->check_and_clear( '->sleep fails' );

   test_test 'sleep fail wrong args';
}

# fail unexpected
{
   test_out q[ok 1 - unexpected ->sleep dies];
   test_out q[# Subtest: ->sleep fails];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 2 - ->sleep fails];

   ok( !defined eval { Future::IO->sleep( 2.0 ) }, 'unexpected ->sleep dies' );
   $test_fio->check_and_clear( '->sleep fails' );

   test_test 'sleep fail unexpected';
}

done_testing;
