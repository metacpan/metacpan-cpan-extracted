use strict;
use warnings;
use Test::More;
use Test::Time::HiRes time => 1;

use Time::HiRes qw( usleep );

ok my $time = time(), "got time()";
ok my $hires_time = Time::HiRes::time(), "got Time::HiRes::time()";

note "real time passes";

CORE::sleep 1;    # real sleep

ok time() == $time, "time() hasn't changed";
ok Time::HiRes::time() == $hires_time, "Time::HiRes::time() hasn't changed";

note "sleep";

sleep 1;          # fake sleep

ok time() == $time + 1, "time() increased by 1 second";
ok Time::HiRes::time() == $hires_time + 1, "Time::HiRes::time() increased by 1 second";

note "usleep";

$time = time();
$hires_time = Time::HiRes::time();

usleep 1000;      # fake sleep

ok time() == $time, "time() not increased";
ok Time::HiRes::time() == $hires_time + 0.001,
    "Time::HiRes::time() increased by 1000 milliseconds";

done_testing;
