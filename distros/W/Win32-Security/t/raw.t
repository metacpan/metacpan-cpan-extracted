use strict;
$^W++;
# Modules under test
use Win32::Security::Raw;

# Modules to support specific tests
use Config; # Supports archname (x86 vs x64)
use Win32; # Supports IsAdminUser
use Win32::Security::ACL; # Build DACL for writing
use Win32::Security::SID; # Decipher returned SID

# Modules to support test harness
use Data::Dumper;
use Test;

use vars qw($enabled);
BEGIN {
	$|++;
	$enabled = 1; #Change this to 0 to disable tests
	plan tests => $enabled ? 75 : 1,
}
if (!$enabled) {
	ok(1);
	exit;
}


$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1; #Repeated to avoid warnings



#### Internal functions for x86 vs x64

# _is_x64
ok(	{0 => 'x86', 1 => 'x64'}->{Win32::Security::Raw::_is_x64},
	(split(/-/, $Config{archname}))[1],
	"_is_x64 returns 0 (maps to x86) on x86, 1 (maps to x64) on x64");

# _uint32
ok(	Win32::Security::Raw::_uint32,
	{0 => 'I', 1 => 'I'}->{Win32::Security::Raw::_is_x64},
	"_uint32 returns I on x86, I on x64");

# _uint64
ok(	Win32::Security::Raw::_uint64,
	{0 => 'I', 1 => 'Q'}->{Win32::Security::Raw::_is_x64},
	"_uint64 returns I on x86, Q on x64");

# _pack_uint32
ok(	Win32::Security::Raw::_pack_uint32,
	{0 => 'V', 1 => 'V'}->{Win32::Security::Raw::_is_x64},
	"_uint32 returns V on x86, V on x64");

# _pack_uint64
ok(	Win32::Security::Raw::_pack_uint64,
	{0 => 'V', 1 => 'Q'}->{Win32::Security::Raw::_is_x64},
	"_uint64 returns V on x86, Q on x64");



#### Memory functions ####

# LocalAlloc
my $lptr = eval { Win32::Security::Raw::LocalAlloc('LPTR', 40) };
ok(	sub { (defined $lptr) && ($lptr != 0) }, 1,
	"Attempt to allocate 40 bytes should return defined pointer");
ok(	$@, "",
	"Attempt to allocate 40 bytes should NOT result in an error message");

# LocalSize
ok(	Win32::Security::Raw::LocalSize($lptr), 40,
	"Attempt to allocate 40 bytes should allocate 40 bytes");

# CopyMemory_Read
ok(	Win32::Security::Raw::CopyMemory_Read($lptr, 40),
	"\0" x 40,
	"Initial 40 byte allocation should be all null bytes");
ok(	Win32::Security::Raw::CopyMemory_Read($lptr),
	"\0" x 40,
	"CopyMemory_Read without passed size should read 40 byte allocation should be all null bytes");

# CopyMemory_Write
eval { Win32::Security::Raw::CopyMemory_Write("My Test String 1234", $lptr) };
ok(	$@, "",
	"Attempt to write string to allocated 40 bytes should NOT result in an error message");

ok(	Win32::Security::Raw::CopyMemory_Read($lptr),
	"My Test String 1234" . ("\0" x 21),
	"After writing, the 40 byte allocation should have the data and then null bytes");
ok(	Win32::Security::Raw::CopyMemory_Read($lptr, 30),
	"My Test String 1234" . ("\0" x 11),
	"After writing, a read with a 30 byte length should read only 30 bytes");

# LocalFree
eval { Win32::Security::Raw::LocalFree($lptr) };
ok(	$@, "",
	"Attempt to free allocated 40 bytes should NOT result in an error message");
ok(	$lptr, undef,
	"Call to LocalFree should update passed value to undef");



#### Process functions ####

# GetCurrentProcess
ok(	Win32::Security::Raw::GetCurrentProcess(),
	-1,
	"GetCurrentProcess returns the special handle -1 always");

# OpenProcessToken
my $th = eval { Win32::Security::Raw::OpenProcessToken(
					Win32::Security::Raw::GetCurrentProcess(),
					"TOKEN_ADJUST_PRIVILEGES|TOKEN_QUERY"
				) };
