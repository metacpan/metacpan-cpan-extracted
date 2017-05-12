use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Types/XMLSchema.pm',
    't/00-compile.t',
    't/00-load.t',
    't/pod-coverage.t',
    't/pod.t',
    't/types-xmlschema.t'
);

notabs_ok($_) foreach @files;
done_testing;
