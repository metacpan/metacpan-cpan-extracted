#!perl -T

use strict;
use warnings;

use Test::More;

use Version::libversion::XS qw(:all);

# Taken from libversion/tests/compare_test.c

subtest "Test group: equality" => sub {
    is(version_compare("0",           "0"),           0);
    is(version_compare("0a",          "0a"),          0);
    is(version_compare("a",           "a"),           0);
    is(version_compare("a0",          "a0"),          0);
    is(version_compare("0a1",         "0a1"),         0);
    is(version_compare("0a1b2",       "0a1b2"),       0);
    is(version_compare("1alpha1",     "1alpha1"),     0);
    is(version_compare("foo",         "foo"),         0);
    is(version_compare("1.2.3",       "1.2.3"),       0);
    is(version_compare("hello.world", "hello.world"), 0);
};

subtest "Test group: different number of components" => sub {
    is(version_compare("1",   "1.0"),             0);
    is(version_compare("1",   "1.0.0"),           0);
    is(version_compare("1.0", "1.0.0"),           0);
    is(version_compare("1.0", "1.0.0.0.0.0.0.0"), 0);
};

subtest "Test group: leading zeroes" => sub {
    is(version_compare("00100.00100", "100.100"),           0);
    is(version_compare("0",           "00000000000000000"), 0);
};

subtest "Test group: simple comparisons" => sub {
    is(version_compare("0.0.0",          "0.0.1"),   -1);
    is(version_compare("0.0.1",          "0.0.2"),   -1);
    is(version_compare("0.0.2",          "0.0.10"),  -1);
    is(version_compare("0.0.2",          "0.1.0"),   -1);
    is(version_compare("0.0.10",         "0.1.0"),   -1);
    is(version_compare("0.1.0",          "0.1.1"),   -1);
    is(version_compare("0.1.1",          "1.0.0"),   -1);
    is(version_compare("1.0.0",          "10.0.0"),  -1);
    is(version_compare("10.0.0",         "100.0.0"), -1);
    is(version_compare("10.10000.10000", "11.0.0"),  -1);
};

subtest "Test group: long numbers" => sub {
    is(version_compare("20160101",           "20160102"),            -1);
    is(version_compare("999999999999999999", "1000000000000000000"), -1);
};

subtest "Test group: very long numbers" => sub {
    is(version_compare("99999999999999999999999999999999999998", "99999999999999999999999999999999999999"), -1);
};

subtest "Test group: letter addendum" => sub {
    is(version_compare("1.0",  "1.0a"), -1);
    is(version_compare("1.0a", "1.0b"), -1);
    is(version_compare("1.0b", "1.1"),  -1);
};

subtest "Test group: letter vs. number" => sub {
    is(version_compare("a",   "0"),   -1);
    is(version_compare("1.a", "1.0"), -1);
};

subtest "Test group: letter-only component" => sub {
    is(version_compare("1.0.a", "1.0.b"), -1);
    is(version_compare("1.0.b", "1.0.c"), -1);
    is(version_compare("1.0.c", "1.0"),   -1);
    is(version_compare("1.0.c", "1.0.0"), -1);
};

subtest "Test group: letter component split" => sub {
    is(version_compare("1.0a0",    "1.0.a0"), 0);
    is(version_compare("1.0beta3", "1.0.b3"), 0);
};

subtest "Test group: case is ignored" => sub {
    is(version_compare("a",      "A"),      0);
    is(version_compare("1alpha", "1ALPHA"), 0);
    is(version_compare("alpha1", "ALPHA1"), 0);
};

subtest "Test group: strings are shortened to one letter" => sub {
    is(version_compare("a", "alpha"),      0);
    is(version_compare("b", "beta"),       0);
    is(version_compare("p", "prerelease"), 0);
};

subtest "Test group: unusial component separators" => sub {
    is(version_compare("1.0.alpha.2", "1_0_alpha_2"), 0);
    is(version_compare("1.0.alpha.2", "1-0-alpha-2"), 0);
    is(version_compare("1.0.alpha.2", "1,0:alpha~2"), 0);
};

subtest "Test group: multiple consequentional separators" => sub {
    is(version_compare("..1....2....3..", "1.2.3"), 0);
    is(version_compare(".-~1~-.-~2~-.",   "1.2"),   0);
    is(version_compare(".,:;~+-_",        "0"),     0);
};

subtest "Test group: empty string" => sub {
    is(version_compare("", ""),  0);
    is(version_compare("", "0"), 0);
    is(version_compare("", "1"), -1);
};

