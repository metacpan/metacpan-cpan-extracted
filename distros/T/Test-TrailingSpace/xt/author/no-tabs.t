use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/TrailingSpace.pm',
    't/00-compile.t',
    't/dogfood.t',
    't/lib/File/Find/Object/TreeCreate.pm',
    't/object-test.t',
    't/sample-data/PLACEHOLDER'
);

notabs_ok($_) foreach @files;
done_testing;
