#############################################################################
#
# Win32::Security::Raw - low-level access Win32 Security API calls
#
# Author: Toby Ovod-Everett
#
#############################################################################
# Copyright 2003, 2004 Toby Ovod-Everett.  All rights reserved
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

=head1 NAME

C<Win32::Security::Raw> - low-level access Win32 Security API calls

=head1 SYNOPSIS

	use Win32::Security::Raw;

=head1 DESCRIPTION

This module provides access to a limited number of Win32 Security API calls.
As I have need for other functions I will add them to the module.  If anyone
has suggestions, feel free to ask - I will be quite happy to extend this
module.


=head2 Installation instructions

This installs as part of C<Win32-Security>.  See 
C<Win32::Security::NamedObject> for more information.

It depends upon the C<Win32::API> and C<Data::BitMask> modules, which
should be installable via PPM or available on CPAN.

=cut

use Carp;
use Win32::API;
use Data::BitMask '0.13';

use strict;

package Win32::Security::Raw;

=head1 Function Reference

=head2 C<AdjustTokenPrivileges>

=cut

{
my $call;
sub AdjustTokenPrivileges {
	my($TokenHandle, $DisableAllPrivileges, $NewState) = @_;

	ref($NewState) eq 'ARRAY' or Carp::croak("AdjustTokenPrivileges requires array ref for NewState.");
	scalar(@{$NewState}) >= 1 or Carp::croak("AdjustTokenPrivileges requires at least one element for NewState.");
	my $pNewState = pack('V', scalar(@{$NewState}));
	foreach my $laa (@{$NewState}) {
		ref($laa) eq 'ARRAY' or Carp::croak("AdjustTokenPrivileges requires all elements of NewState to be array refs.");
		scalar(@{$laa}) == 2 or Carp::croak("AdjustTokenPrivileges requires all elements of NewState to be array refs with two elements.");
		length($laa->[0]) == 8 or Carp::croak("AdjustTokenPrivileges requires all LUID values to be 8 bytes.");
		$pNewState .= $laa->[0].pack('V', &Win32::Security::LUID_ATTRIBUTES->build_mask($laa->[1]));
	}

	my $BufferLength = length($pNewState);
	my $pPreviousState = ("\0" x $BufferLength);
	my $pReturnLength = pack('V', $BufferLength);

	$call ||= Win32::API->new('advapi32',
				'AdjustTokenPrivileges', [qw(I I P I P P)], 'I') or
			Carp::croak("Unable to connect to AdjustTokenPrivileges.");

	$call->Call($TokenHandle, $DisableAllPrivileges, $pNewState, $BufferLength, $pPreviousState, $pReturnLength);
	my $error = Win32::GetLastError();
	$error and Carp::croak(&_format_error('AdjustTokenPrivileges', $error));

	my $PreviousCount = unpack('V', $pPreviousState);
	my $PreviousState = [];
	foreach my $i (0..$PreviousCount-1) {
		my $Luid = substr($pPreviousState, $i*12+4, 8);
		my $Attributes = &Win32::Security::LUID_ATTRIBUTES->break_mask(unpack('V', substr($pPreviousState, $i*12+12, 4)));
		push(@{$PreviousState}, [$Luid, $Attributes]);
	}

	return $PreviousState;
}
}


=head2 C<CopyMemory_Read>

Uses C<RtlMoveMemory> to read an arbitrary memory location.  You should pass a
pointer in the form of a Perl integer and the number of bytes to read from that
location.  The function will return the data read in a Perl string.

=cut

{
my $call;
sub CopyMemory_Read {
	my($pSource, $Length) = @_;

	$call ||= Win32::API->new('kernel32',
				'RtlMoveMemory', [qw(P I I)], 'V') or
			Carp::croak("Unable to connect to RtlMoveMemory.");

	my $Destination = "\0"x$Length;
	$call->Call($Destination, $pSource, $Length);
	return $Destination;
}
}


=head2 C<CopyMemory_Write>

Uses C<RtlMoveMemory> to write to an arbitrary memory location.  You should pass 
a string that will be copied and a pointer in the form of a Perl integer.  The 
caller is responsible for ensuring that the data to be written will not overrun 
the memory location.

=cut

