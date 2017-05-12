# $Id: pod-coverage.t 4 2006-05-12 20:18:10Z rmuhle $

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all =>
    "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
