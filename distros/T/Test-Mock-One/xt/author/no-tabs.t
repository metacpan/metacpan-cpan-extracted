use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Mock/One.pm',
    'lib/Test/Mock/Two.pm',
    't/00-compile.t',
    't/001-mock.t',
    't/002-mock.t',
    't/lib/Test/Mock/Testsuite.pm'
);

notabs_ok($_) foreach @files;
done_testing;
