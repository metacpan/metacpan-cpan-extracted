#!env perl

use strict;
use warnings;

use Test::More tests => 7;
use Time::Local::TZ qw/:const tz_offset/;

is(tz_offset("UTC", 1293829200), 0, "tz_offset('UTC', 1293829200)");
is(tz_offset("UTC", 1309464000), 0, "tz_offset('UTC', 1309464000)");

is(tz_offset("PST8PDT", 1288393200), -28800, "tz_offset('PST8PDT', 1288393200)");
is(tz_offset("MSK-4", 1309464000),    14400, "tz_offset('MSK-4', 1309464000)");

SKIP: {
    skip "Olson timezone names are not available on windows", 3 if $^O =~ /MSWin32/;

    is(tz_offset("Europe/Moscow", 1288393200), 10800, "tz_offset('Europe/Moscow', 1288393200)");
    is(tz_offset("Europe/Moscow", 1293829200), 10800, "tz_offset('Europe/Moscow', 1293829200)");
    is(tz_offset("Europe/Moscow", 1310468400), 14400, "tz_offset('Europe/Moscow', 1310468400)");
}
