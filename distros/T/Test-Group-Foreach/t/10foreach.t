use strict;
use warnings;

use Test::More tests => 11;
use Test::Builder::Tester;

use Test::Group;
use Test::Group::Foreach;

next_test_foreach my $p, 'p', 0;

test_out("not ok 1 - foo outer");
test_diag(
    "  Failed test 'foo inner (p=0)'",
    "  in $0 at line ".(__LINE__+3).".",
);
test_fail(+1);
test 'foo outer' => sub { ok 0, 'foo inner' };
test_test("singleval testfails");


test_out("not ok 1 - foo outer");
test_diag(
    "  Failed test 'foo inner'",
    "  in $0 at line ".(__LINE__+3).".",
);
test_fail(+1);
test 'foo outer' => sub { ok 0, 'foo inner' };
test_test("only next test group effected");


next_test_foreach $p, 'p', 173;
test_out("not ok 1 - foo outer");
test_diag(
    "  Failed test 'foo inner (p=173)'",
    "  in $0 at line ".(__LINE__+3).".",
);
test_fail(+1);
test 'foo outer' => sub { ok $p != 173, 'foo inner' };
test_test("singleval value passed");


next_test_foreach $p, 'p', 21, 22;
test_out("not ok 1 - foo outer");
test_diag(
    "  Failed test 'foo inner (p=21)'",
    "  in $0 at line ".(__LINE__+5).".",
    "  Failed test 'foo inner (p=22)'",
    "  in $0 at line ".(__LINE__+3).".",
);
test_fail(+1);
test 'foo outer' => sub { ok $p == 0, 'foo inner' };
test_test("two values failing");


Test::Group->verbose(2);


next_test_foreach $p, 'p', 21, 22;
test_out("ok 1 - foo outer");
test_diag(
    "Running group of tests - foo outer",
    "ok 1.1 foo inner [21] (p=21)",
    "ok 1.2 foo inner [22] (p=22)",
);
test 'foo outer' => sub { ok $p != 0, "foo inner [$p]" };
test_test("two values passing");


next_test_foreach $p, 'p', 21;
next_test_foreach my $q, 'q', 23;
test_out("ok 1 - foo outer");
test_diag(
    "Running group of tests - foo outer",
    "ok 1.1 foo inner [21] [23] (p=21,q=23)",
);
test 'foo outer' => sub { ok $p != 0, "foo inner [$p] [$q]" };
test_test("nested one value passing");


next_test_foreach $p, 'p', 21;
next_test_foreach $q, 'q', 23, 24;
test_out("ok 1 - foo outer");
test_diag(
    "Running group of tests - foo outer",
    "ok 1.1 foo inner [21] [23] (p=21,q=23)",
    "ok 1.2 foo inner [21] [24] (p=21,q=24)",
);
test 'foo outer' => sub { ok $p != 0, "foo inner [$p] [$q]" };
test_test("nested one/two passing");


next_test_foreach $p, 'p', 21, 22;
next_test_foreach $q, 'q', 23;
test_out("ok 1 - foo outer");
test_diag(
    "Running group of tests - foo outer",
    "ok 1.1 foo inner [21] [23] (p=21,q=23)",
    "ok 1.2 foo inner [22] [23] (p=22,q=23)",
);
test 'foo outer' => sub { ok $p != 0, "foo inner [$p] [$q]" };
test_test("nested two/one passing");


next_test_foreach my $x, 'x', 21, 22;
next_test_foreach my $y, 'y', 23, 24;
test_out("ok 1 - foo outer");
test_diag(
    "Running group of tests - foo outer",
    "ok 1.1 foo inner [21] [23] (x=21,y=23)",
    "ok 1.2 foo inner [21] [24] (x=21,y=24)",
    "ok 1.3 foo inner [22] [23] (x=22,y=23)",
    "ok 1.4 foo inner [22] [24] (x=22,y=24)",
);
test 'foo outer' => sub { ok $y != 0, "foo inner [$x] [$y]" };
test_test("nested two/two passing");


next_test_foreach $p, '', 21, 22;
test_out("ok 1 - noname outer");
test_diag(
    "Running group of tests - noname outer",
    "ok 1.1 noname inner [21] (21)",
    "ok 1.2 noname inner [22] (22)",
);
test 'noname outer' => sub { ok $p != 0, "noname inner [$p]" };
test_test("no name for variable");
 

next_test_foreach $p, undef, 21, 22;
test_out("ok 1 - nonote outer");
test_diag(
    "Running group of tests - nonote outer",
    "ok 1.1 nonote inner [21]",
    "ok 1.2 nonote inner [22]",
);
test 'nonote outer' => sub { ok $p != 0, "nonote inner [$p]" };
test_test("no note for variable");
 

