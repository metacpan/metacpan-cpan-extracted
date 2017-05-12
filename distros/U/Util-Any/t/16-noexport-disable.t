#!perl -T

use Test::More tests => 1;
use lib qw(t/lib/ lib/);
use strict;
use warnings;

use UtilNotExport -test => [];
ok(1, 'dummy test. only this test was run.');
