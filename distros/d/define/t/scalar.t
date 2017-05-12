#! perl

use 5.006;
use strict;
use warnings;
use Test::More 0.88 tests => 3;

use define STRING  => 'hello world';
use define FLOAT   => 3.141592654;
use define INTEGER => 3;

is(STRING, 'hello world', "string constant should match the string");
like(FLOAT, qr/^3\.14/, "FLOAT should match to at least 2 decimal places");
ok(INTEGER == 3, "numeric literal should match that number");
