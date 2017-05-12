use strict;
use warnings;

=head1 NAME

70-plugin-plan.t - testing Test::Group::Plan

=cut

use Test::More tests => 1;
use Test::Group;
use Test::Group::Tester;
use lib "t/lib";
use testlib;

testscript_ok('#line '.(__LINE__+1)."\n".<<'EOSCRIPT', 5*5);
use strict;
use warnings;

use Test::More;
use Test::Group qw(:DEFAULT next_test_plugin);
use Test::Group::Plan;

#
# Test each combination of subtests passing/failing and plan good/bad.
#

want_test('pass', 'goodplan_goodtests');
test_plan 2, goodplan_goodtests => sub {
    ok 1, "frist test passes";
    ok 1, "second test passes";
};

want_test('pass', 'plain_test_no_plan');
test plain_test_no_plan => sub {
    ok 1, "goodtest";
};

want_test('fail', 'goodplan_badtests',
    fail_diag("this test fails", 0, __LINE__+4),
    fail_diag("goodplan_badtests", 1, __LINE__+5),
);
test_plan 2, goodplan_badtests => sub {
    ok 0, "this test fails";
    ok 1, "second test passes";
};

want_test('fail', 'badplan_goodtests',
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_goodtests", 1, __LINE__+5),
);
test_plan 3, badplan_goodtests => sub {
    ok 1, "first test passes";
    ok 1, "second test passes";
};

want_test('fail', 'badplan_badtests',
    fail_diag("this test fails", 0, __LINE__+7),
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_badtests", 1, __LINE__+5),
);
test_plan 3, badplan_badtests => sub {
    ok 1, "frist test ok";
    ok 0, "this test fails";
};

#
# Repeat the tests using a plugin that runs the test group twice.
# The plan check should be innermost, so that check should be
# performed twice as well.
#

sub next_test_twice {
    next_test_plugin {
        my $next = shift;

        $next->();
        $next->();
    };
}

next_test_twice();
want_test('pass', 'goodplan_goodtests');
test_plan 2, goodplan_goodtests => sub {
    ok 1, "frist test passes";
    ok 1, "second test passes";
};

next_test_twice();
want_test('pass', 'plain_test_no_plan');
test plain_test_no_plan => sub {
    ok 1, "goodtest";
};

next_test_twice();
want_test('fail', 'goodplan_badtests',
    fail_diag("this test fails", 0, __LINE__+5),
    fail_diag("this test fails", 0, __LINE__+4),
    fail_diag("goodplan_badtests", 1, __LINE__+5),
);
test_plan 2, goodplan_badtests => sub {
    ok 0, "this test fails";
    ok 1, "second test passes";
};

next_test_twice();
want_test('fail', 'badplan_goodtests',
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_goodtests", 1, __LINE__+5),
);
test_plan 3, badplan_goodtests => sub {
    ok 1, "first test passes";
    ok 1, "second test passes";
};

next_test_twice();
want_test('fail', 'badplan_badtests',
    fail_diag("this test fails", 0, __LINE__+10),
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("this test fails", 0, __LINE__+7),
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_badtests", 1, __LINE__+5),
);
test_plan 3, badplan_badtests => sub {
    ok 1, "frist test ok";
    ok 0, "this test fails";
};

#
# Repeat the tests using a Test::Group based predicate from with the
# test code.
#

sub foobar_ok {
    my ($text, $name) = @_;
    $name ||= "foobar_ok";
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test $name => sub {
       local $Test::Group::InPredicate = 1;
       ok $text =~ /foo/, "foo ok";
       ok $text =~ /bar/, "bar ok";
    };
}

want_test('pass', 'goodplan_goodtests_fb');
test_plan 2, goodplan_goodtests_fb => sub {
    foobar_ok("foobar", "frist test passes");
    foobar_ok("foobar", "second test passes");
};

want_test('pass', 'plain_test_no_plan_2');
test plain_test_no_plan_2 => sub {
    ok 1, "goodtest";
};

want_test('fail', 'goodplan_badtests_fb',
    fail_diag("bar ok"),
    fail_diag("this test fails", 0, __LINE__+4),
    fail_diag("goodplan_badtests_fb", 1, __LINE__+5),
);
test_plan 2, goodplan_badtests_fb => sub {
    foobar_ok("foobaz", "this test fails");
    foobar_ok("foobar", "second test passes");
};

want_test('fail', 'badplan_goodtests_fb',
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_goodtests_fb", 1, __LINE__+5),
);
test_plan 3, badplan_goodtests_fb => sub {
    foobar_ok("foobar", "first test passes");
    foobar_ok("foobar", "second test passes");
};

want_test('fail', 'badplan_badtests_fb',
    fail_diag("bar ok"),
    fail_diag("this test fails", 0, __LINE__+7),
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_badtests_fb", 1, __LINE__+5),
);
test_plan 3, badplan_badtests_fb => sub {
    foobar_ok("foobar", "first test passes");
    foobar_ok("foobaz", "this test fails");
};

#
# Repeat the tests using the plugin from within a predicate.
#

sub foobar_ok_p {
    my ($text, $name) = @_;
    $name ||= "foobar_ok";
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test_plan 3, $name => sub {
       local $Test::Group::InPredicate = 1;
       ok $text =~ /foo/, "foo ok";
       ok $text =~ /bar/, "bar ok";
       ok 1, "dummy test" unless $text =~ /badplan/;
    };
}

want_test('pass', 'goodplan_goodtests_fbp');
foobar_ok_p("foobar", 'goodplan_goodtests_fbp');

want_test('pass', 'plain_test_no_plan_3');
test plain_test_no_plan_3 => sub {
    ok 1, "goodtest";
};

want_test('fail', 'goodplan_badtests_fbp',
    fail_diag("bar ok"),
    fail_diag("goodplan_badtests_fbp", 1, __LINE__+2),
);
foobar_ok_p("foobaz", 'goodplan_badtests_fbp');

want_test('fail', 'badplan_goodtests_fbp',
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_goodtests_fbp", 1, __LINE__+2),
);
foobar_ok_p("foobar-badplan", 'badplan_goodtests_fbp');

want_test('fail', 'badplan_badtests_fbp',
    fail_diag("bar ok"),
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_badtests_fbp", 1, __LINE__+2),
);
foobar_ok_p("foobaz-badplan", 'badplan_badtests_fbp');

#
# Repeat with a Test::Builder wrapper around the predicate.
#

sub foobar_ok_p2 {
    my ($text, $name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    foobar_ok_p($text, $name);
}

want_test('pass', 'goodplan_goodtests_fbp');
foobar_ok_p2("foobar", 'goodplan_goodtests_fbp');

want_test('pass', 'plain_test_no_plan_3');
test plain_test_no_plan_3 => sub {
    ok 1, "goodtest";
};

want_test('fail', 'goodplan_badtests_fbp',
    fail_diag("bar ok"),
    fail_diag("goodplan_badtests_fbp", 1, __LINE__+2),
);
foobar_ok_p2("foobaz", 'goodplan_badtests_fbp');

want_test('fail', 'badplan_goodtests_fbp',
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_goodtests_fbp", 1, __LINE__+2),
);
foobar_ok_p2("foobar-badplan", 'badplan_goodtests_fbp');

want_test('fail', 'badplan_badtests_fbp',
    fail_diag("bar ok"),
    fail_diag("group test plan"),
    '#   group planned 3 tests but ran 2',
    fail_diag("badplan_badtests_fbp", 1, __LINE__+2),
);
foobar_ok_p2("foobaz-badplan", 'badplan_badtests_fbp');

EOSCRIPT

