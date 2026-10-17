#!perl -T

use strict;
use warnings;

use Test::More;

use URI::VersionRange::Util qw(semver_version_compare version_compare);

#<<<
my @test_cases = (
    # equal – base & build metadata ignored
    ["1.0.0",                   "1.0.0",            0],
    ["1.0.0+20130313144700",    "1.0.0",            0],
    ["1.0.0+exp.sha.5114f85",   "1.0.0+build.1",    0],
    ["2.1.0",                   "2.1.0",            0],
    ["0.0.0",                   "0.0.0",            0],

    # major/minor/patch ordering
    ["1.0.0",   "2.0.0",    -1],
    ["2.0.0",   "1.0.0",    1],
    ["2.1.0",   "2.2.0",    -1],
    ["2.2.0",   "2.1.0",    1],
    ["2.1.0",   "2.1.1",    -1],
    ["2.1.1",   "2.1.0",    1],
    ["1.9.9",   "1.10.0",   -1],
    ["1.10.0",  "1.9.9",    1],

    # prerelease < release
    ["1.0.0-alpha", "1.0.0",        -1],
    ["1.0.0-rc.1",  "1.0.0",        -1],
    ["1.0.0-rc.1",  "1.0.0-rc.1",   0],

    # prerelease chain (numeric vs alphabetic; length)
    ["1.0.0-alpha",      "1.0.0-alpha.1",       -1],
    ["1.0.0-alpha.1",    "1.0.0-alpha.beta",    -1],
    ["1.0.0-alpha.beta", "1.0.0-beta",          -1],
    ["1.0.0-beta",       "1.0.0-beta.2",        -1],
    ["1.0.0-beta.2",     "1.0.0-beta.11",       -1],
    ["1.0.0-beta.11",    "1.0.0-rc.1",          -1],
    ["1.0.0-rc.1",       "1.0.0",               -1],

    # the same but reversed ( > )
    ["1.0.0-alpha.1",       "1.0.0-alpha",      1],
    ["1.0.0-alpha.beta",    "1.0.0-alpha.1",    1],
    ["1.0.0-beta",          "1.0.0-alpha.beta", 1],
    ["1.0.0-beta.2",        "1.0.0-beta",       1],
    ["1.0.0-beta.11",       "1.0.0-beta.2",     1],
    ["1.0.0-rc.1",          "1.0.0-beta.11",    1],
    ["1.0.0",               "1.0.0-rc.1",       1],

    # numeric vs alphanumeric in prerelease tokens
    ["1.0.0-alpha.10",  "1.0.0-alpha.2",    1],   # 10 > 2 (numeric)
    ["1.0.0-alpha.2",   "1.0.0-alpha.10",   -1],
    ["1.0.0-alpha.1",   "1.0.0-alpha.a",    -1],  # numeric < alphanumeric
    ["1.0.0-alpha.a",   "1.0.0-alpha.1",    1],

    # length comparison when prefixes are equal
    ["1.0.0-alpha",     "1.0.0-alpha.0",    -1], # shorter < longer
    ["1.0.0-alpha.0",   "1.0.0-alpha",      1],
    ["1.0.0-a.b",       "1.0.0-a.b.c",      -1],
    ["1.0.0-a.b.c",     "1.0.0-a.b",        1],

    # complex mixes (from the common node-semver suite)
    ["1.2.3-a.10",          "1.2.3-a.5",            1],
    ["1.2.3-a.b",           "1.2.3-a.5",            1], # alpha > numeric
    ["1.2.3-a.b",           "1.2.3-a",              1], # extra token => greater
    ["1.2.3-a.b.c.10.d.5",  "1.2.3-a.b.c.5.d.100",  1],

    # shorthand equivalences (not in pure standard, but often supported)
    ["1.0", "1.0.0",    0],
    ["1",   "1.0.0",    0],

    # build metadata with prerelease (ignored)
    ["1.0.0-beta+exp.sha",  "1.0.0-beta+abc",   0],
    ["1.0.0+exp.sha",       "1.0.0",            0],
);
#>>>

my %COMPARATORS = (
    'semver_version_compare'   => \&semver_version_compare,
    'version_compare (semver)' => sub { version_compare('semver', @_) },
    'version_compare (npm)'    => sub { version_compare('npm',    @_) },
);

foreach my $test (@test_cases) {

    my ($a, $b, $expected) = @{$test};
    my $rev_expected = -$expected;

    my $test_label     = "$a <=> $b == $expected";
    my $rev_test_label = "$b <=> $a == $rev_expected (reverse test)";

    foreach my $name (keys %COMPARATORS) {

        my $comparator = $COMPARATORS{$name};

        subtest "$name: $test_label" => sub {
            my $got     = $comparator->($a, $b);
            my $rev_got = $comparator->($b, $a);

            is($got,     $expected,     $test_label);
            is($rev_got, $rev_expected, $rev_test_label);
        };

    }

}

done_testing();
