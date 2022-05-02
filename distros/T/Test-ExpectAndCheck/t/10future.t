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
   test_out q[ok 1 - $puppet->sleep is not done before get];
   test_out q[ok 2 - $puppet->sleep is done after get];
   test_out q[# Subtest: ->sleep];
   test_out q[    ok 1 - ->sleep('0.5')];
   test_out q[    1..1];
   test_out q[ok 3 - ->sleep];

   $controller->expect( sleep => 0.5 );
   my $f = $puppet->sleep( 0.5 );
   ok( !$f->is_done, '$puppet->sleep is not done before get' );
   $f->get;
   ok( $f->is_done, '$puppet->sleep is done after get' );
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

# immediate
{
   test_out q[ok 1 - $f is done immediately];
   test_out q[ok 2 - $f->result];
   test_out q[# Subtest: ->imm];
   test_out q[    ok 1 - ->imm('ABC')];
   test_out q[    1..1];
   test_out q[ok 3 - ->imm];

   $controller->expect( imm => "ABC" )->returns( "DEF" )->immediately;
   my $f = $puppet->imm( "ABC" );
   ok( $f->is_done, '$f is done immediately' );
   is( $f->result, "DEF", '$f->result' );
   $controller->check_and_clear( '->imm' );

   test_test 'immediate';
}

# remains pending
{
   test_out q[ok 1 - $f is still pending];
   test_out q[# Subtest: ->pending];
   test_out q[    ok 1 - ->pending()];
   test_out q[    1..1];
   test_out q[ok 2 - ->pending];

   $controller->expect( pending => )->remains_pending;
   my $f = $puppet->pending();
   ok( !$f->is_ready, '$f is still pending' );
   $controller->check_and_clear( '->pending' );

   test_test 'remains_pending';
}

done_testing;