{
my $call;
sub CopyMemory_Write {
	my($string, $pDest) = @_;

	$call ||= Win32::API->new('kernel32',
				'RtlMoveMemory', [qw(I P I)], 'V') or
			Carp::croak("Unable to connect to RtlMoveMemory.");
	$call->Call($pDest, $string, length($string));
}
}


=head2 C<GetCurrentProcess>

Returns a handle to the C<CurrentProcess> as an integer.

=cut

{
my $call;
sub GetCurrentProcess {
	$call ||= Win32::API->new('kernel32',
				'GetCurrentProcess', [], 'I') or
			Carp::croak("Unable to connect to GetCurrentProcess.");

	$call->Call();
}
}


=head2 C<GetAclInformation>

This expects a pointer to an ACL and an C<AclInformationClass> value (i.e. 
C<'AclSizeInformation'> or C<'AclRevisionInformation'>).  It returns the 
approriate data for the C<AclInformationClass> value (the C<AclRevision> in the 
case of C<AclRevisionInformation>, the C<AceCount>, C<AclBytesInUse>, and 
C<AclBytesFree> in the case of C<AclSizeInformation>).

=cut

{
my $call;
sub GetAclInformation {
	my($pAcl, $dwAclInformationClass) = @_;

	$call ||= Win32::API->new('advapi32',
				'GetAclInformation', [qw(I P I I)], 'I') or
			Carp::croak("Unable to connect to GetAclInformation.");

	my $structures = {
		AclRevisionInformation  => 'V',
		AclSizeInformation => 'VVV'
	};

	my($pAclInformation) = (pack($structures->{$dwAclInformationClass}));

	$call->Call($pAcl, $pAclInformation, length($pAclInformation),
				&Win32::Security::ACL_INFORMATION_CLASS->build_mask($dwAclInformationClass)) or
			Carp::croak(&_format_error('GetAclInformation'));

	my(@retvals) = unpack($structures->{$dwAclInformationClass}, $pAclInformation);

	return(@retvals);
}
}


=head2 C<GetLengthSid>

This accepts a pointer to a SID as an integer and returns the length.

=cut

{
my $call;
sub GetLengthSid {
	my($pSid) = @_;

	$call ||= Win32::API->new('advapi32',
				'GetLengthSid', [qw(I)], 'I') or
			Carp::croak("Unable to connect to GetLengthSid.");

	return $call->Call($pSid);
}
}


=head2 C<GetNamedSecurityInfo>

This expects an object name (i.e. a path to a file, registry key, etc.), an 
object type (i.e. C<'SE_FILE_OBJECT'>), and a C<SECURITY_INFORMATION> mask (i.e. 
C<'OWNER_SECURITY_INFORMATION|DACL_SECURITY_INFORMATION'>).  It returns pointers 
(as integers) to C<sidOwner>, C<sidGroup>, C<Dacl>, C<Sacl>, and the 
C<SecurityDescriptor>.  Some of these may be null pointers.

=cut

{
my $call;
sub GetNamedSecurityInfo {
	my($pObjectName, $ObjectType, $SecurityInfo) = @_;

	$call ||= Win32::API->new('advapi32',
				'GetNamedSecurityInfo', [qw(P I I P P P P P)], 'I') or
			Carp::croak("Unable to connect to GetNamedSecurityInfo.");

	$ObjectType = &Win32::Security::SE_OBJECT_TYPE->build_mask($ObjectType);
	$SecurityInfo = &Win32::Security::SECURITY_INFORMATION->build_mask($SecurityInfo);

	my($ppsidOwner, $ppsidGroup, $ppDacl, $ppSacl, $ppSecurityDescriptor) = ("\0"x4) x 5;

	my $retval = $call->Call($pObjectName, int($ObjectType),
			$SecurityInfo, $ppsidOwner, $ppsidGroup, $ppDacl, $ppSacl, $ppSecurityDescriptor);

	$retval and Carp::croak(&_format_error('GetNamedSecurityInfo', $retval));

	foreach ($ppsidOwner, $ppsidGroup, $ppDacl, $ppSacl, $ppSecurityDescriptor) {
		$_ = unpack("V", $_);
	}

	return($ppsidOwner, $ppsidGroup, $ppDacl, $ppSacl, $ppSecurityDescriptor);
}
}


