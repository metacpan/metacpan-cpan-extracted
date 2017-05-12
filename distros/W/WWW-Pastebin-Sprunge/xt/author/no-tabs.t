use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WWW/Pastebin/Sprunge.pod',
    'lib/WWW/Pastebin/Sprunge/Create.pm',
    'lib/WWW/Pastebin/Sprunge/Retrieve.pm',
    't/00-compile.t',
    't/00-init.t',
    't/01-retrieve.t',
    't/02-create.t',
    't/03-unicode.t',
    't/04-file.t',
    't/testfile'
);

notabs_ok($_) foreach @files;
done_testing;
