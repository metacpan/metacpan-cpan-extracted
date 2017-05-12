#!perl -T

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More;

BEGIN {
    if (! $ENV{CPAN_TEST_AUTHOR}) {
        plan skip_all
            => q[Author test.]
             . q[ To run: set $ENV{CPAN_TEST_AUTHOR} to a TRUE value.];
    }
}

eval {
    use Test::Pod::Coverage 1.04;
};

if ($EVAL_ERROR) {
    plan skip_all
        => q{Test::Pod::Coverage 1.04 required for testing POD coverage};
}

all_pod_coverage_ok({
    also_private => [
        qr{\A Populate \z}msx,
    ]
});
