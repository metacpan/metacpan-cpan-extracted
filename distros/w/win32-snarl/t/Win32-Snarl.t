# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Snarl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Win32::Snarl') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $version = Win32::Snarl::GetVersionEx();
ok ($version >= 65542, 'Get Version');

my $message_id = Win32::Snarl::ShowMessage('Win32::Snarl', 'Testing');
ok ($message_id, 'Show Message');

# have to wait for the message to show before we can hide it
sleep 1;

ok (Win32::Snarl::IsMessageVisible($message_id), 'Visible');
ok (defined Win32::Snarl::HideMessage($message_id), 'Hide Message');
ok (!Win32::Snarl::IsMessageVisible($message_id), 'Not Visible');
