#!/usr/bin/perl -w
# -*- coding: utf-8; -*-

=head1 NAME

10-external.t - Testing Test::Group without using it in the test suite
(which is arguably less fun, but also more robust).

=cut

use Test::More tests => 36; # Sorry, no_plan not portable for Perl 5.6.1!
use lib "t/lib";
use testlib;

use strict;
use warnings;

ok(my $perl = perl_cmd);

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "passing test group";
use Test::More tests=>1;
use Test::Group;
test      "group", sub {
    ok 1;
    like   "blah blah blah", qr/bla/;
    unlike "blah blah blah", qr/bli/;
    foreach my $i (0..5) {
        cmp_ok $i**2, '==', $i*$i;
    }
};
EOSCRIPT
is scalar($perl->stdout()), <<EOOUT;
1..1
ok 1 - group
EOOUT
is scalar($perl->stderr()), "";

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "failing test group";
use Test::More tests=>1;
use Test::Group;
test      "group", sub {
    is "bla", "ble";
    ok 0, "sub test blah";
    ok 0;
    like   "blah blah blah", qr/bli/;
};
EOSCRIPT
is scalar($perl->stdout()), <<EOOUT;
1..1
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
test      "empty group", sub {
    1;
};
EOSCRIPT
is scalar($perl->stdout()), <<EOOUT, "empty test groups";
1..2
not ok 1 - empty group
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "TODO tests";
use Test::More tests => 2;
use Test::Group;

test "TODO: this test is not implemented" => sub {
    fail;
};
test "neither is this one" => sub {
    local $TODO = "UNIMPLEMENTED";
    fail;
};

EOSCRIPT

like scalar($perl->stdout()), qr/not ok 1.*# TODO/, "TODO test by the title";
like scalar($perl->stdout()), qr/not ok 2.*# TODO/, "TODO test w/ local \$TODO";

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "test_only";
use Test::More tests => 2;
use Test::Group;

test_only "group 1", "<reason>";

test      "group 1", sub {
    pass;
};
test      "group 2", sub {
    fail;
};
EOSCRIPT
is scalar($perl->stdout()), <<EOOUT;
1..2
ok 1 - group 1
ok 2 # skip <reason>
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "test_only regex";
use Test::More tests => 3;
use Test::Group;

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
is scalar($perl->stdout()), <<EOOUT;
1..3
ok 1 - group 1
not ok 2 - group 2
ok 3 # skip <reason>
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "skip_next_tests";
use Test::More tests => 3;
use Test::Group;

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
is scalar($perl->stdout()), <<EOOUT;
1..3
ok 1 # skip <reason>
ok 2 # skip <reason>
not ok 3 - other group
EOOUT

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "begin_skipping_tests";
use Test::More tests => 3;
use Test::Group;

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
is scalar($perl->stdout()), <<EOOUT;
1..3
ok 1 # skip <reason>
ok 2 # skip <reason>
not ok 3 - other group
EOOUT

ok $perl->run(stdin => <<'EOSCRIPT') >> 8, "dont_catch_exceptions";
use Test::More tests => 1;
use Test::Group;
Test::Group->dont_catch_exceptions();

test      "group 1", sub {
    die "coucou";
};
print "zut";
EOSCRIPT
is scalar($perl->stdout()), <<EOOUT;
1..1
EOOUT
like(scalar($perl->stderr()), qr/no tests run|before it could/i);

my $errcode = $perl->run(stdin => <<'EOSCRIPT');
use Test::Group;
use Test::More tests => 2;

test "group 1", sub {
    die "line1\nline2\nline3";
};
test "group 2", sub {
    ok 1;
};
EOSCRIPT
isnt($errcode >> 8, 0, "catch exceptions");
is($errcode & 255, 0, "we don't get signal");
unlike (scalar($perl->stdout()), qr/^line2/m,
        "proper quoting of diagnostic messages");

my $logfile = $perl->workpath("log");  # Careful, may contain
                                       # backslashes under win32!
isnt $perl->run(stdin => <<"EOSCRIPT") >> 8, 0, "catch exceptions";
use Test::More tests => 2;
use Test::Group;

Test::Group->logfile('$logfile');

test "group 1", sub {
    die "line1\nline2\nline3";
};
test "group 2", sub {
    ok 1;
};
EOSCRIPT
like scalar($perl->stdout()), qr/^not ok 1.*\*died\*/m;
like scalar($perl->stdout()), qr/^ok 2/m;

my $contents;
$perl->read(\$contents, 'log');
like($contents, qr/group 1.*died/, "log file 1/2");

like($contents, qr/line1\nline2\nline3/, "log file 2/2");

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "nested tests";
use Test::More tests => 2;
use Test::Group;

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
       die;
    };
    test "inner 2" => sub {
       pass;
    };
};

EOSCRIPT
is scalar($perl->stdout()), <<"EOOUT" or warn $perl->stderr;
1..2
ok 1 - outer 1
not ok 2 - outer 2
EOOUT

1;
