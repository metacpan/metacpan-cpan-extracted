use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Text/Sprintf/Named.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-use.t',
    't/02-override-param-retrieval.t',
    't/03-incomplete.t',
    't/04-procedural-iface.t'
);

notabs_ok($_) foreach @files;
done_testing;
