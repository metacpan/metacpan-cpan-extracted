# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Win32::AD::User') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
  my $ADsPath = "WinNT://".$ENV{'USERDOMAIN'}."/".$ENV{'COMPUTERNAME'}.",computer";
  my $user = Win32::AD::User->new($ADsPath,$ENV{'USERNAME'});
  ok(ref($user),'Win32::AD::User');
  ok(ref($user->get_info()),'Win32::OLE');
  ok(ref($user->{_user_ref}).'Win32::OLE');
  $user=undef; $ADsPath=undef;

