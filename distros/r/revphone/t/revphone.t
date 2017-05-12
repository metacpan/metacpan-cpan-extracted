# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl revphone.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 1;
#BEGIN { ok('use revphone') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use revphone;
my $revlookup = revphone;
ok ($revlookup->revlookup('6016841121') eq "Community Calendar On Time-Temp-Plus, 100 S Broadway MCCOMB,MS 39648\n" ) 
