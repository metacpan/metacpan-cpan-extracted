# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-ShutDown.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Win32::ShutDown') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


print "This module can only be tested manually\n";
print "To test this, run with the switch /restart - eg:-\n";
print "$0 /restart\n";

print "Restart return code = " . Win32::ShutDown::Restart() if ($ARGV[0] =~/restart/i);
