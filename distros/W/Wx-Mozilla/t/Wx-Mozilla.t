# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Wx-Mozilla.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Wx::Mozilla') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

