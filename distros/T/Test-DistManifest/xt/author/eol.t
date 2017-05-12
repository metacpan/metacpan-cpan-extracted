use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/DistManifest.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02manifest.t',
    't/03core.t',
    't/04warn-only.t',
    't/05-no-manifest.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
