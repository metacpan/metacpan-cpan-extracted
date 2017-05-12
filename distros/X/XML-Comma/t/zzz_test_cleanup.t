# zzz_test_cleanup.t : remove the .test directory we used for testing...

use strict;

use Test::More tests => 1;
use File::Path;

rmtree(".test");

ok("dummy");
