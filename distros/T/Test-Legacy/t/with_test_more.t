#!/usr/bin/perl -w

use Test::Legacy;
use Test::More import => [qw(!ok !skip !plan)];

plan tests => 2;

ok( 0, 0 );
is( 1, 1 );
