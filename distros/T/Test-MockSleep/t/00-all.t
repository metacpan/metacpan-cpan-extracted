#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockSleep;

use Time::HiRes;

use Dir::Self;
use lib __DIR__;
use dummy_module;

my $begin_time = time();

sleep(20);
is(slept, 20, "in same module (CORE::sleep)");
Time::HiRes::sleep(2.5);
is(slept, 2.5, "in same module (Time::HiRes::sleep)");

dummy_module::sleep_core(5);
is(slept(), 5, "CORE::sleep");

dummy_module::sleep_time_hires(0.5);
is(slept(), 0.5, "Time::HiRes::sleep");

dummy_module_thr::thr_sleep(0.5);
is(slept(), 0.5, "Time::HiRes::sleep (implicit)");

sleep(100);
sleep(100);
is($Test::MockSleep::Slept, 200, "package \$Slept");

Test::MockSleep->restore();
my $begin = Time::HiRes::time();
Time::HiRes::sleep(0.1);
my $end = Time::HiRes::time();
ok($begin != $end, "Real Time::HiRes::sleep: ($begin to $end)");

diag "Sleeping 1 second for real";

$begin = CORE::time();
sleep(1);
$end = CORE::time();
ok($begin != $end, "Real CORE::sleep ($begin to $end)");

$begin = Time::HiRes::time();
Time::HiRes::sleep(0.1);
$end = Time::HiRes::time();
ok($begin != $end, "Real Time::HiRes::sleep ($begin to $end)");

done_testing();

