use strict;
use warnings;
use lib 't/lib';

# Basic - test that Test::More by itself can be Kit'd

use MyTest::Basic;

ok(1, "ok() exists");

done_testing();