subtest "Test group: prerelease sequence" => sub {

#  XXX: is rc/pre ordering defined?
    is(version_compare("1.0alpha1", "1.0alpha2"), -1);
    is(version_compare("1.0alpha2", "1.0beta1"),  -1);
    is(version_compare("1.0beta1",  "1.0beta2"),  -1);
    is(version_compare("1.0beta2",  "1.0rc1"),    -1);
    is(version_compare("1.0beta2",  "1.0pre1"),   -1);
    is(version_compare("1.0rc1",    "1.0"),       -1);
    is(version_compare("1.0pre1",   "1.0"),       -1);

    is(version_compare("1.0.alpha1", "1.0.alpha2"), -1);
    is(version_compare("1.0.alpha2", "1.0.beta1"),  -1);
    is(version_compare("1.0.beta1",  "1.0.beta2"),  -1);
    is(version_compare("1.0.beta2",  "1.0.rc1"),    -1);
    is(version_compare("1.0.beta2",  "1.0.pre1"),   -1);
    is(version_compare("1.0.rc1",    "1.0"),        -1);
    is(version_compare("1.0.pre1",   "1.0"),        -1);

    is(version_compare("1.0alpha.1", "1.0alpha.2"), -1);
    is(version_compare("1.0alpha.2", "1.0beta.1"),  -1);
    is(version_compare("1.0beta.1",  "1.0beta.2"),  -1);
    is(version_compare("1.0beta.2",  "1.0rc.1"),    -1);
    is(version_compare("1.0beta.2",  "1.0pre.1"),   -1);
    is(version_compare("1.0rc.1",    "1.0"),        -1);
    is(version_compare("1.0pre.1",   "1.0"),        -1);

    is(version_compare("1.0.alpha.1", "1.0.alpha.2"), -1);
    is(version_compare("1.0.alpha.2", "1.0.beta.1"),  -1);
    is(version_compare("1.0.beta.1",  "1.0.beta.2"),  -1);
    is(version_compare("1.0.beta.2",  "1.0.rc.1"),    -1);
    is(version_compare("1.0.beta.2",  "1.0.pre.1"),   -1);
    is(version_compare("1.0.rc.1",    "1.0"),         -1);
    is(version_compare("1.0.pre.1",   "1.0"),         -1);
};

subtest "Test group: long word awareness" => sub {

#  this should not be treated as 1.0a-1
    is(version_compare("1.0alpha-1", "0.9"),   1);
    is(version_compare("1.0alpha-1", "1.0"),   -1);
    is(version_compare("1.0alpha-1", "1.0.1"), -1);
    is(version_compare("1.0alpha-1", "1.1"),   -1);

    is(version_compare("1.0beta-1", "0.9"),   1);
    is(version_compare("1.0beta-1", "1.0"),   -1);
    is(version_compare("1.0beta-1", "1.0.1"), -1);
    is(version_compare("1.0beta-1", "1.1"),   -1);

    is(version_compare("1.0pre-1", "0.9"),   1);
    is(version_compare("1.0pre-1", "1.0"),   -1);
    is(version_compare("1.0pre-1", "1.0.1"), -1);
    is(version_compare("1.0pre-1", "1.1"),   -1);

    is(version_compare("1.0prerelease-1", "0.9"),   1);
    is(version_compare("1.0prerelease-1", "1.0"),   -1);
    is(version_compare("1.0prerelease-1", "1.0.1"), -1);
    is(version_compare("1.0prerelease-1", "1.1"),   -1);

    is(version_compare("1.0rc-1", "0.9"),   1);
    is(version_compare("1.0rc-1", "1.0"),   -1);
    is(version_compare("1.0rc-1", "1.0.1"), -1);
    is(version_compare("1.0rc-1", "1.1"),   -1);
};

