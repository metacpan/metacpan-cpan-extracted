#!perl

use Test::More;
use Test::RequiresInternet ( 'www.google.com' => 80, 'www.yahoo.com' => 80 );

plan tests => 1;

ok(1);
