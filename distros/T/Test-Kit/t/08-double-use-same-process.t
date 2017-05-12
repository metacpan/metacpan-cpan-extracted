use strict;
use warnings;
use lib 't/lib';

# Double use same process - test that MyTest::Basic can be used twice

package main_one;

use MyTest::Basic;

ok(1, "ok() exists");

package main_two;

use MyTest::Basic;

ok(1, "ok() exists");

done_testing();
