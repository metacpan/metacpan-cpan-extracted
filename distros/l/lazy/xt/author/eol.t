use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/lazy.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/load.t',
    't/local-install-via-args.t',
    't/test-data/darkpan/authors/01mailrc.txt',
    't/test-data/darkpan/modules/02STAMP',
    't/test-data/darkpan/modules/02packages.details.txt',
    't/test-data/darkpan/modules/06perms.txt'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
