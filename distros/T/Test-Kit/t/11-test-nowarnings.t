use strict;
use warnings;
use lib 't/lib';

# No Warnings - Test::NoWarnings installs an additional test at the end of your test run. Does that work?

use MyTest::NoWarnings;

plan tests => 2;

ok(1, "ok() exists");
