use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/query_kvk.pl',
    'lib/WebService/KvKAPI.pm',
    'lib/WebService/KvKAPI/Spoof.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-spoof.t',
    't/9999-live-test.t'
);

notabs_ok($_) foreach @files;
done_testing;
