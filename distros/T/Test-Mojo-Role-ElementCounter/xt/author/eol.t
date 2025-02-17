use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Mojo/Role/ElementCounter.pm',
    't/00-compile.t',
    't/01-tester.t',
    't/02-element-counter.t',
    't/Test/MyApp.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
