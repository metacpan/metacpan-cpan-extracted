package main;

use strict;
use lib qw(lib t/lib);
use SubExporterGenerator -test;
use Test::More 'no_plan';

is(min(100,25,30), 25);
is(min(100,10,30), 10);
is(max(80,25,30), 80);
is(max(130,10,30), 130);
is(scalar uniq(1,3,1,4,5,1), 4);