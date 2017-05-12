#!/usr/bin/perl

use strict;

use Test::Builder::Tester 1.04 tests => 6;

use Test::More;

# tests pm_version_ok

BEGIN {
    use_ok('Test::HasVersion');
}

ok( chdir "t/eg", "cd t/eg" );

test_out("ok 1 - A.pm has version");
pm_version_ok("A.pm");
test_test();

test_out("not ok 1 - X.pm has version");
test_fail(+1);
pm_version_ok("X.pm");
test_diag("X.pm does not exist");
test_test();

test_out("ok 1 - lib/B.pm has version");
pm_version_ok("lib/B.pm");
test_test();

test_out("not ok 1 - lib/B/C.pm has version");
test_fail(+1);
pm_version_ok("lib/B/C.pm");
test_test();
