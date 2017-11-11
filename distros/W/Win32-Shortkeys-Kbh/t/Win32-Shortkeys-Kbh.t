# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Win32-Shortkeys-Kbh.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Win32::Shortkeys::Kbh') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
is($^O, "MSWin32", "This module is limited to Windows");
can_ok("Win32::Shortkeys::Kbh", qw(send_string send_cmd register_hook set_key_processor));
