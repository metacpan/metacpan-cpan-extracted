#!perl -T

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod::Coverage 1.04';

if ($@) {
    plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage';
}
else {
    plan tests => 1;
}
pod_coverage_ok('Test::Mock::Cmd');    # test mods have no POD so no all_pod_coverage_ok();
