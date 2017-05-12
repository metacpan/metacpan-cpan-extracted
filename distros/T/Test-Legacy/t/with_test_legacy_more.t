#!/usr/bin/perl -w

use Test::Legacy;
use Test::Legacy::More;

plan tests => 3;

ok( 0, 0, "Test::Legacy's ok" );
is( 1, 1, "Test::More's is" );

can_ok( Test::Legacy::More => 'builder' );