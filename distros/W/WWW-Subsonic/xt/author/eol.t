use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/subsonic_import_ratings.pl',
    'bin/subsonic_starred_m3u.pl',
    'bin/subsonic_sync_starred.pl',
    'lib/WWW/Subsonic.pm',
    't/00-compile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
