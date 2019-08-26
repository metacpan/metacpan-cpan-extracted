use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/TrailingSpace.pm',
    't/00-compile.t',
    't/dogfood.t',
    't/lib/File/Find/Object/TreeCreate.pm',
    't/object-test.t',
    't/sample-data/PLACEHOLDER'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
