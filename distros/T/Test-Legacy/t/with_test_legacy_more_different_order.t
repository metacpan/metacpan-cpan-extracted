#!/usr/bin/perl -w

use Test::Legacy::More;
use Test::Legacy;

plan tests => 2;

ok( 0, 0, "Test::Legacy's ok" );
is( 1, 1, "Test::More's is" );