=head2 C<GetSecurityDescriptorControl>

This expects a pointer to a C<SecurityDescriptor>.  It returns the
C<Data::BitMask::break_mask> form for the
C<SECURITY_DESCRIPTOR_CONTROL> mask.

=cut

{
my $call;
sub GetSecurityDescriptorControl {
	my($pSecurityDescriptor) = @_;

	$call ||= Win32::API->new('advapi32',
				'GetSecurityDescriptorControl', [qw(I P P)], 'I') or
			Carp::croak("Unable to connect to GetSecurityDescriptorControl.");

	my($pControl, $lpdwRevision) = ("\0"x2, "\0"x4);

	$call->Call($pSecurityDescriptor, $pControl, $lpdwRevision) or
			Carp::croak(&_format_error('GetSecurityDescriptorControl'));

	$pControl = &Win32::Security::SECURITY_DESCRIPTOR_CONTROL->break_mask(unpack("S", $pControl));
	$lpdwRevision = unpack("V", $lpdwRevision);

	return($pControl, $lpdwRevision);
}
}


=head2 C<InitializeSecurityDescriptor>

Calls C<InitializeSecurityDescriptor> on the passed pointer.  C<dwRevision> is
optional - if omitted, revision 1 is used.  Dies if the call fails.

=cut

{
my $call;
sub InitializeSecurityDescriptor {
	my($pSecurityDescriptor, $dwRevision) = @_;

	$dwRevision = 1 unless defined $dwRevision;

	$call ||= Win32::API->new('advapi32',
				'InitializeSecurityDescriptor', [qw(I I)], 'I') or
			Carp::croak("Unable to connect to InitializeSecurityDescriptor.");

	$call->Call($pSecurityDescriptor, $dwRevision) or Carp::croak("Unable to InitializeSecurityDescriptor $pSecurityDescriptor.");
}
}


=head2 C<LocalAlloc>

Calls C<LocalAlloc> with the passed C<uFlags> and C<size>.  It returns the 
pointer, but dies if a null pointer is returned from the call.  The C<uFlags> 
parameter can be passed as either an integer or as legal C<LMEM_FLAGS>.

=cut

{
my $call;
sub LocalAlloc {
	my($uFlags, $uBytes) = @_;

	$uFlags = &Win32::Security::LMEM_FLAGS->build_mask($uFlags);

	$call ||= Win32::API->new('kernel32',
				'LocalAlloc', [qw(I I)], 'I') or
			Carp::croak("Unable to connect to LocalAlloc.");

	my $ptr = $call->Call($uFlags, $uBytes);
	$ptr or Carp::croak("Unable to LocalAlloc $uBytes.");
	return $ptr;
}
}


=head2 C<LocalFree>

Calls C<LocalFree> on the passed pointer.  The passed pointer should be in the
form of a Perl integer.

=cut

{
my $call;
sub LocalFree {
	my($pObject) = @_;

	$call ||= Win32::API->new('kernel32',
				'LocalFree', [qw(I)], 'I') or
			Carp::croak("Unable to connect to LocalFree.");

	$call->Call($pObject);
}
}


=head2 C<LookupPrivilegeValue>

Pass C<SystemName> (undef permitted) and a privilege C<Name> (i.e. 
C<SeRestorePrivilege>).  Returns the C<Luid>.

=cut

{
my $call;
sub LookupPrivilegeValue {
	my($lpSystemName, $lpName) = @_;

	my($lpLuid) = ("\0"x8);

	$call ||= Win32::API->new('advapi32',
				'LookupPrivilegeValue', [qw(P P P)], 'I') or
			Carp::croak("Unable to connect to LookupPrivilegeValue.");

	$call->Call($lpSystemName, $lpName, $lpLuid) or
			Carp::croak(&_format_error('LookupPrivilegeValue'));

	return $lpLuid;
}
}


=head2 C<OpenProcessToken>

Pass C<ProcessHandle> and C<DesiredAccess> (C<TokenRights>).  Returns 
C<TokenHandle>.

=cut

