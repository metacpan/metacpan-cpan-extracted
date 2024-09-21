use strict;
$^W++;
# Modules under test
use Win32::Security::NamedObject;
use Win32::Security::Recursor;

# Modules to support specific tests
use Win32; # Supports IsAdminUser

# Modules to support test harness
use Data::Dumper;
use Test;

use vars qw($enabled);
BEGIN {
	$|++;
	$enabled = 1; #Change this to 0 to disable the tests
	plan tests => $enabled ? 381 : 1,
}
if (!$enabled) {
	ok(1);
	exit;
}


$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1; #Repeated to avoid warnings


($ENV{USERDOMAIN} ne '' && $ENV{USERNAME} ne '') or die "$0 requires the environment variables USERDOMAIN and USERNAME.  Testing has halted.\n";

my $username = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid("$ENV{USERDOMAIN}\\$ENV{USERNAME}")); # Cleanup capitalization

my $admin = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid('S-1-5-32-544')); # 'BUILTIN\\Administrators' localization

my $guestsid = Win32::Security::SID::ConvertSidToStringSid(Win32::Security::SID::ConvertNameToSid("$ENV{USERDOMAIN}\\$ENV{USERNAME}"));
$guestsid =~ s/-\d+$/-501/;
my $guest = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid($guestsid)); # "$ENV{USERDOMAIN}\\Guest" localization

my $system = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid('S-1-5-18')); # 'NT AUTHORITY\\SYSTEM' localization



`cacls.exe` =~ /Displays or modifies access control lists/si or die "$0 requires cacls.exe to function.  Unable to find cacls.exe so testing has halted.\n";

# Because newer versions of calcs.exe support '(ID)' for an inherited property and older versions don't,
# we use $ID (${ID} specifically) in the cacls.exe strings to supply '(ID)' for versions that support
# ID and to supply an empty string when it is not spported.
my $ID = ( `cacls.exe` =~ /ID - Inherited/ ? '(ID)' : '' );


my $script_dir;
foreach my $inc (@INC) {
	$inc =~ s/\//\\/g;

	my $testinc = $inc.'\\Win32\\Security';
	if (-e "$testinc\\PermChg.pl" && -e "$testinc\\PermDump.pl" && -e "$testinc\\PermFix.pl") {
		$script_dir = $testinc;
		last;
	}

	($testinc = $inc) =~ s/\\lib$/\\script/;
	if (-e "$testinc\\PermChg.pl" && -e "$testinc\\PermDump.pl" && -e "$testinc\\PermFix.pl") {
		$script_dir = $testinc;
		last;
	}
}
defined $script_dir or die "$0 requires access to the Perm(Chg|Dump|Fix).pl scripts.  Unable to find them in \@INC so testing has halted.\n";

# Prepare tempdir for testing
my $tempdir = "$ENV{TEMP}\\Win32-Security_TestDir_$$";
-d $tempdir and die "$0 requires a temp directory for testing.  The directory '$tempdir' already exists so testing has halted.\n";
mkdir($tempdir, 0);
-d $tempdir or die "$0 requires a temp directory for testing.  Unable to create the directory '$tempdir' so testing has halted.\n";

