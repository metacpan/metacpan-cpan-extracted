# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

print "Make test will NOT work on versions of Perl older than 5.006. This is nothing to worry about.\nConsider upgrading your Perl to version 5.6.1!\n";

use Test;
BEGIN { plan tests => 1 };
use Apache::WeSQL;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

