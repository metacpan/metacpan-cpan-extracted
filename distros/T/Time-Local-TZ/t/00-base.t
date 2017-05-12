#!env perl

use strict;
use warnings;

use Test::More tests => 10; 
BEGIN { use_ok('Time::Local::TZ') };

is(Time::Local::TZ::TM_SEC(),   0, "constant TM_SEC");
is(Time::Local::TZ::TM_MIN(),   1, "constant TM_MIN");
is(Time::Local::TZ::TM_HOUR(),  2, "constant TM_HOUR");
is(Time::Local::TZ::TM_MDAY(),  3, "constant TM_MDAY");
is(Time::Local::TZ::TM_MON(),   4, "constant TM_MON");
is(Time::Local::TZ::TM_YEAR(),  5, "constant TM_YEAR");
is(Time::Local::TZ::TM_WDAY(),  6, "constant TM_WDAY");
is(Time::Local::TZ::TM_YDAY(),  7, "constant TM_YDAY");
is(Time::Local::TZ::TM_ISDST(), 8, "constant TM_ISDST");