ok(	sub { (defined $th) && ($th != 0) }, 1,
	"Attempt to open current process token should return handle");
ok(	$@, "",
	"Attempt to open current process token should NOT result in an error message");

# LookupPrivilegeValue
my $bad_luid = eval { Win32::Security::Raw::LookupPrivilegeValue(undef, 'BadPrivilegeName') };
ok(	$bad_luid, undef,
	"Attempt to LookupPrivilegeValue invalid privilege name should return undef");
ok(	$@,
	qr/LookupPrivilegeValue: A specified privilege does not exist/,
	"Attempt to LookupPrivilegeValue invalid privilege name SHOULD result in an error message");

my $luid_SeChangeNotify = eval { Win32::Security::Raw::LookupPrivilegeValue('', 'SeChangeNotifyPrivilege') };
ok(	$luid_SeChangeNotify,
	"\x17\x00\x00\x00\x00\x00\x00\x00",
	"LookupPrivilegeValue works and returns 8 bytes with hex x17 in the first byte for SeChangeNotifyPrivilege");

my $luid_SeIncreaseWorkingSet = eval { Win32::Security::Raw::LookupPrivilegeValue('', 'SeIncreaseWorkingSetPrivilege') };
ok(	$luid_SeIncreaseWorkingSet,
	"\x21\x00\x00\x00\x00\x00\x00\x00",
	"LookupPrivilegeValue works and returns 8 bytes with hex x21 in the first byte for SeIncreaseWorkingSetPrivilege");

my $luid_SeRestore = eval { Win32::Security::Raw::LookupPrivilegeValue('', 'SeRestorePrivilege') };
ok(	$luid_SeRestore,
	"\x12\x00\x00\x00\x00\x00\x00\x00",
	"LookupPrivilegeValue works and returns 8 bytes with hex x12 in the first byte for SeRestorePrivilege");

my $luid_SeTakeOwnership = eval { Win32::Security::Raw::LookupPrivilegeValue('', 'SeTakeOwnershipPrivilege') };
ok(	$luid_SeTakeOwnership,
	"\x09\x00\x00\x00\x00\x00\x00\x00",
	"LookupPrivilegeValue works and returns 8 bytes with hex x09 in the first byte for SeTakeOwnershipPrivilege");

my $luid_SeTcb = eval { Win32::Security::Raw::LookupPrivilegeValue('', 'SeTcbPrivilege') };
ok(	$luid_SeTcb,
	"\x07\x00\x00\x00\x00\x00\x00\x00",
	"LookupPrivilegeValue works and returns 8 bytes with hex x07 in the first byte for SeTcbPrivilege");


# AdjustTokenPrivileges
my($ps, $err) = eval { Win32::Security::Raw::AdjustTokenPrivileges(
							$th, 0,
							[ [$luid_SeChangeNotify, 'SE_PRIVILEGE_ENABLED'] ]
						) };
ok( $@, "", "Call to AdjustTokenPrivileges should not THROW error");
ok(	$err, "",
	"Call to AdjustTokenPrivileges with SeChangeNotifyPrivilege should NOT return error");
ok(	Data::Dumper->Dump([ $ps ]),
	Data::Dumper->Dump([ [ ] ]),
	"Call to AdjustTokenPrivileges with SeChangeNotifyPrivilege returns empty result set because it is asserted by default");

my($ps, $err) = eval { Win32::Security::Raw::AdjustTokenPrivileges(
					$th, 0,
					[ [$luid_SeIncreaseWorkingSet, 'SE_PRIVILEGE_ENABLED'] ]
				) };
ok( $@, "", "Call to AdjustTokenPrivileges should not THROW error");
ok(	$err, "",
	"Call to AdjustTokenPrivileges with SeIncreaseWorkingSetPrivilege should NOT return error");
ok(	Data::Dumper->Dump([ $ps ]),
	Data::Dumper->Dump([ [ [ $luid_SeIncreaseWorkingSet, { 'SE_PRIVILEGE_USED_FOR_ACCESS' => 1 } ] ] ]),
	"Call to AdjustTokenPrivileges with SeIncreaseWorkingSetPrivilege succeeds for both Admins and non-admins");

