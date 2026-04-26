use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Text/Minify/XS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-minify.t',
    't/02-minify_utf8.t',
    't/03-minify_ascii.t',
    't/04-undef.t',
    't/10-overflow.t',
    't/author-leaks.t',
    't/author-ppport.t',
    't/author-xs-check.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
