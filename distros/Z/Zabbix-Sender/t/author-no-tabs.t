
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/zabbix-sender',
    'lib/Zabbix/Sender.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/boilerplate.t',
    't/bulk_buf.t',
    't/encode_request.t',
    't/perlcriticrc',
    't/release-critic.t',
    't/release-kwalittee.t',
    't/release-manifest.t',
    't/release-pod-coverage.t'
);

notabs_ok($_) foreach @files;
done_testing;
