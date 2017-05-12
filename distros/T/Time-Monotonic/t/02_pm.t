# -*- perl -*-

use strict;
use warnings;
use Time::HiRes qw(usleep);

use Test::More tests => 3;

use Time::Monotonic qw(monotonic_time);

like(Time::Monotonic::backend(),
     qr/clock_gettime|generic|mach_absolute_time|QueryPerformanceCounter/,
     "Clock name is sane.");

my $is_monotonic = Time::Monotonic::is_monotonic();
ok ($is_monotonic eq '1' || $is_monotonic eq '0', "monotonic_clock_is_monotonic is sane");

my $time           = monotonic_time();
usleep(1000);
my $time2          = monotonic_time();

cmp_ok ($time,          '<', $time2,          "Monotonic time increments");
