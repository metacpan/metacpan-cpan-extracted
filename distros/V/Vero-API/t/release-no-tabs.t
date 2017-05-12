
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Vero/API.pm',
    'script/verocli',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/basic.t',
    't/release-distmeta.t',
    't/release-eol.t',
    't/release-no-tabs.t'
);

notabs_ok($_) foreach @files;
done_testing;
