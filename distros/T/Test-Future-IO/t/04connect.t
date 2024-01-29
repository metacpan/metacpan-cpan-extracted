#!/usr/bin/perl

use v5.14;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

use Test::Future::IO;

my $test_fio = Test::Future::IO->controller;

# pass
{
   test_out q[ok 1 - Future::IO->connect is done];
   test_out q[# Subtest: ->connect];
   test_out q[    ok 1 - ->connect('dummyFH', 'addr')];
   test_out q[    1..1];
   test_out q[ok 2 - ->connect];

   $test_fio->expect_connect( "dummyFH", "addr" );

   ok( eval { Future::IO->connect( "dummyFH", "addr" )->is_done; 1 },
      'Future::IO->connect is done' ) or
      diag( "Failure was $@" );
   $test_fio->check_and_clear( '->connect' );

   test_test 'connect OK';
}

# fail not called
{
   test_out q[# Subtest: ->connect];
   test_out q[    not ok 1 - ->connect('dummyFH', 'addr')];
   test_out q[    1..1];
   test_out q[not ok 1 - ->connect];
   test_err q[    #   Failed test '->connect('dummyFH', 'addr')'];
   test_err qr/    #   at .* line \d+\.\n/;
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail( +3 );

   $test_fio->expect_connect( "dummyFH", "addr" );
   $test_fio->check_and_clear( '->connect' );

   test_test 'connect fail not called';
}

# fail wrong args
{
   test_out q[ok 1 - ->connect with wrong args dies];
   test_out q[# Subtest: ->connect fails];
   test_out q[    not ok 1 - ->connect('dummyFH', 'addr')];
   test_out q[    1..1];
   test_out q[not ok 2 - ->connect fails];
   test_err q[    #   Failed test '->connect('dummyFH', 'addr')'];
   test_err qr/    #   at .* line \d+\.\n/;
   test_err q[    # Compared $data->[1]];
   test_err q[    #    got : 'ADDR'];
   test_err q[    # expect : 'addr'];
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail( +4 );

   $test_fio->expect_connect( "dummyFH", "addr" );
   ok( !defined eval { Future::IO->connect( "dummyFH", "ADDR" ) }, '->connect with wrong args dies' );
   $test_fio->check_and_clear( '->connect fails' );

   test_test 'connect fail wrong args';
}

# fail unexpected
{
   test_out q[ok 1 - unexpected ->connect dies];
   test_out q[# Subtest: ->connect fails];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 2 - ->connect fails];

   ok( !defined eval { Future::IO->connect( "dummyFH", "addr" ) }, 'unexpected ->connect dies' );
   $test_fio->check_and_clear( '->connect fails' );

   test_test 'connect fail unexpected';
}

done_testing;
