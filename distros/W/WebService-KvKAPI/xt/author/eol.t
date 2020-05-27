use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/query_kvk.pl',
    'lib/WebService/KvKAPI.pm',
    'lib/WebService/KvKAPI/Spoof.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-spoof.t',
    't/03-host-override.t',
    't/04-mangle-params.t',
    't/9999-live-test.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
