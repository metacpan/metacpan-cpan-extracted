use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'Test::Pod::Coverage 1.00 not installed; skipping' if $@;

# TODO: remove to_ligature/from_ligature in next release
all_pod_coverage_ok({ trustme => [qw<
    to_ligatures from_ligatures
    to_ligature  from_ligature
>] });
