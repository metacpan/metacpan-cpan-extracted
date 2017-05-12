#!/usr/bin/perl -w
# -*- coding: utf-8; -*-

=head1 NAME

80-subtest-external.t - Testing Test::Group without using it in the test
suite, with use_subtest() set.

=cut

use strict;
use warnings;

use Test::Builder;

BEGIN {
    my $T = Test::Builder->new;
    $T->can('subtest') or $T->skip_all('Test::Builder too old');
}
       
use Test::More tests => 22;
use lib "t/lib";
use testlib;

ok(my $perl = perl_cmd);

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "passing test group";
use Test::More tests=>1;
use Test::Group;
Test::Group->use_subtest;
test      "group", sub {
    ok 1;
    like   "blah blah blah", qr/bla/;
    unlike "blah blah blah", qr/bli/;
    foreach my $i (0..5) {
        cmp_ok $i**2, '==', $i*$i;
    }
};
EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<EOOUT;
1..1
    ok 1
    ok 2
    ok 3
    ok 4
    ok 5
    ok 6
    ok 7
    ok 8
    ok 9
    1..9
ok 1 - group
EOOUT
is scalar($perl->stderr()), "";

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "failing test group";
use Test::More tests=>1;
use Test::Group;
Test::Group->use_subtest;
test      "group", sub {
    is "bla", "ble";
    ok 0, "sub test blah";
    ok 0;
    like   "blah blah blah", qr/bli/;
};
EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<EOOUT;
1..1
    not ok 1
    not ok 2 - sub test blah
    not ok 3
    not ok 4
    1..4
not ok 1 - group
EOOUT
like scalar($perl->stderr()), qr/got:.*bla/, "got bla";
like scalar($perl->stderr()), qr/expected:.*ble/, "expected ble";
like scalar($perl->stderr()), qr/failed.*sub test blah/i, "another subtest failed";
like scalar($perl->stderr()), qr/failed 1 test.* of 1/,
    "1 test total despite multiple failures";

ok $perl->run(stdin => <<'EOSCRIPT') >> 8, "empty test group fails";
use Test::More tests => 2;
use Test::Group;
Test::Group->use_subtest;
test      "empty group", sub {
    1;
};
EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<EOOUT, "empty test groups";
1..2
    1..0
not ok 1 - No tests run for subtest "empty group"
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "test_only";
use Test::More tests => 2;
use Test::Group;

Test::Group->use_subtest;

test_only "group 1", "<reason>";

test      "group 1", sub {
    pass;
};
test      "group 2", sub {
    fail;
};
EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<EOOUT;
1..2
    ok 1
    1..1
ok 1 - group 1
ok 2 # skip <reason>
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "test_only regex";
use Test::More tests => 3;
use Test::Group;

Test::Group->use_subtest;

test_only qr/^group/, "<reason>";

test      "group 1", sub {
    pass;
};
test      "group 2", sub {
    fail;
};
test      "other group", sub {
    fail;
};
EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<EOOUT;
1..3
    ok 1
    1..1
ok 1 - group 1
    not ok 1
    1..1
not ok 2 - group 2
ok 3 # skip <reason>
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "skip_next_tests";
use Test::More tests => 3;
use Test::Group;

Test::Group->use_subtest;

skip_next_tests 2, "<reason>";

test      "group 1", sub {
    1;
};
test      "group 2", sub {
    0;
};
test      "other group", sub {
    0;
};
EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<EOOUT;
1..3
ok 1 # skip <reason>
ok 2 # skip <reason>
    1..0
not ok 3 - No tests run for subtest "other group"
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "begin_skipping_tests";
use Test::More tests => 3;
use Test::Group;

Test::Group->use_subtest;

begin_skipping_tests "<reason>";
test      "group 1", sub {
    1;
};
test      "group 2", sub {
    0;
};
end_skipping_tests "<reason>";
test      "other group", sub {
    0;
};
EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<EOOUT;
1..3
ok 1 # skip <reason>
ok 2 # skip <reason>
    1..0
not ok 3 - No tests run for subtest "other group"
EOOUT


is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "nested tests";
use Test::More tests => 2;
use Test::Group;

Test::Group->use_subtest;

test "outer 1" => sub {
    test "inner 1" => sub {
       pass;
    };
    test "inner 2" => sub {
       pass;
    };
};

test "outer 2" => sub {
    test "inner 1" => sub {
       fail;
    };
    test "inner 2" => sub {
       pass;
    };
};

EOSCRIPT
is canonicalize_tap(scalar($perl->stdout())), <<"EOOUT" or warn $perl->stderr;
1..2
        ok 1
        1..1
    ok 1 - inner 1
        ok 1
        1..1
    ok 2 - inner 2
    1..2
ok 1 - outer 1
        not ok 1
        1..1
    not ok 1 - inner 1
        ok 1
        1..1
    ok 2 - inner 2
    1..2
not ok 2 - outer 2
EOOUT

1;
