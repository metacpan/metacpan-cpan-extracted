
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CPAN::Changes 0.012

use Test::More 0.96 tests => 1;
use Test::CPAN::Changes;
subtest 'changes_ok' => sub {
    changes_file_ok('Changes');
};
