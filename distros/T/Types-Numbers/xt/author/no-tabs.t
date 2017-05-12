use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Types/Numbers.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-int.t',
    't/03-float.t',
    't/04-fixed.t',
    't/10-char.t',
    't/lib/NumbersTest.pm'
);

notabs_ok($_) foreach @files;
done_testing;
