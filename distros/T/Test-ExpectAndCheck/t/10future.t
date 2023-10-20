#!/usr/bin/perl

use v5.14;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

eval { require Future } or
   plan skip_all => "Future is not available";

use Test::ExpectAndCheck::Future;

my ( $controller, $mock ) = Test::ExpectAndCheck::Future->create;

# pass
{
   test_out q[ok 1 - $mock->sleep is not done before get];
   test_out q[ok 2 - $mock->sleep is done after get];
   test_out q[# Subtest: ->sleep];
   test_out q[    ok 1 - ->sleep('0.5')];
   test_out q[    1..1];
   test_out q[ok 3 - ->sleep];

   $controller->expect( sleep => 0.5 )
      ->will_done;
   my $f = $mock->sleep( 0.5 );
   ok( !$f->is_done, '$mock->sleep is not done before get' );
   $f->get;
   ok( $f->is_done, '$mock->sleep is done after get' );
   $controller->check_and_clear( '->sleep' );

   test_test 'sleep OK';
}

# will_done
{
   test_out q[ok 1 - $mock->one returns 1];
   test_out q[# Subtest: ->one];
   test_out q[    ok 1 - ->one()];
   test_out q[    1..1];
   test_out q[ok 2 - ->one];

   $controller->expect( one => )
      ->will_done( 1 );
   is( $mock->one->get, 1, '$mock->one returns 1' );
   $controller->check_and_clear( '->one' );

   test_test 'one OK';
}

# will_fail
{
   test_out q[ok 1 - $mock->two fails];
   test_out q[# Subtest: ->two];
   test_out q[    ok 1 - ->two()];
   test_out q[    1..1];
   test_out q[ok 2 - ->two];

   $controller->expect( two => )
      ->will_fail( "Oopsie\n" );
   is( $mock->two->failure, "Oopsie\n", '$mock->two fails' );
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

   $controller->expect( imm => "ABC" )
      ->immediately
      ->will_done( "DEF" );
   my $f = $mock->imm( "ABC" );
   ok( $f->is_done, '$f is done immediately' );
   is( $f->result, "DEF", '$f->result' );
   $controller->check_and_clear( '->imm' );

   test_test 'immediate';
}

# can fall back to ->will_return
{
   test_out q[ok 1 - $f is direct return];
   test_out q[# Subtest: ->direct];
   test_out q[    ok 1 - ->direct()];
   test_out q[    1..1];
   test_out q[ok 2 - ->direct];

   $controller->expect( direct => )
      ->will_return( "now" );
   my $f = $mock->direct;
   is( $f, "now", '$f is direct return' );
   $controller->check_and_clear( '->direct' );

   test_test 'direct return';
}

# will_also
{
   test_out q[ok 1 - $f->get returns 1];
   test_out q[# Subtest: ->more];
   test_out q[    ok 1 - ->more()];
   test_out q[    1..1];
   test_out q[ok 2 - ->more];
   test_out q[ok 3 - ->will_also code is invoked];

   my $called;
   $controller->expect( more => )
      ->will_done( 1 )
      ->will_also( sub { $called++ } );
   my $f = $mock->more;
   is( $f->get, 1, '$f->get returns 1' );
   $controller->check_and_clear( '->more' );
   ok( $called, '->will_also code is invoked' );

   test_test 'more OK';
}

# remains pending
{
   test_out q[ok 1 - $f is still pending];
   test_out q[# Subtest: ->pending];
   test_out q[    ok 1 - ->pending()];
   test_out q[    1..1];
   test_out q[ok 2 - ->pending];

   $controller->expect( pending => )->remains_pending;
   my $f = $mock->pending();
   ok( !$f->is_ready, '$f is still pending' );
   $controller->check_and_clear( '->pending' );

   test_test 'remains_pending';
}

# will_also_later happens at the right time
{
   test_out q[ok 1 - $f->get returns done];
   test_out q[# Subtest: ->seq];
   test_out q[    ok 1 - ->seq()];
   test_out q[    1..1];
   test_out q[ok 2 - ->seq];
   test_out q[ok 3 - $sequence is correct];

   my $sequence;
   $controller->expect( seq => )
      ->will_also( sub { $sequence .= "1"; } )
      ->will_done( "done" )
      ->will_also_later( sub { $sequence .= "3"; } );
   my $f = $mock->seq()
      ->on_done( sub { $sequence .= "2"; } );
   is( $f->get, "done", '$f->get returns done' );
   $controller->check_and_clear( '->seq' );
   is( $sequence, "123", '$sequence is correct' );

   test_test 'will_also_later';
}

done_testing;
