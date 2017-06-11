
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBreakpoints 0.0.2

use Test::More 0.88;
use Test::NoBreakpoints 0.15;

all_files_no_breakpoints_ok();

done_testing;
