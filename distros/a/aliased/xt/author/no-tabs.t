use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/aliased.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/aliased.t',
    't/export.t',
    't/import.t',
    't/lib/BadSigDie.pm',
    't/lib/HasSigDie.pm',
    't/lib/NoSigDie.pm',
    't/lib/Really/Long/Module/Conflicting/Name.pm',
    't/lib/Really/Long/Module/Name.pm',
    't/lib/Really/Long/Name.pm',
    't/lib/Really/Long/PackageName.pm',
    't/prefix.t',
    't/sigdie.t',
    'xt/author/00-compile.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
