#!perl -T

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
