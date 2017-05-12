#!env perl

use strict;
use warnings;

use Test::More tests => 4;
use Time::Local::TZ qw/:const tz_offset/;

is(tz_offset("Europe/Moscow", 1293829200), 10800, "tz_offset('Europe/Moscow', 1293829200)");
is(tz_offset("Europe/Moscow", 1309464000), 14400, "tz_offset('Europe/Moscow', 1309464000)");
is(tz_offset("UTC", 1293829200), 0, "tz_offset('UTC', 1293829200)");
is(tz_offset("UTC", 1309464000), 0, "tz_offset('UTC', 1309464000)");