{
my $call;
sub OpenProcessToken {
	my($ProcessHandle, $DesiredAccess) = @_;

	$DesiredAccess = &Win32::Security::TokenRights->build_mask($DesiredAccess);

	my($TokenHandle) = ("\0"x4);

	$call ||= Win32::API->new('advapi32',
				'OpenProcessToken', [qw(I I P)], 'I') or
			Carp::croak("Unable to connect to OpenProcessToken.");

	$call->Call($ProcessHandle, $DesiredAccess, $TokenHandle) or
			Carp::croak(&_format_error('OpenProcessToken'));

	$TokenHandle = unpack("V", $TokenHandle);

	return $TokenHandle;
}
}


=head2 C<SetFileSecurity>

Pass C<FileName>, C<SecurityInfo>, and C<SecurityDescriptor>.  Useful for 
setting permissions without propagating inheritable ACEs.

=cut

{
my $call;
my $os2k;
sub SetFileSecurity {
	my($pFileName, $SecurityInfo, $pSecurityDescriptor) = @_;

	$call ||= Win32::API->new('advapi32',
				'SetFileSecurity', [qw(P I I)], 'I') or
			Carp::croak("Unable to connect to SetFileSecurity.");

	$SecurityInfo = &Win32::Security::SECURITY_INFORMATION->build_mask($SecurityInfo);

	unless (defined($os2k)) {
		my(@osver) = Win32::GetOSVersion();
		$os2k = ($osver[4] == 2 && $osver[1] >= 5);
	}

	if (!$os2k && scalar(grep(/PROTECTED/, keys %{&Win32::Security::SECURITY_INFORMATION->break_mask($SecurityInfo)})) ) {
		Carp::croak("Use of PROTECTED SECURITY_INFORMATION constant on a non Win2K or greater OS.");
	}

	$call->Call($pFileName, $SecurityInfo, $pSecurityDescriptor) or
			Carp::croak(&_format_error('SetFileSecurity'));
}
}



=head2 C<SetNamedSecurityInfo>

This expects an object name (i.e. a path to a file, registry key, etc.), an 
object type (i.e. C<'SE_FILE_OBJECT'>), and a C<SECURITY_INFORMATION> mask (i.e. 
C<'OWNER_SECURITY_INFORMATION|DACL_SECURITY_INFORMATION'>), and pointers (as 
integers) to C<sidOwner>, C<sidGroup>, C<Dacl>, and C<Sacl>.  These may be null 
pointers if they are not referenced in the C<SECURITY_INFORMATION> mask.

=cut

{
my $call;
my $os2k;
sub SetNamedSecurityInfo {
	my($pObjectName, $ObjectType, $SecurityInfo, $psidOwner, $psidGroup, $pDacl, $pSacl) = @_;

	$call ||= Win32::API->new('advapi32',
				'SetNamedSecurityInfo', [qw(P I I P P P P)], 'I') or
			Carp::croak("Unable to connect to SetNamedSecurityInfo.");

	$ObjectType = &Win32::Security::SE_OBJECT_TYPE->build_mask($ObjectType);
	$SecurityInfo = &Win32::Security::SECURITY_INFORMATION->build_mask($SecurityInfo);

	unless (defined($os2k)) {
		my(@osver) = Win32::GetOSVersion();
		$os2k = ($osver[4] == 2 && $osver[1] >= 5);
	}

	if (!$os2k && scalar(grep(/PROTECTED/, keys %{&Win32::Security::SECURITY_INFORMATION->break_mask($SecurityInfo)})) ) {
		Carp::croak("Use of PROTECTED SECURITY_INFORMATION constant on a non Win2K or greater OS.");
	}

	my $retval;
	{
		local $^W = 0; #Turn off warnings about uninitialized values . . .
		$retval = $call->Call($pObjectName, int($ObjectType),
				$SecurityInfo, $psidOwner, $psidGroup, $pDacl, $pSacl);
	}

	$retval and Carp::croak(&_format_error('SetNamedSecurityInfo', $retval));
}
}


=head2 C<SetSecurityDescriptorDacl>

Calls C<SetSecurityDescriptorDacl>.  Expects a pointer to a 
C<SecurityDescriptor>, C<DaclPresent>, C<Dacl>, and C<DaclDefaulted>.  Dies if 
the call fails.

