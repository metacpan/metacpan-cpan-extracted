use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/Amazon.pm',
    'lib/XML/Amazon/Collection.pm',
    'lib/XML/Amazon/Item.pm',
    't/00-compile.t',
    't/XML-Amazon.t'
);

notabs_ok($_) foreach @files;
done_testing;
