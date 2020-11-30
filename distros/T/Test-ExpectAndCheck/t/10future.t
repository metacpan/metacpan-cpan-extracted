#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

eval { require Future } or
   plan skip_all => "Future is not available";

use Test::ExpectAndCheck::Future;

my ( $controller, $puppet ) = Test::ExpectAndCheck::Future->create;

# pass
{
   test_out q[ok 1 - $puppet->sleep is done];
   test_out q[# Subtest: ->sleep];
   test_out q[    ok 1 - ->sleep('0.5')];
   test_out q[    1..1];
   test_out q[ok 2 - ->sleep];

   $controller->expect( sleep => 0.5 );
   ok( $puppet->sleep( 0.5 )->is_done, '$puppet->sleep is done' );
   $controller->check_and_clear( '->sleep' );

   test_test 'sleep OK';
}

# returns
{
   test_out q[ok 1 - $puppet->one returns 1];
   test_out q[# Subtest: ->one];
   test_out q[    ok 1 - ->one()];
   test_out q[    1..1];
   test_out q[ok 2 - ->one];

   $controller->expect( one => )
      ->returns( 1 );
   is( $puppet->one->get, 1, '$puppet->one returns 1' );
   $controller->check_and_clear( '->one' );

   test_test 'one OK';
}

# fails
{
   test_out q[ok 1 - $puppet->two fails];
   test_out q[# Subtest: ->two];
   test_out q[    ok 1 - ->two()];
   test_out q[    1..1];
   test_out q[ok 2 - ->two];

   $controller->expect( two => )
      ->fails( "Oopsie\n" );
   is( $puppet->two->failure, "Oopsie\n", '$puppet->two fails' );
   $controller->check_and_clear( '->two' );

   test_test 'two fails';
}

done_testing;
