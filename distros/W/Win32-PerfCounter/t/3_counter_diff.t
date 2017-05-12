# Test 3: Counter, using sleep

use Test::More tests => 1;
use Win32::PerfCounter;

my @ret1 = Win32::PerfCounter::counter;
sleep(1);
my @ret2 = Win32::PerfCounter::counter;

ok($ret1[1] != $ret2[1], "Win32::PerfCounter::counter");
