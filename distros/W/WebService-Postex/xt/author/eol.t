use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WebService/Postex.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-bug-baseuri-context.t',
    't/03-lwp-injection.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
