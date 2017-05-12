
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

# this test was generated with Dist::Zilla::Plugin::Test::Kwalitee 2.07
use strict;
use warnings;
use Test::Kwalitee;
