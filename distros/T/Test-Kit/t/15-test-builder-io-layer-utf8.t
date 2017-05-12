use strict;
use warnings;
use utf8;
use lib 't/lib';

# Test Builder IO Layer UTF8 - test that the Test::Builder I/O Layer trick works

use MyTest::TestBuilderIOLayerUTF8;

ok(1, "ok() exists");

# This has to be checked by eye...
#
# Test::Output only works on STDOUT and STDERR, and Test::Warn only works on
# SIG{__WARN__}, so I have no idea how to properly test the Test::Builder
# output file handles.
pass("Δ");
TODO: {
    local $TODO = "Σ";
    fail("Λ");
}

done_testing();
