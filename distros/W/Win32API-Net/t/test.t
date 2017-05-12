# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
    $| = 1;
    require Win32 unless defined &Win32::IsAdminUser;
    printf "1..%d\n", Win32::IsAdminUser() ? 18 : 4;
}
END {print "not ok 1\n" unless $loaded;}
use Win32API::Net qw/ :ALL /;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# test UserName() function. Not all Win32 perls are case insensitive when is
# comes to accessing the %ENV hash and the username could be returned
# in any old case. Hence the extra precautions...

require Win32 unless defined &Win32::LoginName;
$userName = Win32::LoginName();
print "not " unless $userName =~ /$ENV{'USERNAME'}/i;
print "ok 2\n";

# test GetDCName() function to return domain controller for primary domain
$dc = "";
print "# ignore test 3 failure if network has no Primary Domain Controller\n";
#print "# [$^E]\nnot " unless GetDCName("", "", $dc);
print "ok 3\n";
#warn "Failure of test 3 is expected on NT Workstations\n";

# test UserGetInfo()
print "# ignore test 4 failure if network has no Primary Domain Controller\n";
#print "# [$^E]\nnot " unless UserGetInfo($dc, $userName, 3, \%testUserInfo3);
print "ok 4\n";
undef %testUserInfo3;

exit unless Win32::IsAdminUser();

# test UserAdd() function
# define some variables for level 3 user
# Where a variable is modified later or is otherwise easier to declare
# it is declared first and then used later
$testUserName="qwerty$$";	# should be unique (but isn't that much!)
# passing certain values in flags can result in runtime errors.
# I would recommend that you use anything that works and don't
# compute a value at runtime!
$testUserFlags=( UF_ACCOUNTDISABLE() |
		 UF_NORMAL_ACCOUNT() |
		 UF_SCRIPT() );
@testLogonHours=( 255 ) x 21;
%testUserInfo3=(
	'name'          => $testUserName,
	'password'      => "password",							# don't worry - the account is disabled
	'passwordAge'   => 0,
	'priv'          => USER_PRIV_USER(),
	'homeDir'       => $ENV{'TEMP'},
	'comment'       => "What do you expect for sixpence", 
	'flags'         => $testUserFlags,
	'scriptPath'    => "",
	'authFlags',    => 0,
	'fullName',     => "Temp. user for AccNT module testing - delete me",
	'usrComment',   => "Usr Comment!",
	'parms',        => "",
	'workstations', => "",
	'lastLogon',    => 0,
	'lastLogoff',   => 0,
	'acctExpires',  => -1,							# never
	'maxStorage',   => -1,							# no quota
	'unitsPerWeek', => 0,
	'logonHours',   => \@testLogonHours,
	'badPwCount',   => 0,
	'numLogons',    => 0,
	'logonServer',  => "",
	'countryCode',  => 0,
	'codePage',     => 0,
	'userId'        => 0,
	'primaryGroupId'=> 513,							# magic number - see documentation
	'profile'       => "",
	'homeDirDrive'  => "",
	'passwordExpired'=>0
);

# this will fail if this account actually exists - this is a good thing.
$fie=0;
unless (UserAdd($dc, 3, \%testUserInfo3, $fie)) {
    print <<EOM;
not ok 5
Can't add a user so there really isn't any point in continuing...
EOM
    exit;
}
print "ok 5\n";

# test UserGetInfo using the newly created account.
print "not " unless UserGetInfo($dc, $testUserName, 3, \%userInfo3);
print "ok 6\n";
undef %userInfo3;

# Set info at level 0 - this is effectively an account rename option.
$currentUserName=$testUserName;
$testUserName.="renamed";
%testUserInfo0=(
	'name'=>$testUserName
);

print "not " unless UserSetInfo($dc, $currentUserName, 0,
				\%testUserInfo0, $fie);
print "ok 7\n";

print "not " unless UserGetInfo($dc, $testUserName, 3, \%testLogonHours);
print "ok 8\n";
undef %testLogonHours;

# this can/will generate a huge array
print "not " unless UserEnum($dc, \@users);
print "ok 9\n";

print "not " unless UserEnum($dc, \@users, FILTER_NORMAL_ACCOUNT());
print "ok 10\n";

print "not " unless LocalGroupEnum("", \@localGroups);
print "ok 11\n";

# Try to pick out out the Administrators and Guests group names for
# further tests.  This mechanism is not very reliable because some
# Windows versions have additional groups defined between
# Administrators and Guests.
$Administrators = $localGroups[0];
$Guests = $localGroups[2];
undef @localGroups;

# If we have Win32::OLE and WMI available, then use that to determine
# the group names from their "well-known SIDs".  This code is written
# so that it should work with the version of WMI available on Windows
# 2000 and later.
sub GroupName {
    my($wmi,$name,$sid)= @_;
    # Domain = '$name' makes sure we only retrieve local accounts
    my $account = $wmi->ExecQuery(<<QUERY);
        SELECT * FROM Win32_Group
            WHERE Domain = '$name' AND SID = '$sid'
QUERY
    return Win32::OLE::Enum->new($account)->Next->Name;
}

if (eval {require Win32::OLE}) {
    my $name = Win32::NodeName;
    my $wmi = Win32::OLE->GetObject("winmgmts:\\\\$name\\root\\cimv2");
    if ($wmi) {
	$Administrators = GroupName($wmi, $name, "S-1-5-32-544");
	$Guests         = GroupName($wmi, $name, "S-1-5-32-546");
    }
}

print "not " unless LocalGroupGetInfo($dc, $Administrators, 1,
				      \%localGroupInfo);
print "ok 12\n";
undef %localGroupInfo;

# LocalGroupAdd()
$localGroupName="##Freds";
%localGroup=('name' => $localGroupName, 'comment' => 'All the freds');

print "not " unless LocalGroupAdd("", 1, \%localGroup, $fie);
print "ok 13\n";

@localGroupMembers=($testUserName, $Guests);
print "not " unless LocalGroupAddMembers("", $localGroupName,
					 \@localGroupMembers);
print "ok 14\n";

print "not " unless LocalGroupGetInfo("", $localGroupName, 1, \%lgInfo);
print "ok 15\n";

print "not " unless LocalGroupGetMembers("", $localGroupName, \@lgMembers);
print "ok 16\n";
undef %lgMembers;

@localGroupDelMembers=($Guests);
print "not " unless LocalGroupDelMembers("", $localGroupName,
					 \@localGroupDelMembers);
print "ok 17\n";

%lgInfo=('name' => $localGroupName, 'comment' => 'What-else');
print "not " unless LocalGroupSetInfo("", $localGroupName, 1, \%lgInfo, $fie);
print "ok 18\n";

print "not " unless LocalGroupDel("", $localGroupName);
print "not " unless UserDel($dc, $testUserName);