my($ps, $err) = eval { Win32::Security::Raw::AdjustTokenPrivileges(
					$th, 0,
					[ [$luid_SeRestore, 'SE_PRIVILEGE_ENABLED'] ]
				) };
if ( Win32::IsAdminUser() ) {
	ok( $@, "", "Call to AdjustTokenPrivileges should not THROW error");
	ok(	$err, "",
		"Call to AdjustTokenPrivileges with SeRestorePrivilege when running with Admin should NOT return error");
	ok(	Data::Dumper->Dump([ $ps ]),
		Data::Dumper->Dump([ [ [ $luid_SeRestore, { 'SE_PRIVILEGE_USED_FOR_ACCESS' => 1 } ] ] ]),
		"");
}
else {
	ok( $@, "", "Call to AdjustTokenPrivileges should not THROW error");
	ok(	$err,
		qr/AdjustTokenPrivileges: Not all privileges or groups referenced are assigned to the caller/,
		"Call to AdjustTokenPrivileges with SeRestorePrivilege when running without Admin SHOULD return error");
	ok(	"", "", "Null test for AdjustTokenPrivileges without Admin." );
}

my($ps, $err) = eval { Win32::Security::Raw::AdjustTokenPrivileges(
					$th, 0,
					[ [$luid_SeTakeOwnership, 'SE_PRIVILEGE_ENABLED'], [$luid_SeTcb, 'SE_PRIVILEGE_ENABLED'] ]
				) };
if ( Win32::IsAdminUser() ) {
	ok( $@, "", "Call to AdjustTokenPrivileges should not THROW error");
	ok(	$err,
		qr/AdjustTokenPrivileges: Not all privileges or groups referenced are assigned to the caller/,
		"Call to AdjustTokenPrivileges with SeTakeOwnershipPrivilege AND SeTcbPrivilege when running with Admin SHOULD return error");
	ok(	Data::Dumper->Dump([ $ps ]),
		Data::Dumper->Dump([ [ [ $luid_SeTakeOwnership, { 'SE_PRIVILEGE_USED_FOR_ACCESS' => 1 } ] ] ]),
		"");
}
else {
	ok( $@, "", "Call to AdjustTokenPrivileges should not THROW error");
	ok(	$err,
		qr/AdjustTokenPrivileges: Not all privileges or groups referenced are assigned to the caller/,
		"Call to AdjustTokenPrivileges with SeRestorePrivilege when running without Admin SHOULD return error");
	ok(	"", "", "Null test for AdjustTokenPrivileges without Admin." );
}



#### Security Descriptor read functions ####

# Prepare tempdir for testing
my $tempdir = "$ENV{TEMP}\\Win32-Security_TestDir_$$";
-d $tempdir and die "$0 requires a temp directory for testing.  The directory '$tempdir' already exists so testing has halted.\n";
mkdir($tempdir, 0);
-d $tempdir or die "$0 requires a temp directory for testing.  Unable to create the directory '$tempdir' so testing has halted.\n";

