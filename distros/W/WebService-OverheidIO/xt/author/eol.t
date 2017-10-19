use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
