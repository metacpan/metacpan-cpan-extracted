
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Win32/Netsh.pm',
    'lib/Win32/Netsh/Interface.pm',
    'lib/Win32/Netsh/Utils.pm',
    'lib/Win32/Netsh/Wlan.pm',
    't/00-Win32-Netsh.t',
    't/00-compile.t',
    't/01-Win32-Netsh-Interface.t',
    't/02-Win32-Netsh-Wlan.t',
    't/author-critic.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-test-version.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t'
);

notabs_ok($_) foreach @files;
done_testing;
