use Test::More skip_all => " *** NOT IMPLEMENTED";
#test for Perl NetAdmin Module Extension.
#Written by Douglas_Lankshear@ActiveWare.com

BEGIN {
    require Win32 unless defined &Win32::IsWin95;
    if (Win32::IsWin95) {
	print"1..0 # skip This module does not work on Win95\n";
	exit 0;
    }
};

use Win32::NetAdmin;

Win32::NetAdmin::GetDomainController('', '', $serverName);

$serverName = '';
$userName = 'TestUser';
$password = 'password';
$passwordAge = 0;
$privilege = USER_PRIV_USER;
$homeDir = 'c:\\';
$comment = 'This is a test user';
$flags = UF_SCRIPT;
$scriptpath = 'C:\\';
$groupName = 'TestGroup';
$groupComment = "This is a test group";

print "1..15\n";

# TODO: Check to make sure current account has rights to Create user accounts etc.

Win32::NetAdmin::UserCreate($serverName, $userName, $password, $passwordAge, $privilege, $homeDir, $comment, $flags, $scriptpath) || print "not ";
print "ok 1\n";

Win32::NetAdmin::UserGetAttributes($serverName, $userName, my $getpassword, $GetpasswordAge, $Getprivilege, $GethomeDir, $Getcomment, $Getflags, $Getscriptpath) || print "not ";
print "ok 2\n";

($passwordAge <= $GetpasswordAge && $passwordAge+5 >= $GetpasswordAge) || print "not ";
print "ok 3\n";

if($serverName eq '')
{
	# on a server this will be zero
	($Getprivilege == 0) || print "not ";
}
else
{
	($privilege == $Getprivilege) || print "not ";
}
print "ok 4\n";

($homeDir eq $GethomeDir) || print "not ";
print "ok 5\n";

($comment eq $Getcomment) || print "not ";
print "ok 6\n";

($flags == ($Getflags&USER_PRIV_MASK)) || print "not ";
print "ok 7\n";

($scriptpath eq $Getscriptpath) || print "not ";
print "ok 8\n";

Win32::NetAdmin::LocalGroupCreate($serverName, $groupName, $groupComment) || print "not ";
print "ok 9\n";

Win32::NetAdmin::LocalGroupGetAttributes($serverName, $groupName, $GetgroupComment) || print "not ";
print "ok 10\n";

($groupComment eq $GetgroupComment) || print "not ";
print "ok 11\n";

Win32::NetAdmin::LocalGroupAddUsers($serverName, $groupName, $userName) || print "not ";
print "ok 12\n";

Win32::NetAdmin::LocalGroupIsMember($serverName, $groupName, $userName) || print "not ";
print "ok 13\n";

Win32::NetAdmin::LocalGroupDelete($serverName, $groupName) || print "not ";
print "ok 14\n";

Win32::NetAdmin::UserDelete($serverName, $userName) || print "not ";
print "ok 15\n";

