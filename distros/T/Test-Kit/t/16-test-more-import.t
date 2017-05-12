use strict;
use warnings;
use lib 't/lib';

# Test More Import - make sure that including Test::More means you can pass tests into import

use MyTest::Basic tests => 1;

pass("got a plan from 'use MyTest::Basic tests => 1;'");
