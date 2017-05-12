
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WebService/Avalara/AvaTax.pm',
    'lib/WebService/Avalara/AvaTax/Role/Connection.pm',
    'lib/WebService/Avalara/AvaTax/Role/Dumper.pm',
    'lib/WebService/Avalara/AvaTax/Role/Service.pm',
    'lib/WebService/Avalara/AvaTax/Service/Address.pm',
    'lib/WebService/Avalara/AvaTax/Service/Tax.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/dumper.t',
    't/fix_get_tax.t',
    't/get_tax.t',
    't/is_authorized.t',
    't/ping.t',
    't/release-changes_has_content.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-pod-linkcheck.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
