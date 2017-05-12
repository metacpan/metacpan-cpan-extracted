use strict;
use warnings;

use Test;

BEGIN {
    eval {require Win32};
    unless (defined &Win32::IsWinNT && Win32::IsWinNT()) {
        print"1..0 # skip Win32::NetAdmin only works on Windows NT and later\n";
	exit 0;
    }
    unless (defined &Win32::IsAdminUser && Win32::IsAdminUser()) {
	print"1..0 # skip Must be running as an administrator\n";
	exit 0;
    }
}

use Win32::NetAdmin qw(:DEFAULT UserCreate UserDelete UserGetAttributes
		       LocalGroupCreate LocalGroupGetAttributes LocalGroupAddUsers
		       LocalGroupIsMember LocalGroupDelete);

my $serverName   = '';
my $userName     = 'TestUser';
my $password     = 'password';
my $passwordAge  = 0;
my $privilege    = USER_PRIV_USER;
my $homeDir      = 'c:\\';
my $comment      = 'This is a test user';
my $flags        = UF_SCRIPT;
my $scriptpath   = 'C:\\';
my $groupName    = 'TestGroup';
my $groupComment = "This is a test group";

plan tests => 15;

ok(UserCreate($serverName, $userName, $password, $passwordAge, $privilege,
	      $homeDir, $comment, $flags, $scriptpath));

ok(UserGetAttributes($serverName, $userName,
		     my $Getpassword, my $GetpasswordAge, my $Getprivilege,
		     my $GethomeDir, my $Getcomment, my $Getflags, my $Getscriptpath));

ok($passwordAge <= $GetpasswordAge && $passwordAge+5 >= $GetpasswordAge);

if ($serverName eq '') {
    # on a server this will be zero
    ok($Getprivilege == 0);
}
else {
    ok($privilege == $Getprivilege);
}

ok($homeDir, $GethomeDir);
ok($comment, $Getcomment);
ok($flags == ($Getflags&USER_PRIV_MASK));
ok($scriptpath, $Getscriptpath);

ok(LocalGroupCreate($serverName, $groupName, $groupComment));

ok(LocalGroupGetAttributes($serverName, $groupName, my $GetgroupComment));
ok($groupComment, $GetgroupComment);

ok(LocalGroupAddUsers($serverName, $groupName, $userName));

ok(LocalGroupIsMember($serverName, $groupName, $userName));

ok(LocalGroupDelete($serverName, $groupName));

ok(UserDelete($serverName, $userName));
