use Test2::V0 -target => 'goto::file';
use Test2::IPC;
use Test2::Require::RealFork;

use File::Temp qw/tempfile/;

use ok $CLASS => [
    "is(__LINE__, 1, 'got line 1');",
    "ok(1, 'pass');",
    "done_testing;",
];

die "Should not get here!\n";
