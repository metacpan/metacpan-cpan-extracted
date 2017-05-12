#!perl
use Test::More tests => 1;

use deferred qr/^t::.*/;
use t::testload2;

is 42, t::testload2->foo;
