use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/PerlTidy.pm',
    't/00-compile.t',
    't/_perlcriticrc.txt',
    't/_perltidyrc.txt',
    't/critic.t',
    't/exclude_files.t',
    't/exclude_perltidy.t',
    't/is_file_tidy.t',
    't/list_files.t',
    't/messy_file.txt',
    't/perltidy.t',
    't/tidy_file.txt'
);

notabs_ok($_) foreach @files;
done_testing;
