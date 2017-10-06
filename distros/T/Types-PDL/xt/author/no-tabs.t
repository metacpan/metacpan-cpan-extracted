use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Types/PDL.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/coercions.t',
    't/empty.t',
    't/ndims.t',
    't/null.t',
    't/subtypes.t'
);

notabs_ok($_) foreach @files;
done_testing;
