
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Roo/DataDriven.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-example.t',
    't/02-json.t',
    't/03-parsing-errors.t',
    't/04-skip_all.t',
    't/05-argv-disabled.t',
    't/05-argv-enabled.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/data/001-sample-data.dat',
    't/data/002-another.dat',
    't/data/003-array.dat',
    't/data/errors/function.err',
    't/data/errors/syntax.err',
    't/data/json/001-sample.json',
    't/data/json/002-another.json',
    't/data/json/003-array.json',
    't/etc/perlcritic.rc',
    't/lib/Example.pm',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