# BEGIN eval block from the top of the section that interacts with the file system
eval {

# GetNamedSecurityInfo
my($psidOwner, $psidGroup, $pDacl, $pSacl, $pSecurityDescriptor) =
		eval { Win32::Security::Raw::GetNamedSecurityInfo(
					$tempdir, 'SE_FILE_OBJECT',
					'OWNER_SECURITY_INFORMATION|DACL_SECURITY_INFORMATION'
				) };
ok(	$@, "",
	"Call to GetNamedSecurityInfo should NOT result in an error message");
ok(	sub { (defined $psidOwner) && ($psidOwner != 0) }, 1,
	"Call to GetNamedSecurityInfo with OWNER_SECURITY_INFORMATION should return defined psidOwner");
ok(	sub { (defined $psidGroup) && ($psidGroup == 0) }, 1,
	"Call to GetNamedSecurityInfo without GROUP_SECURITY_INFORMATION should return null psidGroup");
ok(	sub { (defined $pDacl) && ($pDacl != 0) }, 1,
	"Call to GetNamedSecurityInfo with DACL_SECURITY_INFORMATION should return defined pDacl");
ok(	sub { (defined $pSacl) && ($pSacl == 0) }, 1,
	"Call to GetNamedSecurityInfo without SACL_SECURITY_INFORMATION should return null pSacl");
ok(	sub { (defined $pSecurityDescriptor) && ($pSecurityDescriptor != 0) }, 1,
	"Call to GetNamedSecurityInfo should return defined pSecurityDescriptor");

# GetSecurityDescriptorControl
my($SdControl, $SdRevision) = eval { Win32::Security::Raw::GetSecurityDescriptorControl($pSecurityDescriptor) };
ok(	$@, "",
	"Call to GetSecurityDescriptorControl should NOT result in an error message");
ok(	Data::Dumper->Dump([$SdControl]),
		Data::Dumper->Dump([ { 'SE_DACL_PRESENT' => 1, 'SE_SELF_RELATIVE' => 1 } ]),
	"Call to GetSecurityDescriptorControl should return valid \$SdControl hash");
ok(	sub { (defined $SdRevision) && ($SdRevision != 0) }, 1,
	"Call to GetSecurityDescriptorControl should return valid \$SdRevision");

# GetLengthSid
my($sidLength) = eval { Win32::Security::Raw::GetLengthSid($psidOwner) };
ok(	$@, "",
	"Call to GetLengthSid should NOT result in an error message");
ok(	sub { (defined $sidLength) && ($sidLength != 0) }, 1,
	"Call to GetLengthSid should return valid \$sidLength");

my $Sid = eval { Win32::Security::Raw::CopyMemory_Read($psidOwner, $sidLength) };
ok(	$@, "",
	"Call to CopyMemory_Read to read the Sid should NOT result in an error message");
ok(	length($Sid),
	$sidLength,
	"Call to CopyMemory_Read to read the Sid should return a string of $sidLength bytes");

my $sidOwner = eval { Win32::Security::SID::ConvertSidToName($Sid) };
ok(	$@, "",
	"Call to ConvertSidToName to interpret the Sid should NOT result in an error message");
ok(	uc($sidOwner),
	uc( Win32::IsAdminUser() ? 'BUILTIN\\Administrators' : $ENV{USERDOMAIN}."\\".$ENV{USERNAME} ),
	"Call to ConvertSidToName to interpret the Sid should return the current user");

# GetAclInformation
my($AclRevision) = eval { Win32::Security::Raw::GetAclInformation($pDacl, 'AclRevisionInformation') };
ok(	$@, "",
	"Call to GetAclInformation for AclRevisionInformation should NOT result in an error message");
ok(	sub { (defined $AclRevision) && ($AclRevision != 0) }, 1,
	"Call to GetSecurityDescriptorControl should return valid \$AclRevision");

my($AceCount, $AclBytesInUse, $AclBytesFree) = eval { Win32::Security::Raw::GetAclInformation($pDacl, 'AclSizeInformation') };
ok(	$@, "",
	"Call to GetAclInformation for AclSizeInformation should NOT result in an error message");
ok(	sub { (defined $AceCount) && ($AceCount != 0) }, 1,
	"Call to GetSecurityDescriptorControl should return valid \$AceCount");
ok(	sub { (defined $AclBytesInUse) && ($AclBytesInUse != 0) }, 1,
	"Call to GetSecurityDescriptorControl should return valid \$AclBytesInUse");
ok(	$AclBytesFree, 0,
	"Call to GetSecurityDescriptorControl should return 0 for \$AclBytesFree");

# LocalFree $pSecurityDescriptor
eval { Win32::Security::Raw::LocalFree($pSecurityDescriptor) };
ok(	$@, "",
	"Attempt to free \$pSecurityDescriptor should NOT result in an error message");
ok(	$pSecurityDescriptor, undef,
	"Call to LocalFree should update \$pSecurityDescriptor to undef");


#### Security Descriptor write functions ####

# SECURITY_DESCRIPTOR_MIN_LENGTH
# _pack_uint64
ok(	Win32::Security::Raw::SECURITY_DESCRIPTOR_MIN_LENGTH(),
	{0 => 20, 1 => 36}->{Win32::Security::Raw::_is_x64},
	"SECURITY_DESCRIPTOR_MIN_LENGTH returns 20 on x86, 36 on x64");

# InitializeSecurityDescriptor
my $pSecurityDescriptor = eval { Win32::Security::Raw::InitializeSecurityDescriptor() };
ok(	sub { (defined $pSecurityDescriptor) && ($pSecurityDescriptor != 0) }, 1,
	"Call to InitializeSecurityDescriptor should return defined pointer");
ok(	$@, "",
	"Call to InitializeSecurityDescriptor should NOT result in an error message");
ok(	Win32::Security::Raw::LocalSize($pSecurityDescriptor),
	Win32::Security::Raw::SECURITY_DESCRIPTOR_MIN_LENGTH(),
	"Call to InitializeSecurityDescriptor should return pointer to SECURITY_DESCRIPTOR_MIN_LENGTH bytes");
ok(	Win32::Security::Raw::CopyMemory_Read($pSecurityDescriptor),
	"\1" . ( "\0" x ( Win32::Security::Raw::SECURITY_DESCRIPTOR_MIN_LENGTH() - 1) ),
	"Data in \$pSecurityDescriptor should start with a 1 byte and then be all null bytes");

# SetSecurityDescriptorDacl
my $SecurityInfo = &Win32::Security::SECURITY_INFORMATION->build_mask(DACL_SECURITY_INFORMATION);
my $dacl = Win32::Security::ACL->new('FILE',
			Win32::Security::ACE->new('FILE', 'ALLOW', 'FULL_INHERIT', 'FULL',
					$ENV{USERDOMAIN}."\\".$ENV{USERNAME}
				)
		);
my $rawDacl = $dacl->rawAcl();

my $pDacl = eval { Win32::Security::Raw::LocalAlloc('LPTR', length($rawDacl)) };
ok(	sub { (defined $pDacl) && ($pDacl != 0) }, 1,
	"Call to LocalAlloc should return defined pointer");
ok(	$@, "",
	"Call to LocalAlloc should NOT result in an error message");

ok(	Win32::Security::Raw::LocalSize($pDacl),
	length($rawDacl),
	"Call to LocalAlloc should return pointer to length(\$rawDacl) bytes");

eval { Win32::Security::Raw::CopyMemory_Write($rawDacl, $pDacl) };
ok(	$@, "",
	"Attempt to write string to allocated $pDacl should NOT result in an error message");

my $SecurityDescriptor_Previous_Contents = Win32::Security::Raw::CopyMemory_Read($pSecurityDescriptor);
eval { Win32::Security::Raw::SetSecurityDescriptorDacl($pSecurityDescriptor, 1, $pDacl, 0) };
ok(	$@, "",
	"Call to SetSecurityDescriptorDacl should NOT result in an error message");
ok( sub { $SecurityDescriptor_Previous_Contents ne
			Win32::Security::Raw::CopyMemory_Read($pSecurityDescriptor) }, 1,
	"Call to SetSecurityDescriptorDacl should mutate contents of \$pSecurityDescriptor");

# SetFileSecurity
eval { Win32::Security::Raw::SetFileSecurity(
			$tempdir, 'DACL_SECURITY_INFORMATION', $pSecurityDescriptor
		) };
ok(	$@, "",
	"Call to SetFileSecurity should NOT result in an error message");

# SetNamedSecurityInfo
eval { Win32::Security::Raw::SetNamedSecurityInfo(
			$tempdir, 'SE_FILE_OBJECT', 'DACL_SECURITY_INFORMATION',
			undef, undef, $rawDacl, undef
		) };
ok(	$@, "",
	"Call to SetFileSecurity should NOT result in an error message");

# LocalFree $pSecurityDescriptor again
eval { Win32::Security::Raw::LocalFree($pSecurityDescriptor) };
ok(	$@, "",
	"Attempt to free \$pSecurityDescriptor should NOT result in an error message");
ok(	$pSecurityDescriptor, undef,
	"Call to LocalFree should update \$pSecurityDescriptor to undef");

# END eval block from the top of the section that interacts with the file system
};
my $err = $@;

system("rd /s /q \"$tempdir\"");
-d "$tempdir" and die "$0 used a temp directory for testing.  Unable to erase the directory '$tempdir' after testing was completed.\n";

die $err if $err ne '';
