
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
    'lib/Types/SQL.pm',
    'lib/Types/SQL/Util.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001-use.t',
    't/100-blob.t',
    't/100-bool.t',
    't/100-char.t',
    't/100-datetime.t',
    't/100-enum.t',
    't/100-int.t',
    't/100-integer.t',
    't/100-num.t',
    't/100-numeric.t',
    't/100-serial.t',
    't/100-str.t',
    't/100-text.t',
    't/100-varchar.t',
    't/101-types-datetime.t',
    't/199-unsupported.t',
    't/200-custom.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
