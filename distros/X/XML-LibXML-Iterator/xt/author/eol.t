use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/XML/LibXML/Iterator.pm',
    'lib/XML/LibXML/NodeList/Iterator.pm',
    't/00-compile.t',
    't/01basic.t',
    't/02tree.t',
    't/03list.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
