use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/EOL.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-use-self.t',
    't/11-all.t',
    't/12-fail.t',
    't/13-latin1.t',
    't/20-all_files.t',
    'xt/author/00-compile.t',
    'xt/author/changes_has_content.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
