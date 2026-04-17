use Test2::V0;

use Test2::Harness2::ChildSubReaper qw/have_subreaper_support/;

my $got = have_subreaper_support();

if ($^O eq 'linux') {
    ok($got, "Linux build advertises subreaper support (got: $got)");
}
else {
    ok(!$got, "$^O build does not advertise subreaper support (got: $got)");
}

done_testing;
