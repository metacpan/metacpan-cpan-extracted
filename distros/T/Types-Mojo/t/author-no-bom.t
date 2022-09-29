
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'lib/Types/Mojo.pm',
    't/TestClass.pm',
    't/collection.t',
    't/file.t',
    't/file_list.t',
    't/url.t',
    't/user_agent.t'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