subtest "Test group: post-release keyword awareness" => sub {

#  this should not be treated as 1.0a-1
    is(version_compare("1.0patch1", "0.9"),   1);
    is(version_compare("1.0patch1", "1.0"),   1);
    is(version_compare("1.0patch1", "1.0.1"), -1);
    is(version_compare("1.0patch1", "1.1"),   -1);

    is(version_compare("1.0.patch1", "0.9"),   1);
    is(version_compare("1.0.patch1", "1.0"),   1);
    is(version_compare("1.0.patch1", "1.0.1"), -1);
    is(version_compare("1.0.patch1", "1.1"),   -1);

    is(version_compare("1.0patch.1", "0.9"),   1);
    is(version_compare("1.0patch.1", "1.0"),   1);
    is(version_compare("1.0patch.1", "1.0.1"), -1);
    is(version_compare("1.0patch.1", "1.1"),   -1);

    is(version_compare("1.0.patch.1", "0.9"),   1);
    is(version_compare("1.0.patch.1", "1.0"),   1);
    is(version_compare("1.0.patch.1", "1.0.1"), -1);
    is(version_compare("1.0.patch.1", "1.1"),   -1);

    is(version_compare("1.0post1", "0.9"),   1);
    is(version_compare("1.0post1", "1.0"),   1);
    is(version_compare("1.0post1", "1.0.1"), -1);
    is(version_compare("1.0post1", "1.1"),   -1);

    is(version_compare("1.0postanythinggoeshere1", "0.9"),   1);
    is(version_compare("1.0postanythinggoeshere1", "1.0"),   1);
    is(version_compare("1.0postanythinggoeshere1", "1.0.1"), -1);
    is(version_compare("1.0postanythinggoeshere1", "1.1"),   -1);

    is(version_compare("1.0pl1", "0.9"),   1);
    is(version_compare("1.0pl1", "1.0"),   1);
    is(version_compare("1.0pl1", "1.0.1"), -1);
    is(version_compare("1.0pl1", "1.1"),   -1);

    is(version_compare("1.0errata1", "0.9"),   1);
    is(version_compare("1.0errata1", "1.0"),   1);
    is(version_compare("1.0errata1", "1.0.1"), -1);
    is(version_compare("1.0errata1", "1.1"),   -1);
};

subtest "Test group: p is patch flag" => sub {
    is(version_compare("1.0p1", "1.0p1", 0,          0),          0);
    is(version_compare("1.0p1", "1.0p1", P_IS_PATCH, P_IS_PATCH), 0);
    is(version_compare("1.0p1", "1.0p1", P_IS_PATCH, 0),          1);
    is(version_compare("1.0p1", "1.0p1", 0,          P_IS_PATCH), -1);

    is(version_compare("1.0p1", "1.0P1", 0,          0),          0);
    is(version_compare("1.0p1", "1.0P1", P_IS_PATCH, P_IS_PATCH), 0);

    is(version_compare("1.0", "1.0p1", 0,          0),          1);
    is(version_compare("1.0", "1.0p1", P_IS_PATCH, 0),          1);
    is(version_compare("1.0", "1.0p1", 0,          P_IS_PATCH), -1);

    is(version_compare("1.0", "1.0.p1", 0,          0),          1);
    is(version_compare("1.0", "1.0.p1", P_IS_PATCH, 0),          1);
    is(version_compare("1.0", "1.0.p1", 0,          P_IS_PATCH), -1);

    is(version_compare("1.0", "1.0.p.1", 0,          0),          1);
    is(version_compare("1.0", "1.0.p.1", P_IS_PATCH, 0),          1);
    is(version_compare("1.0", "1.0.p.1", 0,          P_IS_PATCH), -1);

#  this case is not affected
    is(version_compare("1.0", "1.0p.1", 0,          0),          -1);
    is(version_compare("1.0", "1.0p.1", P_IS_PATCH, 0),          -1);
    is(version_compare("1.0", "1.0p.1", 0,          P_IS_PATCH), -1);
};

subtest "Test group: any is patch flag" => sub {
    is(version_compare("1.0a1", "1.0a1", 0,            0),            0);
    is(version_compare("1.0a1", "1.0a1", ANY_IS_PATCH, ANY_IS_PATCH), 0);
    is(version_compare("1.0a1", "1.0a1", ANY_IS_PATCH, 0),            1);
    is(version_compare("1.0a1", "1.0a1", 0,            ANY_IS_PATCH), -1);

    is(version_compare("1.0", "1.0a1", 0,            0),            1);
    is(version_compare("1.0", "1.0a1", ANY_IS_PATCH, 0),            1);
    is(version_compare("1.0", "1.0a1", 0,            ANY_IS_PATCH), -1);

    is(version_compare("1.0", "1.0.a1", 0,            0),            1);
    is(version_compare("1.0", "1.0.a1", ANY_IS_PATCH, 0),            1);
    is(version_compare("1.0", "1.0.a1", 0,            ANY_IS_PATCH), -1);

    is(version_compare("1.0", "1.0.a.1", 0,            0),            1);
    is(version_compare("1.0", "1.0.a.1", ANY_IS_PATCH, 0),            1);
    is(version_compare("1.0", "1.0.a.1", 0,            ANY_IS_PATCH), -1);

#  this case is not affected
    is(version_compare("1.0", "1.0a.1", 0,            0),            -1);
    is(version_compare("1.0", "1.0a.1", ANY_IS_PATCH, 0),            -1);
    is(version_compare("1.0", "1.0a.1", 0,            ANY_IS_PATCH), -1);
};

