use Test2::V0;

use Test2::Harness2::ChildSubReaper qw/have_subreaper_support subreaper_mechanism/;

my $have = have_subreaper_support();
my $mech = subreaper_mechanism();

# The core invariant: the two functions must agree on whether a
# backend compiled in. Normalize both sides to 0/1 so the string-eq
# compare used by is() doesn't trip over "" vs "0".
is($have ? 1 : 0, defined($mech) ? 1 : 0,
   'have_subreaper_support() truthiness matches defined(subreaper_mechanism())');

# If a backend is present, the mechanism label must be one of the
# known strings. New backends added later should extend this list.
if (defined $mech) {
    my %known = map { $_ => 1 } qw/prctl procctl/;
    ok($known{$mech}, "subreaper_mechanism() returned a known backend (got: '$mech')");
}
else {
    pass("no backend compiled in; nothing further to check");
}

done_testing;
