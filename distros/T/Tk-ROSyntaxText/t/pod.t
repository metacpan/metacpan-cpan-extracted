#!perl -T

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

BEGIN {
    if (! $ENV{CPAN_TEST_AUTHOR}) {
        plan skip_all
            => q[Author test.]
             . q[ To run: set $ENV{CPAN_TEST_AUTHOR} to a TRUE value.];
    }
}

eval {
    use Test::Pod 1.14;
};

if ($EVAL_ERROR) {
    plan skip_all
        => q{Test::Pod 1.14 required for testing POD};
}

all_pod_files_ok();

