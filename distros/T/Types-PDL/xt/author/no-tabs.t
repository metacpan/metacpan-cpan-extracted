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
    't/deprecated/basic.t',
    't/deprecated/coercions.t',
    't/deprecated/empty.t',
    't/deprecated/ndims.t',
    't/deprecated/null.t',
    't/deprecated/shape.t',
    't/deprecated/subtypes.t',
    't/deprecated/type.t',
    't/empty.t',
    't/ndims.t',
    't/null.t',
    't/shape.t',
    't/shape_match.t',
    't/subtypes.t',
    't/type.t'
);

notabs_ok($_) foreach @files;
done_testing;
