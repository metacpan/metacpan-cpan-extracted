
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/SVN/Repo.pm',
    't/00-compile.t',
    't/01-noserver.t',
    't/02-server.t',
    't/03-multiple.t',
    't/04-non-win32.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-meta-json.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t'
);

notabs_ok($_) foreach @files;
done_testing;
