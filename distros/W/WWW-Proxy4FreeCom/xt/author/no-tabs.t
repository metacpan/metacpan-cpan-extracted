use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WWW/Proxy4FreeCom.pm',
    't/00-compile.t',
    't/01-proxy.t'
);

notabs_ok($_) foreach @files;
done_testing;
