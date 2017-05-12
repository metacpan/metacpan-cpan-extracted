# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Test-Mock-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use lib 't/';

use Test::More tests => 7;

BEGIN {
  use_ok('Test::Mock::Simple');
  use_ok('Mock::TestModule');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $test = TestModule->new();

is($test->one, 'eins', 'Got Mocked One');
is($test->two, 2, 'Got Real Two');
is($test->three, 3, 'Got Real Three');
is($test->rooster, 'kikeriki', 'Got Mocked Rooster');

is($test->add, 'No namespace conflicts', 'Able to add an "add" method');
