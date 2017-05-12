use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/NewVersion.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/03-pod.t',
    't/04-blib.t',
    't/corpus/basic/META.json',
    't/corpus/basic/lib/Bar/Baz.pm',
    't/corpus/basic/lib/ExtUtils/MakeMaker.pm',
    't/corpus/basic/lib/Foo.pm',
    't/corpus/basic/lib/Moose.pm',
    't/corpus/basic/lib/Moose/Cookbook.pod',
    't/corpus/basic/lib/Plack/Test.pm',
    't/corpus/blib/blib/lib/Bar.pm',
    't/corpus/blib/lib/Bar.pm',
    't/corpus/blib/lib/Foo.pm',
    't/corpus/pod/lib/Bar.pod',
    't/corpus/pod/lib/Foo.pm',
    't/lib/NoNetworkHits.pm',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/author/self.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t',
    'xt/release/synopsis.t'
);

notabs_ok($_) foreach @files;
done_testing;