=cut

{
my $call;
sub SetSecurityDescriptorDacl {
	my($pSecurityDescriptor, $bDaclPresent, $pDacl, $bDaclDefaulted) = @_;

	$call ||= Win32::API->new('advapi32',
				'SetSecurityDescriptorDacl', [qw(I I I I)], 'I') or
			Carp::croak("Unable to connect to SetSecurityDescriptorDacl.");

	$call->Call($pSecurityDescriptor, $bDaclPresent, $pDacl, $bDaclDefaulted) or Carp::croak("Unable to SetSecurityDescriptorDacl.");
}
}



sub _format_error {
	my($func, $retval) = @_;

	(my $msg = $func.": ".Win32::FormatMessage($retval || Win32::GetLastError()))
			=~ s/[\r\n]+$//;
	return $msg;
}



package Win32::Security;

=head1 C<Data::BitMask> Objects

The objects are accessed via class methods on C<Win32::Security>.  The
C<Data::BitMask> objects are created by the first call and lexically cached.

=cut

=head2 &Win32::Security::SE_OBJECT_TYPE

Win32 constants for C<SE_OBJECT_TYPE>, along with the following aliases:

=over 4

=item *

C<FILE> (C<SE_FILE_OBJECT>)

=item *

C<SERVICE> (C<SE_SERVICE>)

=item *

C<PRINTER> (C<SE_PRINTER>)

=item *

C<REG> (C<SE_REGISTRY_KEY>)

=item *

C<REGISTRY> (C<SE_REGISTRY_KEY>)

=item *

C<SHARE> (C<SE_LMSHARE>)

=back

=cut

{
my $cache;
sub SE_OBJECT_TYPE {
	$cache ||= Data::BitMask->new(
			SE_UNKNOWN_OBJECT_TYPE =>     0,
			SE_FILE_OBJECT =>             1,
			SE_SERVICE =>                 2,
			SE_PRINTER =>                 3,
			SE_REGISTRY_KEY =>            4,
			SE_LMSHARE =>                 5,
			SE_KERNEL_OBJECT =>           6,
			SE_WINDOW_OBJECT =>           7,
			SE_DS_OBJECT =>               8,
			SE_DS_OBJECT_ALL =>           9,
			SE_PROVIDER_DEFINED_OBJECT => 10,
			FILE =>                       1,
			SERVICE =>                    2,
			PRINTER =>                    3,
			REG =>                        4,
			REGISTRY =>                   4,
			SHARE =>                      5,
		);
}
}

=head2 &Win32::Security::SECURITY_INFORMATION

=cut

{
my $cache;
sub SECURITY_INFORMATION {
	$cache ||= Data::BitMask->new(
			OWNER_SECURITY_INFORMATION =>                      0x1,
			GROUP_SECURITY_INFORMATION =>                      0x2,
			DACL_SECURITY_INFORMATION =>                       0x4,
			SACL_SECURITY_INFORMATION =>                       0x8,
			UNPROTECTED_SACL_SECURITY_INFORMATION =>    0x10000000,
			UNPROTECTED_DACL_SECURITY_INFORMATION =>    0x20000000,
			PROTECTED_SACL_SECURITY_INFORMATION =>      0x40000000,
			PROTECTED_DACL_SECURITY_INFORMATION =>      0x80000000,
		);
}
}

=head2 &Win32::Security::SECURITY_DESCRIPTOR_CONTROL

=cut

{
my $cache;
sub SECURITY_DESCRIPTOR_CONTROL {
	$cache ||= Data::BitMask->new(
			SE_OWNER_DEFAULTED =>                0x0001,
			SE_GROUP_DEFAULTED =>                0x0002,
			SE_DACL_PRESENT =>                   0x0004,
			SE_DACL_DEFAULTED =>                 0x0008,
			SE_SACL_PRESENT =>                   0x0010,
			SE_SACL_DEFAULTED =>                 0x0020,
			SE_DACL_AUTO_INHERIT_REQ =>          0x0100,
			SE_SACL_AUTO_INHERIT_REQ =>          0x0200,
			SE_DACL_AUTO_INHERITED =>            0x0400,
			SE_SACL_AUTO_INHERITED =>            0x0800,
			SE_DACL_PROTECTED =>                 0x1000,
			SE_SACL_PROTECTED =>                 0x2000,
			SE_SELF_RELATIVE =>                  0x8000,
		);
}
}

