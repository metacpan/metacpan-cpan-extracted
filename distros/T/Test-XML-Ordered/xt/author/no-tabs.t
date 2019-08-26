use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/XML/Ordered.pm',
    't/00-compile.t',
    't/attribute_compare_1.t',
    't/xml_compare1.t'
);

notabs_ok($_) foreach @files;
done_testing;
