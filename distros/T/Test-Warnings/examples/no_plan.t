use strict;
use warnings;

use Test::More;
use Test::Warnings ':all';

is(1, 1, 'passing test');

had_no_warnings;

ok(!allowing_warnings, 'warnings are not currently allowed');

allow_warnings;
ok(allowing_warnings, 'warnings are now allowed');

warn 'this warning will not cause a failure';
had_no_warnings;

allow_warnings(0);
ok(!allowing_warnings, 'warnings are not allowed again');
warn 'oh noes, something warned!';

# this will now fail.
had_no_warnings;

# had_no_warnings will be called automatically from END
# done_testing not called... will cause a test failure