# BEGIN eval block from the top of the section that interacts with the file system
eval {

#First we set the permissions on $tempdir
my $tempdir_no = Win32::Security::NamedObject->new('SE_FILE_OBJECT', $tempdir);
$tempdir_no->dacl( $tempdir_no->dacl()->new(map {['ALLOW', 'FULL_INHERIT', 'FULL', $_]} ($admin, $system, $username)), 'PROTECTED_DACL_SECURITY_INFORMATION' );

#Now we check the owner
my $owner = $tempdir_no->ownerTrustee();
ok( $owner eq $username || $owner eq $admin );

#Initial cacls and permdump tests on $tempdir
ok(	&cacls($tempdir),
		join("\n", map { "$_:(OI)(CI)F" } ($admin, $system, $username)) );
ok(	&permdump($tempdir),
		join("\n", ",INHERITANCE_BLOCKED,,DB", map { "$_,FULL,FULL_INHERIT,DX" } ($admin, "\"$system\"", $username)) );

#Create foo.txt and check cacls and permdump
ok(	&touch("$tempdir\\foo.txt") );
ok(	&cacls("$tempdir\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\foo.txt"),
		join("\n", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );


#Create GuestWrite and check cacls and permdump
ok( mkdir("$tempdir\\GuestWrite", 0) );
ok(	&cacls("$tempdir\\GuestWrite"),
		join("\n", map { "$_:(OI)(CI)${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite"),
		join("\n", map { "$_,FULL,FULL_INHERIT,DI" } ($admin, "\"$system\"", $username)) );

#Give the Guest account perms on foo.txt and check cacls and permdump
my $gw_no = Win32::Security::NamedObject->new('SE_FILE_OBJECT', "$tempdir\\GuestWrite");
$gw_no->dacl( $gw_no->dacl()->addAces(map {['ALLOW', 'FULL_INHERIT', 'FULL', $_]} ($guest)) );
ok(	&cacls("$tempdir\\GuestWrite"),
		join("\n", "$guest:(OI)(CI)F", ( map { "$_:(OI)(CI)${ID}F" } ($admin, $system, $username) ) ) );
ok(	&permdump("$tempdir\\GuestWrite"),
		join("\n", "$guest,FULL,FULL_INHERIT,DX", map { "$_,FULL,FULL_INHERIT,DI" } ($admin, "\"$system\"", $username)) );

#Create foo2.txt in GuestWrite and check cacls and permdump
ok(	&touch("$tempdir\\GuestWrite\\foo2.txt") );
ok(	&cacls("$tempdir\\GuestWrite\\foo2.txt"),
		join("\n", map { "$_:${ID}F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo2.txt"),
		join("\n", map { "$_,FULL,,FI" } ($guest, $admin, "\"$system\"", $username)) );

#Swap foo.txt and foo2.txt between dirs . . .
ok(	&move("$tempdir\\GuestWrite\\foo2.txt", "$tempdir\\foo2.txt") );
ok(	&move("$tempdir\\foo.txt", "$tempdir\\GuestWrite\\foo.txt") );

#Check that cacls reports nothing strange . ..
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&cacls("$tempdir\\foo2.txt"),
		join("\n", map { "$_:${ID}F" } ($guest, $admin, $system, $username)) );

#But permdump sure does!
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest,FULL,,FM", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );
ok(	&permdump("$tempdir\\foo2.txt"),
		join("\n", "$guest,FULL,,FW", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );
ok(	&permdump("$tempdir", '-c -r'),
		join("\n", (map {"$tempdir,$_"} ",INHERITANCE_BLOCKED,,DB", map { "$_,FULL,FULL_INHERIT,DX" } ($admin, "\"$system\"", $username)),
							 "$tempdir\\foo2.txt,$guest,FULL,,FW",
							 "$tempdir\\GuestWrite,$guest,FULL,FULL_INHERIT,DX",
							 "$tempdir\\GuestWrite\\foo.txt,$guest,FULL,,FM",
				)
	);

#But we can fix this . . .
ok(	&permfix("$tempdir", '-r -c -q'), "$tempdir\\foo2.txt\n$tempdir\\GuestWrite\\foo.txt\n" );

#And now everything comes out peachy!
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_,FULL,,FI" } ($guest, $admin, "\"$system\"", $username)) );
ok(	&permdump("$tempdir\\foo2.txt"),
		join("\n", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );
ok(	&permdump("$tempdir", '-c -r'),
		join("\n", (map {"$tempdir,$_"} ",INHERITANCE_BLOCKED,,DB", map { "$_,FULL,FULL_INHERIT,DX" } ($admin, "\"$system\"", $username)),
							 "$tempdir\\GuestWrite,$guest,FULL,FULL_INHERIT,DX",
				)
	);

#Now, testing permchg for the first time
ok(	&permchg("$tempdir\\GuestWrite\\foo.txt", "-q -a=$guest:M"), "" );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest:C", map { "$_:${ID}F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest,MODIFY,,FX", map { "$_,FULL,,FI" } ($guest, $admin, "\"$system\"", $username)) );

