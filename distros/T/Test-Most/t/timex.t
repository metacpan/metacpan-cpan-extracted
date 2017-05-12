#!/usr/bin/perl

use lib 'lib', 't/lib';
use Test::Most qw<timeit>;

ok 1;
timeit { ok 1 };
timeit { ok 1 } 'message';

done_testing();
