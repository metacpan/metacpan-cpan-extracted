# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl promessaging-MRS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('promessaging::MRS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.



BEGIN {  $| = 1; print "begin tests 1 to ... 1\n";}
END {print "not OK 1\n" unless $loaded;}
use promessaging::MRS;
$loaded = 1;
print "OK 1\n";

#MRSinfo();	print "OK ... 1";

print "\n end tests \n";