#Now, testing multiple allows in the same statement
ok(	&permchg("$tempdir\\GuestWrite\\foo.txt", "-q -a=$guest:M -a=$guest:F"), "" );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest:C", "$guest:F", map { "$_:${ID}F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest,MODIFY,,FX", "$guest,FULL,,FX", map { "$_,FULL,,FI" } ($guest, $admin, "\"$system\"", $username)) );

#Now, remove Guest allow from the parent folder
ok(	&permchg("$tempdir\\GuestWrite", "-q -a=$guest:"), "" );
ok(	&cacls("$tempdir\\GuestWrite"),
		join("\n", map { "$_:(OI)(CI)${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite"),
		join("\n", map { "$_,FULL,FULL_INHERIT,DI" } ($admin, "\"$system\"", $username)) );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest:C", "$guest:F", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest,MODIFY,,FX", "$guest,FULL,,FX", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now, fix the two explicits on the file
ok(	&permchg("$tempdir\\GuestWrite\\foo.txt", "-q -a=$guest:R"), "" );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest:R", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest,READ,,FX", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now, remove Guest totally
ok(	&permchg("$tempdir\\GuestWrite\\foo.txt", "-q -a=$guest:"), "" );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now, testing multiple allows for different users in the same statement
ok(	&permchg("$tempdir\\GuestWrite\\foo.txt", "-q -a=$guest:M -a=$username:F"), "" );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest:C", "$username:F", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest,MODIFY,,FX", "$username,FULL,,FX", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now, testing swapping perms on those allows (and order)
ok(	&permchg("$tempdir\\GuestWrite\\foo.txt", "-q -a=$username:M -a=$guest:F"), "" );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$username:C", "$guest:F", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$username,MODIFY,,FX", "$guest,FULL,,FX", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now, stripping the easy way
ok(	&permchg("$tempdir\\GuestWrite\\foo.txt", "-q -r"), "" );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now testing -b on it's own . . .
ok(	&permchg("$tempdir\\GuestWrite", "-q -b"), "" );
ok(	&cacls("$tempdir\\GuestWrite"),
		join("\n", map { "$_:(OI)(CI)F" } ($admin, $system, $username)) );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite"),
		join("\n", ",INHERITANCE_BLOCKED,,DB", map { "$_,FULL,FULL_INHERIT,DX" } ($admin, "\"$system\"", $username)) );

#Now, reverting to inheritable
ok(	&permchg("$tempdir\\GuestWrite", "-q -nob -r"), "" );
ok(	&cacls("$tempdir\\GuestWrite"),
		join("\n", map { "$_:(OI)(CI)${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite"),
		join("\n", map { "$_,FULL,FULL_INHERIT,DI" } ($admin, "\"$system\"", $username)) );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now, grant Guest allow on the top-level test folder
ok(	&permchg("$tempdir", "-q -a=$guest:F"), "" );
ok(	&cacls("$tempdir"),
		join("\n", map { "$_:(OI)(CI)F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir"),
		join("\n", ",INHERITANCE_BLOCKED,,DB", map { "$_,FULL,FULL_INHERIT,DX" } ($guest, $admin, "\"$system\"", $username)) );
ok(	&cacls("$tempdir\\GuestWrite"),
		join("\n", map { "$_:(OI)(CI)${ID}F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite"),
		join("\n", map { "$_,FULL,FULL_INHERIT,DI" } ($guest, $admin, "\"$system\"", $username)) );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", map { "$_,FULL,,FI" } ($guest, $admin, "\"$system\"", $username)) );

