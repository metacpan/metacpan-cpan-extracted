# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Thread-IID.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Thread::IID') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(Thread::IID::interpreter_id() =~ m(\A[0-9]+\z),      'looks like an integer');
is(Thread::IID::interpreter_id(),Thread::IID::interpreter_id(),  'always the same');

