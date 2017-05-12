use strict;
use warnings;
use lib 't/lib';

# Simple - test that Test::More and Test::Warn can be combined

use MyTest::Simple;

ok(1, "ok() exists");

pass("pass() exists");

warning_like(
    sub { warn("foo") },
    qr/foo/,
    "warning_like() exists"
);

done_testing();
