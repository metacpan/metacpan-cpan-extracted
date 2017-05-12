use strict;
use warnings;

use Test::More tests => 14;

use_ok('MMM::Utils');

is(yes_no(), 0, 'undef');
is(yes_no(''), 0, 'empty');
is(yes_no('0'), 0, 'zero');
is(yes_no('OFF'), 0, 'OFF');

is(yes_no('ON'), 1, 'ON');
is(yes_no(1), 1, 'un');
is(yes_no('true'), 1, 'true');
is(yes_no('yes'), 1, 'yes');

is(yes_no('NON'), 0, 'NON');

is(fmt_duration(0, 3), "00h00m03s", "format 3 second");
is(fmt_duration(0, 3600 * 24), "1 day, 00h00m00s", "format 1 day");
is(fmt_duration(0, 3600 * 24 + 3600 + 52), "1 day, 01h00m52s", "format 1 day, 1 hour and 52s");
is(fmt_duration(0, 3600 * 48 + 3600 + 52), "2 days, 01h00m52s", "format 2 days, 1 hour and 52s");
