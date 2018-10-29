use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/query_openkvk.pl',
    'lib/WebService/OverheidIO.pm',
    'lib/WebService/OverheidIO/BAG.pm',
    'lib/WebService/OverheidIO/KvK.pm',
    't/00-compile.t',
    't/100-base-model.t',
    't/150-kvk.t',
    't/200-bag.t',
    't/999-livetests.t',
    't/data/search_bag.json',
    't/data/search_kvk.json'
);

notabs_ok($_) foreach @files;
done_testing;
