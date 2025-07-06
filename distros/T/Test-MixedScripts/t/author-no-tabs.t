
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
    'lib/Test/MixedScripts.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all_perl_files_scripts_ok.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/data/ascii-01.txt',
    't/data/bad-01.txt',
    't/data/bad-02.js',
    't/data/bad-03.txt',
    't/data/good-03.pod',
    't/etc/perlcritic.rc',
    't/file_scripts_ok-Test-More.t',
    't/file_scripts_ok.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t',
    't/self.t'
);

notabs_ok($_) foreach @files;
done_testing;
