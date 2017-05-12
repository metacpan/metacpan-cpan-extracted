# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && make && perl -Mlib=blib/arch -Mlib=blib/lib t/01_xs.t

use strict;
use warnings;
use Time::HiRes qw(usleep);

use Test::More tests => 5;
BEGIN { use_ok('Time::Monotonic') };

like(Time::Monotonic::monotonic_clock_name(),
     qr/clock_gettime|generic|mach_absolute_time|QueryPerformanceCounter/,
     "Clock name is sane.");

my $is_monotonic = Time::Monotonic::monotonic_clock_is_monotonic();
ok ($is_monotonic eq '1' || $is_monotonic eq '0', "monotonic_clock_is_monotonic is sane");

my $time           = Time::Monotonic::clock_get_dbl();
my $time_fallback  = Time::Monotonic::clock_get_dbl_fallback();
usleep(1000);
my $time2          = Time::Monotonic::clock_get_dbl();
my $time_fallback2 = Time::Monotonic::clock_get_dbl_fallback();

cmp_ok ($time,          '<', $time2,          "Monotonic time increments");
cmp_ok ($time_fallback, '<', $time_fallback2, "Fallback time increments");
