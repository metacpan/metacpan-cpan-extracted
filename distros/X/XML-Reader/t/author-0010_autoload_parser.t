
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

use Test::More tests => 2;

# This test verifies that XML::Reader uses XML::Parser
# if the user doesn't provide a backend module

use XML::Reader; # no specification of a backend

ok($INC{'XML/Parser.pm'},'XML::Parser is used as a backend');
ok(! exists $INC{'XML/Parsepp.pm'}, 'XML::Parsepp is not used');
