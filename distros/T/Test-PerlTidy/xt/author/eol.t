use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
