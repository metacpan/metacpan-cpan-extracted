use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/LibXML/Iterator.pm',
    'lib/XML/LibXML/NodeList/Iterator.pm',
    't/00-compile.t',
    't/01basic.t',
    't/02tree.t',
    't/03list.t'
);

notabs_ok($_) foreach @files;
done_testing;
