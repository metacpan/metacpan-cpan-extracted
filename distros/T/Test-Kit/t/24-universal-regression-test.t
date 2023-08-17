use strict;
use warnings;
use lib 't/lib';

# Ensure that loading UNIVERSAL doesn't break Test::Kit

use UNIVERSAL;
use MyTest::Simple;

pass("pass() exists");

done_testing();
