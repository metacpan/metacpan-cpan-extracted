#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}


use strict;
use warnings;

use Test::More 0.96 tests => 2;
use_ok('Test::CPAN::Changes');
subtest 'changes_ok' => sub {
    changes_file_ok('Changes');
};
done_testing();
