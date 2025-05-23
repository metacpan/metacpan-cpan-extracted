use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Text/Sprintf/Named.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-use.t',
    't/02-override-param-retrieval.t',
    't/03-incomplete.t',
    't/04-procedural-iface.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
