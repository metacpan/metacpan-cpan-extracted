#!perl

use strict;
use warnings;

use Test::More;

use XString;
use B;

is XString::cstring( q[a'string"with quotes] ), B::cstring( q[a'string"with quotes] ), q["a'string\"with quotes"];
is XString::perlstring( q[a'string"with quotes] ), B::perlstring( q[a'string"with quotes] ), q["a'string\"with quotes"];

done_testing;
