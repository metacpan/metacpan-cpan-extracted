use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test2/Event/Warning.pm',
    'lib/Test2/Plugin/NoWarnings.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/compile.t',
    't/tap-bug-in-test2.t',
    't/warnings-after-done.t'
);

notabs_ok($_) foreach @files;
done_testing;
