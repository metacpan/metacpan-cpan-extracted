use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Version.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all-generated.t',
    't/all-has-version-false.t',
    't/all.t',
    't/at-least-one-version.t',
    't/bare.t',
    't/consistent.t',
    't/fail.t',
    't/file-not-defined.t',
    't/inconsistent.t',
    't/missing-has-version.t',
    't/missing.t',
    't/mswin32.t',
    't/multiple-inconsistent.t',
    't/multiple.t',
    't/no-file.t',
    't/noversion.t',
    't/pass.t',
    't/strict.t',
    't/taint-workaround.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
