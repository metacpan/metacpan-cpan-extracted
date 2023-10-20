#!/usr/bin/perl

use v5.14;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

use Test::ExpectAndCheck;

my ( $controller, $mock ) = Test::ExpectAndCheck->create;

# pass
{
   test_out q[ok 1 - ->one];
   test_out q[ok 2 - ->one again];
   test_out q[# Subtest: ->one];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 3 - ->one];

   $controller->whenever( one => )
      ->will_return( 1 );

   is( $mock->one, 1, '->one' );
   is( $mock->one, 1, '->one again' );

   $controller->check_and_clear( '->one' );

   test_test 'one OK';
}

# choice of args
{
   test_out q[ok 1 - ->add 1+1];
   test_out q[ok 2 - ->add 2+2];
   test_out q[ok 3 - ->add 2+2 again];
   test_out q[ok 4 - ->add 1+1 again];
   test_out q[# Subtest: ->add];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 5 - ->add];

   $controller->whenever( add => 1, 1 )
      ->will_return( 2 );
   $controller->whenever( add => 2, 2 )
      ->will_return( 4 );

   is( $mock->add( 1, 1 ), 2, '->add 1+1' );
   is( $mock->add( 2, 2 ), 4, '->add 2+2' );
   is( $mock->add( 2, 2 ), 4, '->add 2+2 again' );
   is( $mock->add( 1, 1 ), 2, '->add 1+1 again' );

   $controller->check_and_clear( '->add' );

   test_test 'add OK';
}

# will_return_using args
{
   test_out q[ok 1 - ->mul 2*2];
   test_out q[ok 2 - ->mul 2*3];
   test_out q[# Subtest: ->mul];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 3 - ->mul];

   $controller->whenever( mul => Test::Deep::ignore(), Test::Deep::ignore() )
      ->will_return_using( sub { my ($args) = @_; return $args->[0] * $args->[1]; } );

   is( $mock->mul( 2, 2 ), 4, '->mul 2*2' );
   is( $mock->mul( 2, 3 ), 6, '->mul 2*3' );

   $controller->check_and_clear( '->mul' );

   test_test 'mul OK';
}

# indefinite whenevers outlive ->check_and_clear
{
   $controller->whenever( div => Test::Deep::ignore(), Test::Deep::ignore() )
      ->will_return_using( sub { my ($args) = @_; return $args->[0] / $args->[1]; } )
      ->indefinitely;

   test_out q[ok 1 - ->div returns result];
   test_out q[# Subtest: ->div];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 2 - ->div];

   is( $mock->div( 10, 5 ), 2, '->div returns result' );

   $controller->check_and_clear( '->div' );

   test_out q[ok 3 - ->div returns result];
   test_out q[# Subtest: ->div again];
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 4 - ->div again];

   is( $mock->div( 12, 4 ), 3, '->div returns result' );

   $controller->check_and_clear( '->div again' );

   test_test 'indefinitely';
}

done_testing;
