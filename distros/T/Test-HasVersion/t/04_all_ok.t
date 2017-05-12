#!/usr/bin/perl

use Test::Builder::Tester tests => 1;
use Test::More;
use Test::HasVersion;

my @expected = (
    'A.pm'       => 'ok',
    'lib/B.pm'   => 'ok',
    'lib/B/C.pm' => 'not ok',
);

my $count = 1;
while (@expected) {
    my $file = shift @expected;
    my $want = shift @expected;
    test_out("$want $count - $file has version");
    test_fail(+5) if $want eq 'not ok';
    $count++;
}

chdir "t/eg/" or die "Can't chdir to t/eg";
all_pm_version_ok();

test_test("all_pm_version_ok() including failures");
