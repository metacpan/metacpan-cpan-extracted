#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

SKIP: {
    skip 'Skipping release tests', 1 unless $ENV{RELEASE_TESTING};

    eval "use Test::Pod::Coverage;";
    pod_coverage_ok($_, { trustme => [qr/BUILDARGS/] }) for grep {!/Role/} all_modules();
}

done_testing();