subtest "Test group: p/patch compatibility" => sub {
    is(version_compare("1.0p1", "1.0pre1",   0, 0), 0);
    is(version_compare("1.0p1", "1.0patch1", 0, 0), -1);
    is(version_compare("1.0p1", "1.0post1",  0, 0), -1);

    is(version_compare("1.0p1", "1.0pre1",   P_IS_PATCH, P_IS_PATCH), 1);
    is(version_compare("1.0p1", "1.0patch1", P_IS_PATCH, P_IS_PATCH), 0);
    is(version_compare("1.0p1", "1.0post1",  P_IS_PATCH, P_IS_PATCH), 0);
};

subtest "Test group: prerelease words without numbers" => sub {
    is(version_compare("1.0alpha",  "1.0"), -1);
    is(version_compare("1.0.alpha", "1.0"), -1);

    is(version_compare("1.0beta",  "1.0"), -1);
    is(version_compare("1.0.beta", "1.0"), -1);

    is(version_compare("1.0rc",  "1.0"), -1);
    is(version_compare("1.0.rc", "1.0"), -1);

    is(version_compare("1.0pre",  "1.0"), -1);
    is(version_compare("1.0.pre", "1.0"), -1);

    is(version_compare("1.0prerelese",  "1.0"), -1);
    is(version_compare("1.0.prerelese", "1.0"), -1);

    is(version_compare("1.0patch",  "1.0"), 1);
    is(version_compare("1.0.patch", "1.0"), 1);
};

subtest "Test group: release bounds" => sub {
    is(version_compare("0.99999",   "1.0", 0, 0), -1);
    is(version_compare("1.0alpha",  "1.0", 0, 0), -1);
    is(version_compare("1.0alpha0", "1.0", 0, 0), -1);
    is(version_compare("1.0",       "1.0", 0, 0), 0);
    is(version_compare("1.0patch",  "1.0", 0, 0), 1);
    is(version_compare("1.0patch0", "1.0", 0, 0), 1);
    is(version_compare("1.0.1",     "1.0", 0, 0), 1);
    is(version_compare("1.1",       "1.0", 0, 0), 1);

    is(version_compare("0.99999",   "1.0", 0, LOWER_BOUND), -1);
    is(version_compare("1.0alpha",  "1.0", 0, LOWER_BOUND), 1);
    is(version_compare("1.0alpha0", "1.0", 0, LOWER_BOUND), 1);
    is(version_compare("1.0",       "1.0", 0, LOWER_BOUND), 1);
    is(version_compare("1.0patch",  "1.0", 0, LOWER_BOUND), 1);
    is(version_compare("1.0patch0", "1.0", 0, LOWER_BOUND), 1);
    is(version_compare("1.0a",      "1.0", 0, LOWER_BOUND), 1);
    is(version_compare("1.0.1",     "1.0", 0, LOWER_BOUND), 1);
    is(version_compare("1.1",       "1.0", 0, LOWER_BOUND), 1);

    is(version_compare("0.99999",   "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.0alpha",  "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.0alpha0", "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.0",       "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.0patch",  "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.0patch0", "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.0a",      "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.0.1",     "1.0", 0, UPPER_BOUND), -1);
    is(version_compare("1.1",       "1.0", 0, UPPER_BOUND), 1);

    is(version_compare("1.0", "1.0", LOWER_BOUND, LOWER_BOUND), 0);
    is(version_compare("1.0", "1.0", UPPER_BOUND, UPPER_BOUND), 0);
    is(version_compare("1.0", "1.0", LOWER_BOUND, UPPER_BOUND), -1);

    is(version_compare("1.0", "1.1", UPPER_BOUND, LOWER_BOUND), -1);

    is(version_compare("0", "0.0", UPPER_BOUND, UPPER_BOUND), 1);
    is(version_compare("0", "0.0", LOWER_BOUND, LOWER_BOUND), -1);
};

subtest "Test group: uniform component splitting" => sub {
    is(version_compare("1.0alpha1", "1.0alpha1"),   0);
    is(version_compare("1.0alpha1", "1.0.alpha1"),  0);
    is(version_compare("1.0alpha1", "1.0alpha.1"),  0);
    is(version_compare("1.0alpha1", "1.0.alpha.1"), 0);

    is(version_compare("1.0patch1", "1.0patch1"),   0);
    is(version_compare("1.0patch1", "1.0.patch1"),  0);
    is(version_compare("1.0patch1", "1.0patch.1"),  0);
    is(version_compare("1.0patch1", "1.0.patch.1"), 0);
};

done_testing();
