use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WebService/Netlify.pm',
    'lib/WebService/Netlify/Roles/OpenAPI.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/data/filemap'
);

notabs_ok($_) foreach @files;
done_testing;
