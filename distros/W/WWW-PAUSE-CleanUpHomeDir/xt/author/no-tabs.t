use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WWW/PAUSE/CleanUpHomeDir.pm',
    't/00-compile.t',
    't/00-load.t'
);

notabs_ok($_) foreach @files;
done_testing;
