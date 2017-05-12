use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/TempDir.pm',
    'lib/Test/TempDir/Factory.pm',
    'lib/Test/TempDir/Handle.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_load.t',
    't/basic.t',
    't/directory_scratch.t',
    't/factory.t',
    't/handle.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
