
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.1.0.

use Test::More 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'XS.c',
    'XS.xs',
    'lib/Text/Minify/XS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-minify.t',
    't/02-minify_utf8.t',
    't/03-minify_ascii.t',
    't/04-undef.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-leaks.t',
    't/author-minimum-version.t',
    't/author-mixed-unicode-scripts.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-ppport.t',
    't/author-xs-check.t',
    't/etc/perlcritic.rc',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
