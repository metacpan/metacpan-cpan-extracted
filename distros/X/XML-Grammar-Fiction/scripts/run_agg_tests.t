# run_agg_tests.t - run the tests under t/ while aggregated to make them
# run faster.
#
# Moose takes a while to load sometimes and it needs to be loaded for every
# script when ran under ./Build runtest.

use strict;
use warnings;
use Test::Aggregate;
use FindBin qw($Bin);
use Path::Class;
use lib dir($Bin)->parent->subdir(qw(t lib))->stringify;

my $aggregate_test_dir = dir($Bin)->parent->subdir('t')->stringify;
# need set_filenames to auto-load fixtures correctly
my $tests = Test::Aggregate
    ->new( { dirs => $aggregate_test_dir, set_filenames => 1, verbose => 0,} );
$tests->run;

done_testing;