#Now, deny permissions using permchg
ok(	&permchg("$tempdir\\GuestWrite", "-q -d=$guest:F"), "" );
ok(	&cacls("$tempdir\\GuestWrite"),
		join("\n", "$guest:(OI)(CI)N", map { "$_:(OI)(CI)${ID}F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite"),
		join("\n", "$guest,DENY:FULL,FULL_INHERIT,DX", map { "$_,FULL,FULL_INHERIT,DI" } ($guest, $admin, "\"$system\"", $username)) );
ok(	&cacls("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest:${ID}N", map { "$_:${ID}F" } ($guest, $admin, $system, $username)) );
ok(	&permdump("$tempdir\\GuestWrite\\foo.txt"),
		join("\n", "$guest,DENY:FULL,,FI", map { "$_,FULL,,FI" } ($guest, $admin, "\"$system\"", $username)) );

system("rd /s /q \"$tempdir\\GuestWrite\"");

#Now validate -o for reading - first set up test dir/file
ok(	&permchg("$tempdir", "-q -a=$guest:"), "" );
ok(	&touch("$tempdir\\foo.txt") );
ok(	&cacls("$tempdir\\foo.txt"),
		join("\n", map { "$_:${ID}F" } ($admin, $system, $username)) );
ok(	&permdump("$tempdir\\foo.txt"),
		join("\n", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

#Now run IsAdminUser specific tests...
if ( Win32::IsAdminUser() ) {
	# Verify current owner
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$admin,OWNER,,FO", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

	# Change owner to Guest and verify
	ok(	&permchg("$tempdir\\foo.txt", "-q -o=$guest"), "" );
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$guest,OWNER,,FO", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

	# DENY Full Control to Admin
	ok(	&permchg("$tempdir\\foo.txt", "-q -d=$admin:F"), "" );
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$guest,OWNER,,FO", "$admin,DENY:FULL,,FX", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

	# Change owner to individual Admin account and verify
	ok(	&permchg("$tempdir\\foo.txt", "-q -o=$username"), "" );
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$username,OWNER,,FO", "$admin,DENY:FULL,,FX", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

	# Change owner back to BUILTIN\Administrators account and verify
	ok(	&permchg("$tempdir\\foo.txt", "-q -o=$admin"), "" );
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$admin,OWNER,,FO", "$admin,DENY:FULL,,FX", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );
}
else {
	# Verify current owner
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$username,OWNER,,FO", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

	# Change owner to Guest and verify failure
	ok(	&permchg("$tempdir\\foo.txt", "-q -o=$guest"),
		qr/SetNamedSecurityInfo: This security ID may not be assigned as the owner of this object/ );
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$username,OWNER,,FO", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

	# Change owner to self (already self) and verify
	ok(	&permchg("$tempdir\\foo.txt", "-q -o=$username"), "" );
	ok(	&permdump("$tempdir\\foo.txt", '-c -i -o'),
			join("\n", "$username,OWNER,,FO", map { "$_,FULL,,FI" } ($admin, "\"$system\"", $username)) );

	# Blank tests to match up with IsAdminUser tests
	ok(1, 1);
	ok(1, 1);

	ok(1, 1);
	ok(1, 1);
}




&matrix_test("$guest:F(FO)", {
				'.' => "$guest:F"
			}, ".,$guest,FULL,THIS_FOLDER_ONLY,DX");
&matrix_test("$guest:F(CI)", {
				'.' => "$guest:(CI)F",
				'bar' => "$guest:(CI)${ID}F", 'bar\\bas' => 'bar'
			}, ".,$guest,FULL,CONTAINER_INHERIT_ACE,DX");
&matrix_test("$guest:F(OI)", {
				'.' => "$guest:(OI)F",
				'bar' => "$guest:(OI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,FULL,OBJECT_INHERIT_ACE,DX");
&matrix_test("$guest:F", {
				'.' => "$guest:(OI)(CI)F",
				'bar' => "$guest:(OI)(CI)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,FULL,FULL_INHERIT,DX");
&matrix_test("$guest:F(CI|IO)", {
				'.' => "$guest:(CI)(IO)F",
				'bar' => "$guest:(CI)${ID}F", 'bar\\bas' => 'bar'
			}, ".,$guest,FULL,SUBFOLDERS_ONLY,DX");
&matrix_test("$guest:F(OI|IO)", {
				'.' => "$guest:(OI)(IO)F",
				'bar' => "$guest:(OI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,FULL,FILES_ONLY,DX");
&matrix_test("$guest:F(FI|IO)", {
				'.' => "$guest:(OI)(CI)(IO)F",
				'bar' => "$guest:(OI)(CI)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,FULL,SUBFOLDERS_AND_FILES_ONLY,DX");
&matrix_test("$guest:F(CI|NP)", {
				'.' => "$guest:(CI)(NP)F",
				'bar' => "$guest:${ID}F"
			}, ".,$guest,FULL,CONTAINER_INHERIT_ACE|NO_PROPAGATE_INHERIT_ACE,DX");
&matrix_test("$guest:F(OI|NP)", {
				'.' => "$guest:(OI)(NP)F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,FULL,NO_PROPAGATE_INHERIT_ACE|OBJECT_INHERIT_ACE,DX");
&matrix_test("$guest:F(FI|NP)", {
				'.' => "$guest:(OI)(CI)(NP)F",
				'bar' => "$guest:${ID}F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,FULL,FULL_INHERIT|NO_PROPAGATE_INHERIT_ACE,DX");
&matrix_test("$guest:F(CI|IO|NP)", {
				'.' => "$guest:(CI)(NP)(IO)F",
				'bar' => "$guest:${ID}F"
			}, ".,$guest,FULL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_ONLY,DX");
&matrix_test("$guest:F(OI|IO|NP)", {
				'.' => "$guest:(OI)(NP)(IO)F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,FULL,FILES_ONLY|NO_PROPAGATE_INHERIT_ACE,DX");
&matrix_test("$guest:F(FI|IO|NP)", {
				'.' => "$guest:(OI)(CI)(NP)(IO)F",
				'bar' => "$guest:${ID}F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,FULL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_AND_FILES_ONLY,DX");


my $UIO = ($owner eq $admin) ? '' : '(IO)';
my $AIO = ($owner eq $admin) ? '(IO)' : '';
my $matrix_mod = [$owner eq $admin ? "$admin:${ID}F\n$system:${ID}F\n$username:${ID}C" : "$username:${ID}F\n$admin:${ID}F\n$system:${ID}F"];

&matrix_test("CREATOR OWNER:F(CI)", {
				'.' => ["$owner:F\nCREATOR OWNER:(CI)(IO)F\n$admin:(OI)(CI)F\n$system:(OI)(CI)F\n$username:(OI)(CI)C"],
				'bar' => ["$owner:${ID}F\nCREATOR OWNER:(CI)(IO)${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"],
					'bar\\bas' => 'bar'
			}, ".,$owner,FULL,THIS_FOLDER_ONLY,DX\n.,\"CREATOR OWNER\",FULL,SUBFOLDERS_ONLY,DX");
&matrix_test("CREATOR OWNER:F(OI)", {
				'.' => ["$owner:F\nCREATOR OWNER:(OI)(IO)F\n$admin:(OI)(CI)F\n$system:(OI)(CI)F\n$username:(OI)(CI)C"],
				'bar' => "CREATOR OWNER:(OI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => $matrix_mod, 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$owner,FULL,THIS_FOLDER_ONLY,DX\n.,\"CREATOR OWNER\",FULL,FILES_ONLY,DX");
&matrix_test("CREATOR OWNER:F(FI)", {
				'.' => ["$owner:F\nCREATOR OWNER:(OI)(CI)(IO)F\n$admin:(OI)(CI)F\n$system:(OI)(CI)F\n$username:(OI)(CI)C"],
				'bar' => ["$owner:${ID}F\nCREATOR OWNER:(OI)(CI)(IO)${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"],
					'bar\\bas' => 'bar',
				'matrix.txt' => $matrix_mod, 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$owner,FULL,THIS_FOLDER_ONLY,DX\n.,\"CREATOR OWNER\",FULL,SUBFOLDERS_AND_FILES_ONLY,DX");
&matrix_test("CREATOR OWNER:F(CI|IO)", {
				'.' => "CREATOR OWNER:(CI)(IO)F",
				'bar' => ["$owner:${ID}F\nCREATOR OWNER:(CI)(IO)${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"],
					'bar\\bas' => 'bar'
			}, ".,\"CREATOR OWNER\",FULL,SUBFOLDERS_ONLY,DX");
&matrix_test("CREATOR OWNER:F(OI|IO)", {
				'.' => "CREATOR OWNER:(OI)(IO)F",
				'bar' => "CREATOR OWNER:(OI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => $matrix_mod, 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,\"CREATOR OWNER\",FULL,FILES_ONLY,DX");
&matrix_test("CREATOR OWNER:F(FI|IO)", {
				'.' => "CREATOR OWNER:(OI)(CI)(IO)F",
				'bar' => ["$owner:${ID}F\nCREATOR OWNER:(OI)(CI)(IO)${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"],
					'bar\\bas' => 'bar',
				'matrix.txt' => $matrix_mod, 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,\"CREATOR OWNER\",FULL,SUBFOLDERS_AND_FILES_ONLY,DX");
&matrix_test("CREATOR OWNER:F(CI|NP)", {
				'.' => ["$owner:F\nCREATOR OWNER:(CI)(NP)(IO)F\n$admin:(OI)(CI)F\n$system:(OI)(CI)F\n$username:(OI)(CI)C"],
				'bar' => ["$owner:${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"]
			}, ".,$owner,FULL,THIS_FOLDER_ONLY,DX\n.,\"CREATOR OWNER\",FULL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_ONLY,DX");
&matrix_test("CREATOR OWNER:F(OI|NP)", {
				'.' => ["$owner:F\nCREATOR OWNER:(OI)(NP)(IO)F\n$admin:(OI)(CI)F\n$system:(OI)(CI)F\n$username:(OI)(CI)C"],
				'matrix.txt' => $matrix_mod
			}, ".,$owner,FULL,THIS_FOLDER_ONLY,DX\n.,\"CREATOR OWNER\",FULL,FILES_ONLY|NO_PROPAGATE_INHERIT_ACE,DX");
&matrix_test("CREATOR OWNER:F(FI|NP)", {
				'.' => ["$owner:F\nCREATOR OWNER:(OI)(CI)(NP)(IO)F\n$admin:(OI)(CI)F\n$system:(OI)(CI)F\n$username:(OI)(CI)C"],
				'bar' => ["$owner:${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"],
				'matrix.txt' => $matrix_mod
			}, ".,$owner,FULL,THIS_FOLDER_ONLY,DX\n.,\"CREATOR OWNER\",FULL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_AND_FILES_ONLY,DX");
&matrix_test("CREATOR OWNER:F(CI|IO|NP)", {
				'.' => "CREATOR OWNER:(CI)(NP)(IO)F",
				'bar' => ["$owner:${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"]
			}, ".,\"CREATOR OWNER\",FULL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_ONLY,DX");
&matrix_test("CREATOR OWNER:F(OI|IO|NP)", {
				'.' => "CREATOR OWNER:(OI)(NP)(IO)F",
				'matrix.txt' => $matrix_mod
			}, ".,\"CREATOR OWNER\",FULL,FILES_ONLY|NO_PROPAGATE_INHERIT_ACE,DX");
&matrix_test("CREATOR OWNER:F(FI|IO|NP)", {
				'.' => "CREATOR OWNER:(OI)(CI)(NP)(IO)F",
				'bar' => ["$owner:${ID}F\n$admin:(OI)(CI)${AIO}${ID}F\n$system:(OI)(CI)${ID}F\n$username:(OI)(CI)${UIO}${ID}C"],
				'matrix.txt' => $matrix_mod
			}, ".,\"CREATOR OWNER\",FULL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_AND_FILES_ONLY,DX");


&matrix_test("$guest:GENERIC_ALL(CI)", {
				'.' => "$guest:F\n$guest:(CI)(IO)F",
				'bar' => "$guest:${ID}F\n$guest:(CI)(IO)${ID}F", 'bar\\bas' => 'bar'
			}, ".,$guest,FULL,THIS_FOLDER_ONLY,DX\n.,$guest,GENERIC_ALL,SUBFOLDERS_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL(OI)", {
				'.' => "$guest:F\n$guest:(OI)(IO)F",
				'bar' => "$guest:(OI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,FULL,THIS_FOLDER_ONLY,DX\n.,$guest,GENERIC_ALL,FILES_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL", {
				'.' => "$guest:F\n$guest:(OI)(CI)(IO)F",
				'bar' => "$guest:${ID}F\n$guest:(OI)(CI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,FULL,THIS_FOLDER_ONLY,DX\n.,$guest,GENERIC_ALL,SUBFOLDERS_AND_FILES_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL(CI|IO)", {
				'.' => "$guest:(CI)(IO)F",
				'bar' => "$guest:${ID}F\n$guest:(CI)(IO)${ID}F", 'bar\\bas' => 'bar'
			}, ".,$guest,GENERIC_ALL,SUBFOLDERS_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL(OI|IO)", {
				'.' => "$guest:(OI)(IO)F",
				'bar' => "$guest:(OI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,GENERIC_ALL,FILES_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL(FI|IO)", {
				'.' => "$guest:(OI)(CI)(IO)F",
				'bar' => "$guest:${ID}F\n$guest:(OI)(CI)(IO)${ID}F", 'bar\\bas' => 'bar',
				'matrix.txt' => "$guest:${ID}F", 'bar\bar.txt' => 'matrix.txt', 'bar\bas\bas.txt' => 'matrix.txt'
			}, ".,$guest,GENERIC_ALL,SUBFOLDERS_AND_FILES_ONLY,DX");

&matrix_test("$guest:GENERIC_ALL(CI|NP)", {
				'.' => "$guest:F\n$guest:(CI)(NP)(IO)F",
				'bar' => "$guest:${ID}F"
			}, ".,$guest,FULL,THIS_FOLDER_ONLY,DX\n.,$guest,GENERIC_ALL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL(OI|NP)", {
				'.' => "$guest:F\n$guest:(OI)(NP)(IO)F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,FULL,THIS_FOLDER_ONLY,DX\n.,$guest,GENERIC_ALL,FILES_ONLY|NO_PROPAGATE_INHERIT_ACE,DX");
&matrix_test("$guest:GENERIC_ALL(FI|NP)", {
				'.' => "$guest:F\n$guest:(OI)(CI)(NP)(IO)F",
				'bar' => "$guest:${ID}F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,FULL,THIS_FOLDER_ONLY,DX\n.,$guest,GENERIC_ALL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_AND_FILES_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL(CI|IO|NP)", {
				'.' => "$guest:(CI)(NP)(IO)F",
				'bar' => "$guest:${ID}F"
			}, ".,$guest,GENERIC_ALL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_ONLY,DX");
&matrix_test("$guest:GENERIC_ALL(OI|IO|NP)", {
				'.' => "$guest:(OI)(NP)(IO)F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,GENERIC_ALL,FILES_ONLY|NO_PROPAGATE_INHERIT_ACE,DX");
&matrix_test("$guest:GENERIC_ALL(FI|IO|NP)", {
				'.' => "$guest:(OI)(CI)(NP)(IO)F",
				'bar' => "$guest:${ID}F",
				'matrix.txt' => "$guest:${ID}F"
			}, ".,$guest,GENERIC_ALL,NO_PROPAGATE_INHERIT_ACE|SUBFOLDERS_AND_FILES_ONLY,DX");



# END eval block from the top of the section that interacts with the file system
};
my $err = $@;

system("rd /s /q \"$tempdir\"");
-d "$tempdir" and die "$0 used a temp directory for testing.  Unable to erase the directory '$tempdir' after testing was completed.\n";

die $err if $err ne '';




sub matrix_test {
	my($allow, $cacls_hash, $permdump) = @_;

	-d "$tempdir\\matrix" and die "Directory '$tempdir\\matrix' already exists.\n";
	mkdir("$tempdir\\matrix");
	-d "$tempdir\\matrix" or die "Unable to create dir '$tempdir\\matrix'.\n";

	ok(	&permchg("$tempdir\\matrix", "-q -r -b -a=\"$allow\" -a=\"$admin:F\" -a=\"$system:F\" -a=\"$username:M\""), "" );

	foreach my $dir ('bar', 'bar\\bas') {
		mkdir("$tempdir\\matrix\\$dir");
		-d "$tempdir\\matrix\\$dir" or die "Unable to create dir '$tempdir\\matrix\\$dir'.\n";
	}

	foreach my $file ('matrix.txt', 'bar\\bar.txt', 'bar\\bas\\bas.txt') {
		touch("$tempdir\\matrix\\$file");
		-e "$tempdir\\matrix\\$file" or die "Unable to create '$tempdir\\matrix\\$file'.\n";
	}

	foreach my $node (qw(. matrix.txt bar bar\\bar.txt bar\\bas bar\\bas\\bas.txt)) {
		my $cacls = $cacls_hash->{$node};
		while (defined $cacls && exists $cacls_hash->{$cacls}) {
			$cacls = $cacls_hash->{$cacls};
		}
		my $flags = ($node =~ /\.txt$/ ? '' : '(OI)(CI)') .
					($node eq '.' ? '' : "${ID}");
		$cacls = ref($cacls) eq 'ARRAY' ? $cacls->[0] : join("\n", defined $cacls ? $cacls : (), "$admin:${flags}F", "$system:${flags}F", "$username:${flags}C");
		my(@caller) = caller(0);
		ok(	&cacls("$tempdir\\matrix" . ($node eq '.' ? '' : "\\$node")), $cacls, "Matrix Test (line $caller[2]): '$allow', '$node'");
	}

	my(@permdump) = map {s/^\.,/$tempdir\\matrix,/ or s/^/$tempdir\\matrix\\/; $_ } split(/\n/, $permdump);
	$permdump = join("\n",
			"$tempdir\\matrix,,INHERITANCE_BLOCKED,,DB",
			@permdump,
			"$tempdir\\matrix,BUILTIN\\Administrators,FULL,FULL_INHERIT,DX",
			"$tempdir\\matrix,\"NT AUTHORITY\\SYSTEM\",FULL,FULL_INHERIT,DX",
			"$tempdir\\matrix,$username,MODIFY,FULL_INHERIT,DX",
		);

	ok(	&permdump("$tempdir\\matrix", '-c -r'), $permdump, "Matrix Test: '$allow'" );

	system("rd /s /q \"$tempdir\\matrix\"");
}


sub cacls {
	my($file) = @_;

	my $retval = join("\n", map { s/^\s+//g; s/\s+$//g; s/\s+/ /g; $_ ne '' ? $_ : () } `cacls.exe "$file" 2>&1`);
	substr($retval, 0, length($file) + 1) eq "$file " or return "Unable to parse cacls.exe output.\n";
	return substr($retval, length($file) + 1);
}

sub permdump {
	my($file, $options) = @_;

	$options = '-c -i' unless defined $options;
	my $recurse = $options =~ /-r/;

	my $retval = join("\n", map { 
			chomp;
			$_ = '' if $_ eq 'Path,Trustee,Mask,Inheritance,Desc';
			if (!$recurse) {
				($_ eq '' || substr($_, 0, length($file) + 1) eq "$file,") or return "Unable to parse PermDump.pl output: '$_'.\n";
				$_ = substr($_, length($file) + 1) if $_ ne '';
			}
			$_ ne '' ? $_ : ()
		} `perl.exe "$script_dir\\PermDump.pl" $options "$file" 2>&1`);
	return $retval;
}

sub permfix {
	my($file, $options) = @_;

	return `perl.exe "$script_dir\\PermFix.pl" $options "$file" 2>&1`;
}

sub permchg {
	my($file, $options) = @_;

	my $echo = $options =~ /-q/ ? '' : "echo y| ";

	return `${echo}perl.exe "$script_dir\\PermChg.pl" $options "$file" 2>&1`;
}

sub touch {
	my($file) = @_;

	open(TEMP, ">>$file") or return 0;
	close(TEMP);
	return 1;
}

sub move {
	my($file1, $file2) = @_;

	return system("move \"$file1\" \"$file2\" 1>NUL 2>NUL") ? 0 : 1;
}
