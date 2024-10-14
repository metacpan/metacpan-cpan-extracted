#!/usr/bin/perl

use v5.14;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

use Test::ExpectAndCheck 'namedargs';

my ( $controller, $mock ) = Test::ExpectAndCheck->create;

# pass - exact order
{
   test_out q[# Subtest: ->nmethod];
   test_out q[    ok 1 - ->nmethod('x', 'y', namedargs(one => 1, two => 2))];
   test_out q[    1..1];
   test_out q[ok 1 - ->nmethod];

   $controller->expect( nmethod => 'x', 'y', namedargs(one => 1, two => 2) );
   $mock->nmethod( 'x', 'y', one => 1, two => 2 );
   $controller->check_and_clear( '->nmethod' );

   test_test 'nmethod OK';
}

# pass - swapped order
{
   test_out q[# Subtest: ->nmethod];
   test_out q[    ok 1 - ->nmethod('x', 'y', namedargs(one => 1, two => 2))];
   test_out q[    1..1];
   test_out q[ok 1 - ->nmethod];

   $controller->expect( nmethod => 'x', 'y', namedargs(one => 1, two => 2) );
   $mock->nmethod( 'x', 'y', two => 2, one => 1 );
   $controller->check_and_clear( '->nmethod' );

   test_test 'nmethod OK';
}

# fails - wrong value in positional
{
   test_out q[ok 1 - ->nmethod with wrong positional arg dies];
   test_out q[# Subtest: ->nmethod];
   test_out q[    not ok 1 - ->nmethod('x', 'y', namedargs(one => 1, two => 2))];
   test_out q[    1..1];
   test_out q[not ok 2 - ->nmethod];
   test_err q[    #   Failed test '->nmethod('x', 'y', namedargs(one => 1, two => 2))'];
   test_err qr/\s*#   at .* line \d+\.\n/;
   test_err q[    # Compared $data];
   test_err q[    #    got : 'z'];
   test_err q[    # expect : 'y'];
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail +4;

   $controller->expect( nmethod => 'x', 'y', namedargs(one => 1, two => 2) );
   ok( !defined eval { $mock->nmethod( 'x', 'z', two => 2, one => 1 ) }, '->nmethod with wrong positional arg dies' );
   $controller->check_and_clear( '->nmethod' );

   test_test 'nmethod OK';
}

# fails - wrong value in named
{
   test_out q[ok 1 - ->nmethod with wrong named arg dies];
   test_out q[# Subtest: ->nmethod];
   test_out q[    not ok 1 - ->nmethod('x', 'y', namedargs(one => 1, two => 2))];
   test_out q[    1..1];
   test_out q[not ok 2 - ->nmethod];
   test_err q[    #   Failed test '->nmethod('x', 'y', namedargs(one => 1, two => 2))'];
   test_err qr/\s*#   at .* line \d+\.\n/;
   test_err q[    # Compared $data->{"one"}];
   test_err q[    #    got : '3'];
   test_err q[    # expect : '1'];
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail +4;

   $controller->expect( nmethod => 'x', 'y', namedargs(one => 1, two => 2) );
   ok( !defined eval { $mock->nmethod( 'x', 'y', two => 2, one => 3 ) }, '->nmethod with wrong named arg dies' );
   $controller->check_and_clear( '->nmethod' );

   test_test 'nmethod OK';
}

done_testing;
