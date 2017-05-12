#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Test::LeakTrace' }

diag "Testing Test::LeakTrace/$Test::LeakTrace::VERSION";

