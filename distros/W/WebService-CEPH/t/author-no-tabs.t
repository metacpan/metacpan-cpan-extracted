
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
    'lib/WebService/CEPH.pm',
    'lib/WebService/CEPH/FileShadow.pm',
    'lib/WebService/CEPH/NetAmazonS3.pm',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/ceph.t',
    't/file_shadown.t',
    't/netamazons3_integration.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-kwalitee.t'
);

notabs_ok($_) foreach @files;
done_testing;
