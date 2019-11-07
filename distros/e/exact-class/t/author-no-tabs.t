
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
    'lib/exact/class.pm',
    'lib/exact/role.pm',
    't/00-compile.t',
    't/00_use_class.t',
    't/01_use_role.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/basic.t',
    't/false_injection.t',
    't/prop_inherit.t',
    't/release-kwalitee.t',
    't/role.t',
    't/sub_attrs.t'
);

notabs_ok($_) foreach @files;
done_testing;
