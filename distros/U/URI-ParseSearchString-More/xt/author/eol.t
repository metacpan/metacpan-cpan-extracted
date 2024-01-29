use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/URI/ParseSearchString/More.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001_load.t',
    't/005_parse_more.t',
    't/006_extended.t',
    't/007_focus.t',
    't/extended_urls.cfg'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
