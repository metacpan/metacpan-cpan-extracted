use Test2::V0;

use Test2::Harness2::ChildSubReaper qw/have_subreaper_support subreaper_mechanism/;

# Platforms where a backend COULD compile in, and the mechanism label
# we expect when it does.
my %expected_mech = (
    linux     => 'prctl',
    freebsd   => 'procctl',
    dragonfly => 'procctl',
);

my $have = have_subreaper_support();
my $mech = subreaper_mechanism();

# Invariant that must always hold, regardless of platform.
# Normalize both sides to 0/1 so the string-eq compare used by is()
# doesn't trip over "" (Perl's canonical false) vs "0".
is($have ? 1 : 0, defined($mech) ? 1 : 0,
   'have_subreaper_support() and subreaper_mechanism() agree');

if (my $want = $expected_mech{$^O}) {
    if ($have) {
        is($mech, $want,
           "$^O build advertises '$want' support");
    }
    else {
        # A supported-in-theory platform that compiled without support.
        # This typically means the build environment's system headers
        # lacked the relevant macro (very old Linux, very old FreeBSD).
        # Not a test failure — just a diagnostic.
        diag("$^O build did NOT compile in subreaper support");
        diag("(expected '$want' backend, but the relevant kernel macro");
        diag(" was missing at compile time — check system headers)");
        pass("$^O build without support: invariants hold");
    }
}
else {
    ok(!$have,          "$^O build does not advertise support");
    ok(!defined($mech), "$^O build has no mechanism string");
}

done_testing;