=head2 &Win32::Security::ACL_INFORMATION_CLASS

=cut

{
my $cache;
sub ACL_INFORMATION_CLASS {
	$cache ||= Data::BitMask->new(
			AclRevisionInformation  => 1,
			AclSizeInformation      => 2,
		);
}
}

=head2 &Win32::Security::TokenRights

=cut

{
my $cache;
sub TokenRights {
	unless ($cache) {
		$cache = Data::BitMask->new(
				TOKEN_ASSIGN_PRIMARY    => 0x00000001,
				TOKEN_DUPLICATE         => 0x00000002,
				TOKEN_IMPERSONATE       => 0x00000004,
				TOKEN_QUERY             => 0x00000008,
				TOKEN_QUERY_SOURCE      => 0x00000010,
				TOKEN_ADJUST_PRIVILEGES => 0x00000020,
				TOKEN_ADJUST_GROUPS     => 0x00000040,
				TOKEN_ADJUST_DEFAULT    => 0x00000080,
				TOKEN_ADJUST_SESSIONID  => 0x00000100,

				DELETE                  => 0x00010000,
				READ_CONTROL            => 0x00020000,
				WRITE_DAC               => 0x00040000,
				WRITE_OWNER             => 0x00080000,

				ACCESS_SYSTEM_SECURITY  => 0x01000000,

				STANDARD_RIGHTS_READ    => 0x00020000,
				STANDARD_RIGHTS_WRITE   => 0x00020000,
				STANDARD_RIGHTS_EXECUTE => 0x00020000,
			);

		$cache->add_constants(
				TOKEN_EXECUTE => $cache->build_mask('STANDARD_RIGHTS_EXECUTE TOKEN_IMPERSONATE'),
				TOKEN_READ =>    $cache->build_mask('STANDARD_RIGHTS_READ TOKEN_QUERY'),
				TOKEN_WRITE =>   $cache->build_mask('STANDARD_RIGHTS_WRITE TOKEN_ADJUST_PRIVILEGES TOKEN_ADJUST_GROUPS TOKEN_ADJUST_DEFAULT'),
				TOKEN_ALL_ACCESS => $cache->build_mask('ACCESS_SYSTEM_SECURITY') | 0x000F01FF,
			);
	}
	return $cache;
}
}


=head2 &Win32::Security::LUID_ATTRIBUTES

=cut

{
my $cache;
sub LUID_ATTRIBUTES {
	$cache ||= Data::BitMask->new(
			SE_PRIVILEGE_USED_FOR_ACCESS    => 0x0000,
			SE_PRIVILEGE_ENABLED_BY_DEFAULT => 0x0001,
			SE_PRIVILEGE_ENABLED            => 0x0002,
	);
}
}


=head2 &Win32::Security::LMEM_FLAGS

=cut

{
my $cache;
sub LMEM_FLAGS {
	unless ($cache) {

		$cache = Data::BitMask->new(
				LMEM_FIXED          => 0x0000,
				LMEM_MOVEABLE       => 0x0002,
				LMEM_NOCOMPACT      => 0x0010,
				LMEM_NODISCARD      => 0x0020,
				LMEM_ZEROINIT       => 0x0040,
				LMEM_MODIFY         => 0x0080,
				LMEM_DISCARDABLE    => 0x0F00,
				LMEM_VALID_FLAGS    => 0x0F72,
				LMEM_INVALID_HANDLE => 0x8000,
			);

		$cache->add_constants(
				LHND        => $cache->build_mask('LMEM_MOVEABLE LMEM_ZEROINIT'),
				LPTR        => $cache->build_mask('LMEM_FIXED LMEM_ZEROINIT'),
				NONZEROLHND => $cache->build_mask('LMEM_MOVEABLE'),
				NONZEROLPTR => $cache->build_mask('LMEM_FIXED'),
			);
	}
	return $cache;
}
}


=head1 AUTHOR

Toby Ovod-Everett, toby@ovod-everett.org

=cut

1;
