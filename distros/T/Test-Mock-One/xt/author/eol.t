use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Mock/One.pm',
    'lib/Test/Mock/Two.pm',
    't/00-compile.t',
    't/001-mock.t',
    't/002-mock.t',
    't/lib/Test/Mock/Testsuite.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
