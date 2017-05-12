# Test 2: Frequency

use Test::More tests => 1;
use Win32::PerfCounter;

my @ret = Win32::PerfCounter::frequency;
ok($#ret > 0, "Win32::PerfCounter::frequency");
