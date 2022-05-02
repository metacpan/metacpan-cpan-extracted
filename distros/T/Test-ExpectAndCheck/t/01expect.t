#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::ExpectAndCheck;

my ( $controller, $puppet ) = Test::ExpectAndCheck->create;

# pass
{
   test_out q[# Subtest: ->amethod];
   test_out q[    ok 1 - ->amethod('0.5')];
   test_out q[    1..1];
   test_out q[ok 1 - ->amethod];

   $controller->expect( amethod => 0.5 );
   $puppet->amethod( 0.5 );
   $controller->check_and_clear( '->amethod' );

   test_test 'amethod OK';
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
   is( $puppet->one, 1, '$puppet->one returns 1' );
   $controller->check_and_clear( '->one' );

   test_test 'one OK';
}

# throws
{
   test_out q[ok 1 - $puppet->two throws];
   test_out q[# Subtest: ->two];
   test_out q[    ok 1 - ->two()];
   test_out q[    1..1];
   test_out q[ok 2 - ->two];

   $controller->expect( two => )
      ->throws( "Oopsie\n" );
   is( !eval { $puppet->two } && $@, "Oopsie\n", '$puppet->two throws' );
   $controller->check_and_clear( '->two' );

   test_test 'two throws';
}

# fail not called
{
   test_out q[# Subtest: ->bmethod];
   test_out q[    not ok 1 - ->bmethod('0.5')];
   test_out q[    1..1];
   test_out q[not ok 1 - ->bmethod];
   test_err q[    #   Failed test '->bmethod('0.5')'];
   test_err qr/\s*#   at .* line \d+\.\n/;
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail +3;

   $controller->expect( bmethod => 0.5 );
   $controller->check_and_clear( '->bmethod' );

   test_test 'bmethod fail not called';
}

# fail wrong args
{
   test_out q[ok 1 - ->cmethod with wrong args dies];
   test_out q[# Subtest: ->cmethod fails];
   test_out q[    not ok 1 - ->cmethod('0.5')];
   test_out q[    1..1];
   test_out q[not ok 2 - ->cmethod fails];
   test_err q[    #   Failed test '->cmethod('0.5')'];
   test_err qr/\s*#   at .* line \d+\.\n/;
   test_err q[    # Compared $data->[0]];
   test_err q[    #    got : '1'];
   test_err q[    # expect : '0.5'];
   test_err q[    # Looks like you failed 1 test of 1.];
   test_fail +6;

   my $line = __LINE__;
   $controller->expect( cmethod => 0.5 );
   ok( !defined eval { $puppet->cmethod( 1.0 ) }, '->cmethod with wrong args dies' );
   my $e = "$@";
   $controller->check_and_clear( '->cmethod fails' );

   test_test 'cmethod fail wrong args';

   # I can't actually break out of TBT mode here so lets nest it instead
   test_out q[ok 1 - thrown exception from expectation failure];

   is( $e, "Unexpected call to ->cmethod(1) at $0 line ${\( $line+2 )}.\n" .
           "... while expecting ->cmethod('0.5') at $0 line ${\( $line+1 )}.\n",
      'thrown exception from expectation failure' );

   test_test 'exception message check';
}

# fail unexpected
{
   test_out q[ok 1 - unexpected ->dmethod dies];
   test_out qr/\s*# Subtest: ->dmethod fails\n/;
   test_out q[    ok 1 - No calls made];
   test_out q[    1..1];
   test_out q[ok 2 - ->dmethod fails];

   ok( !defined eval { $puppet->dmethod( 2.0 ) }, 'unexpected ->dmethod dies' );
   $controller->check_and_clear( '->dmethod fails' );

   test_test 'dmethod fail unexpected';
}

done_testing;
