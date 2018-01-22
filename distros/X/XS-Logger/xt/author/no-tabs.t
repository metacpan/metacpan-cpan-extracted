use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XS/Logger.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02-log-file-path.t',
    't/custom-path-file.t',
    't/fork.t',
    't/levels.t',
    't/lib/Test/XSLogger.pm',
    't/log-level.t',
    't/object.t'
);

notabs_ok($_) foreach @files;
done_testing;
