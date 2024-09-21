#############################################################################
#
# Win32::Security::Raw - low-level access Win32 Security API calls
#
# Author: Toby Ovod-Everett
#
#############################################################################
# Copyright 2003-2024 Toby Ovod-Everett.  All rights reserved
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
use Config;
use Win32::API;
use Data::BitMask 0.13;

use strict;

package Win32::Security::Raw;

$Win32::Security::Raw::VERSION = '0.60';


=head1 Function Reference: Helper functions

=head2 C<_is_x64>

Returns 1 if Perl is x64, 0 if Perl is x86.

=cut

{
my $_is_x64;

sub _is_x64 {
	unless (defined $_is_x64) {
		my $archname = $::Config{archname};
		if ( $archname =~ /^MSWin32-x64-/ ) {
			$_is_x64 = 1;
		}
		elsif ( $archname =~ /^MSWin32-x86-/ ) {
			$_is_x64 = 0;
		}
		else {
			die "Unable to determine x64/x86 from '$archname'";
		}
	}
	return $_is_x64;
}
}


=head2 C<_uint32>

Clarifies using C<Win32::API> on both the x86 (32-bit) and x64 (64-bit)
versions of Perl.  It returns the C<Win32::API> parameter character
specifier for an unsigned 32-bit, independent of Perl bit-version:

=over

=item * C<I> (unsigned 32-bit int) on x64 Perl

=item * C<I> (unsigned 32-bit int) on x32 Perl

=back

=cut

{
my $_uint32;

sub _uint32 {
	$_uint32 ||= 'I';
	return $_uint32;
}
}


=head2 C<_uint64>

Clarifies using C<Win32::API> on both the x86 (32-bit) and x64 (64-bit)
versions of Perl.  It returns the C<Win32::API> parameter character
specifier for an unsigned pointer-sized int (i.e. 32-bit on x86, 64-bit on
x64), dependent on Perl bit-version:

=over

=item * C<Q> (unsigned 64-bit int) on x64 Perl

=item * C<I> (unsigned 32-bit int) on x32 Perl

=back

=cut

{
my $_uint64;

sub _uint64 {
	$_uint64 ||= _is_x64() ? 'Q' : 'I';
	return $_uint64;
}
}


=head2 C<_pack_uint32>

Clarifies using C<pack>/C<unpack> on both the x86 (32-bit) and x64 (64-bit)
versions of Perl.  It returns the C<pack>/C<unpack> TEMPLATE character for
an unsigned 32-bit, independent of Perl bit-version:

=over

=item * C<V> (unsigned 32-bit int) on x64 Perl

=item * C<V> (unsigned 32-bit int) on x32 Perl

=back

=cut

{
my $_pack_uint32;

sub _pack_uint32 {
	$_pack_uint32 ||= 'V';
	return $_pack_uint32;
}
}


=head2 C<_pack_uint64>

Clarifies using C<pack>/C<unpack> on both the x86 (32-bit) and x64 (64-bit)
versions of Perl.  It returns the C<pack>/C<unpack> TEMPLATE character for
an unsigned pointer-sized int (i.e. 32-bit on x86, 64-bit on x64), dependent
on Perl bit-version:

=over

=item * C<Q> (unsigned 64-bit int) on x64 Perl

=item * C<V> (unsigned 32-bit int) on x32 Perl

=back

=cut

{
my $_pack_uint64;

sub _pack_uint64 {
	$_pack_uint64 ||= _is_x64() ? 'Q' : 'V';
	return $_pack_uint64;
}
}


=head2 C<_format_error>

Formats an error message starting with the passed Win32 API function name,
followed by the output from C<Win32::FormatMessage> on the optional passed
$retval or return value from C<Win32::GetLastError>.

=cut

sub _format_error {
	my($func, $retval) = @_;

	(my $msg = $func.": ".Win32::FormatMessage($retval || Win32::GetLastError()))
			=~ s/[\r\n]+$//;
	return $msg;
}



=head1 Function Reference: Memory functions

=head2 C<LocalAlloc>

Calls C<LocalAlloc> with the passed C<Flags> and C<Bytes>.  It returns a
pointer as a Perl int, but dies if a null pointer is returned from the call.
The C<Flags> parameter can be passed as either an integer or as legal
C<Win32::Security::LMEM_FLAGS>.

=cut

{
my $call;
sub LocalAlloc {
	my($Flags, $Bytes) = @_;

	$Flags = &Win32::Security::LMEM_FLAGS->build_mask($Flags);

	$call ||= Win32::API->new('kernel32',
				'LocalAlloc', [ _uint32, _uint64 ], _uint64) or
			Carp::croak("Unable to connect to LocalAlloc.");

	my $pObject = $call->Call($Flags, $Bytes);
	$pObject or Carp::croak("Unable to LocalAlloc $Bytes.");

	return $pObject;
}
}


=head2 C<LocalFree>

Calls C<LocalFree> on the passed pointer (as Perl int).

=cut

{
my $call;
sub LocalFree {
	my($pObject) = @_;

	$call ||= Win32::API->new('kernel32',
				'LocalFree', [ _uint64 ], _uint64) or
			Carp::croak("Unable to connect to LocalFree.");

	$call->Call($pObject) and Carp::croak("Unable to FreeAlloc $pObject.");
	$_[0] = undef; # Undefine the passed $pObject
}
}


=head2 C<LocalSize>

Calls C<LocalSize> on the passed pointer (as Perl int).

=cut

{
my $call;
sub LocalSize {
	my($pObject) = @_;

	$call ||= Win32::API->new('kernel32',
				'LocalSize', [ _uint64 ], _uint64) or
			Carp::croak("Unable to connect to LocalSize.");

	return $call->Call($pObject);
}
}


=head2 C<CopyMemory_Read>

Uses C<RtlMoveMemory> to copy an arbitrary memory location into a Perl string.
Pass pointer as Perl int.  The number of bytes to read from that location is
optional - if not passed, C<LocalSize> will be used to determine the number of
bytes to read.

The function will return the data read in a Perl string.

=cut

{
my $call;
sub CopyMemory_Read {
	my($pSource, $Length) = @_;

	unless( defined $Length ) {
		$Length = LocalSize($pSource);
	}

	my $Destination = "\0" x $Length;

	$call ||= Win32::API->new('kernel32',
				'RtlMoveMemory', [ 'P', _uint64, _uint64 ], 'V') or
			Carp::croak("Unable to connect to RtlMoveMemory.");

	$call->Call($Destination, $pSource, $Length);

	return $Destination;
}
}


=head2 C<CopyMemory_Write>

Uses C<RtlMoveMemory> to write to an arbitrary memory location.  Pass a
string that will be copied and a pointer (as Perl int).  The caller is
responsible for ensuring that the data to be written will not overrun
the memory location.

=cut

{
my $call;
sub CopyMemory_Write {
	my($string, $pDest) = @_;

	$call ||= Win32::API->new('kernel32',
				'RtlMoveMemory', [_uint64, 'P', _uint64], 'V') or
			Carp::croak("Unable to connect to RtlMoveMemory.");

	$call->Call($pDest, $string, length($string));
}
}



=head1 Function Reference: Process functions

=head2 C<GetCurrentProcess>

Returns a handle to the C<CurrentProcess> as an integer.

=cut

{
my $call;
sub GetCurrentProcess {
	$call ||= Win32::API->new('kernel32',
				'GetCurrentProcess', [], _uint64) or
			Carp::croak("Unable to connect to GetCurrentProcess.");

	$call->Call();
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

	my $TokenHandle = pack(_pack_uint64, 0);

	$call ||= Win32::API->new('advapi32',
				'OpenProcessToken', [ _uint64, _uint32, 'P' ], _uint32) or
			Carp::croak("Unable to connect to OpenProcessToken.");

	$call->Call($ProcessHandle, $DesiredAccess, $TokenHandle) or
			Carp::croak(&_format_error('OpenProcessToken'));

	$TokenHandle = unpack(_pack_uint64, $TokenHandle);

	return $TokenHandle;
}
}


=head2 C<LookupPrivilegeValue>

Pass C<SystemName> (undef permitted) and a privilege C<Name> (i.e.
C<SeRestorePrivilege>).  Returns the C<Luid>.

=cut

{
my $call;
sub LookupPrivilegeValue {
	my($SystemName, $Name) = @_;

	defined $SystemName or $SystemName = '';

	my($Luid) = ("\0" x 8);

	$call ||= Win32::API->new('advapi32',
				'LookupPrivilegeValue', [ 'P', 'P', 'P' ], _uint32) or
			Carp::croak("Unable to connect to LookupPrivilegeValue.");

	$call->Call($SystemName, $Name, $Luid) or
			Carp::croak(&_format_error('LookupPrivilegeValue'));

	return $Luid;
}
}


=head2 C<AdjustTokenPrivileges>

Pass the following three parameters:

=over 4

=item * C<TokenHandle> from C<OpenProcessToken>

=item * C<DisableAllPrivileges> 0 or 1

=item * C<NewState> array ref like so: [ [C<Luid> from C<LookupPrivilegeValue>, C<LUID_ATTRIBUTES> mask], .. ]
i.e. C<[ [$luid, 'SE_PRIVILEGE_ENABLED'] ]>

=back

The first return value is array C<PreviousState> that will be similar to the passed C<NewState>.
The second return value is any error messages returned from the call to C<AdjustTokenPrivileges>.

=cut

{
my $call;
sub AdjustTokenPrivileges {
	my($TokenHandle, $DisableAllPrivileges, $NewState) = @_;

	ref($NewState) eq 'ARRAY' or Carp::croak("AdjustTokenPrivileges requires array ref for NewState.");
	scalar(@{$NewState}) >= 1 or Carp::croak("AdjustTokenPrivileges requires at least one element for NewState.");
	my $pNewState = pack(_pack_uint32, scalar(@{$NewState}));
	foreach my $laa (@{$NewState}) {
		ref($laa) eq 'ARRAY' or Carp::croak("AdjustTokenPrivileges requires all elements of NewState to be array refs.");
		scalar(@{$laa}) == 2 or Carp::croak("AdjustTokenPrivileges requires all elements of NewState to be array refs with two elements.");
		length($laa->[0]) == 8 or Carp::croak("AdjustTokenPrivileges requires all LUID values to be 8 bytes.");
		$pNewState .= $laa->[0] . pack(_pack_uint32, &Win32::Security::LUID_ATTRIBUTES->build_mask($laa->[1]));
	}

	my $BufferLength = length($pNewState);
	my $pPreviousState = ("\0" x $BufferLength);
	my $pReturnLength = pack(_pack_uint32, 0);

	$call ||= Win32::API->new('advapi32',
				'AdjustTokenPrivileges', [ _uint64, _uint32, 'P', _uint32, 'P', 'P' ], _uint32) or
			Carp::croak("Unable to connect to AdjustTokenPrivileges.");

	unless ($call->Call($TokenHandle, $DisableAllPrivileges, $pNewState, $BufferLength, $pPreviousState, $pReturnLength)) {
		my $error = Win32::GetLastError();
		Carp::croak(&_format_error('AdjustTokenPrivileges', $error));
	}

	my $error = Win32::GetLastError();
	$error = $error ? &_format_error('AdjustTokenPrivileges', $error) : '';

	my $PreviousCount = unpack(_pack_uint32, $pPreviousState);
	my $PreviousState = [];
	foreach my $i (0..$PreviousCount-1) {
		my $Luid = substr($pPreviousState, $i*12+4, 8);
		my $Attributes = &Win32::Security::LUID_ATTRIBUTES->break_mask(unpack('V', substr($pPreviousState, $i*12+12, 4)));
		push(@{$PreviousState}, [$Luid, $Attributes]);
	}

	return($PreviousState, $error);
}
}



=head1 Function Reference: Security Descriptor functions

=head2 C<GetNamedSecurityInfo>

This expects an object name (i.e. a path to a file, registry key, etc.), an
object type (i.e. C<'SE_FILE_OBJECT'>), and a C<SECURITY_INFORMATION> mask (i.e.
C<'OWNER_SECURITY_INFORMATION|DACL_SECURITY_INFORMATION'>).  It returns pointers
(as Perl ints) to C<sidOwner>, C<sidGroup>, C<Dacl>, C<Sacl>, and the
C<SecurityDescriptor>.  Some of these may be null pointers.

B<IMPORTANT>: When done with the returned data, call
C<Win32::Security::Raw::LocalFree> on the returned C<SecurityDescriptor>;

=cut

{
my $call;
sub GetNamedSecurityInfo {
	my($ObjectName, $ObjectType, $SecurityInfo) = @_;

	$ObjectType = &Win32::Security::SE_OBJECT_TYPE->build_mask($ObjectType);
	$SecurityInfo = &Win32::Security::SECURITY_INFORMATION->build_mask($SecurityInfo);

	my($psidOwner, $psidGroup, $pDacl, $pSacl, $pSecurityDescriptor) =
		( (pack(_pack_uint64, 0)) x 5 );

	$call ||= Win32::API->new('advapi32',
				'GetNamedSecurityInfo', [ 'P', _uint32, _uint32, 'P', 'P', 'P', 'P', 'P' ], _uint32) or
			Carp::croak("Unable to connect to GetNamedSecurityInfo.");

	my $retval = $call->Call($ObjectName, $ObjectType, $SecurityInfo,
			$psidOwner, $psidGroup, $pDacl, $pSacl, $pSecurityDescriptor);

	$retval and Carp::croak(&_format_error('GetNamedSecurityInfo', $retval));

	foreach ($psidOwner, $psidGroup, $pDacl, $pSacl, $pSecurityDescriptor) {
		$_ = unpack(_pack_uint64, $_);
	}

	return($psidOwner, $psidGroup, $pDacl, $pSacl, $pSecurityDescriptor);
}
}


=head2 C<GetSecurityDescriptorControl>

This expects a pointer to a C<SecurityDescriptor>.  It returns the
C<Data::BitMask::break_mask> form for the
C<SECURITY_DESCRIPTOR_CONTROL> mask and the Revision.

=cut

{
my $call;
sub GetSecurityDescriptorControl {
	my($pSecurityDescriptor) = @_;

	my($Control, $Revision) = ( pack('S', 0), pack(_pack_uint32, 0) );

	$call ||= Win32::API->new('advapi32',
				'GetSecurityDescriptorControl', [ _uint64, 'P', 'P' ], _uint32) or
			Carp::croak("Unable to connect to GetSecurityDescriptorControl.");

	$call->Call($pSecurityDescriptor, $Control, $Revision) or
			Carp::croak(&_format_error('GetSecurityDescriptorControl'));

	$Control = &Win32::Security::SECURITY_DESCRIPTOR_CONTROL->break_mask(unpack('S', $Control));
	$Revision = unpack(_pack_uint32, $Revision);

	return($Control, $Revision);
}
}


=head2 C<GetLengthSid>

This accepts a pointer (as a Perl int) to a SID as an integer and returns
the length.

=cut

{
my $call;
sub GetLengthSid {
	my($pSid) = @_;

	$call ||= Win32::API->new('advapi32',
				'GetLengthSid', [ _uint64 ], _uint32) or
			Carp::croak("Unable to connect to GetLengthSid.");

	return $call->Call($pSid);
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
	my($pAcl, $AclInformationClass) = @_;

	my $structures = {
		AclRevisionInformation	=> join('', _uint32),
		AclSizeInformation		=> join('', _uint32, _uint32, _uint32),
	};

	my($AclInformation) = (pack($structures->{$AclInformationClass}));

	$call ||= Win32::API->new('advapi32',
				'GetAclInformation', [ _uint64, 'P', _uint32, _uint32 ], _uint32) or
			Carp::croak("Unable to connect to GetAclInformation.");

	$call->Call($pAcl, $AclInformation, length($AclInformation),
				&Win32::Security::ACL_INFORMATION_CLASS->build_mask($AclInformationClass)) or
			Carp::croak(&_format_error('GetAclInformation'));

	my(@retvals) = unpack($structures->{$AclInformationClass}, $AclInformation);

	return(@retvals);
}
}


=head2 C<SECURITY_DESCRIPTOR_MIN_LENGTH>

Returns the minimum length for a valid SecurityDescriptor.  This is 4 bytes plus
4 times the size of a pointer (i.e. 4 + 4*4 = 20 on x86, 4 + 4*8 = 36 on x64).

=cut

{
my $SECURITY_DESCRIPTOR_MIN_LENGTH;

sub SECURITY_DESCRIPTOR_MIN_LENGTH {
	$SECURITY_DESCRIPTOR_MIN_LENGTH ||=  4 + 4 * ( _is_x64() ? 8 : 4 );
	return $SECURITY_DESCRIPTOR_MIN_LENGTH;
}
}


=head2 C<InitializeSecurityDescriptor>

C<Revision> is optional - if omitted, revision 1 is used.  Dies if the call fails.

The call will allocate a chunk of memory for the new SecurityDescriptor before
initializing it and then return a pointer to it.

B<IMPORTANT>: When done with using the new SecurityDescriptor, call
C<Win32::Security::Raw::LocalFree> on the returned C<SecurityDescriptor>;

=cut

{
my $call;
sub InitializeSecurityDescriptor {
	my($Revision) = @_;

	$Revision = 1 unless defined $Revision;

	my $pSecurityDescriptor = Win32::Security::Raw::LocalAlloc(
			'LPTR', SECURITY_DESCRIPTOR_MIN_LENGTH() );

	$call ||= Win32::API->new('advapi32',
				'InitializeSecurityDescriptor', [ _uint64, _uint32 ], _uint32) or
			Carp::croak("Unable to connect to InitializeSecurityDescriptor.");

	$call->Call($pSecurityDescriptor, $Revision) or
		Carp::croak("Unable to InitializeSecurityDescriptor $pSecurityDescriptor.");

	return $pSecurityDescriptor;
}
}


=head2 C<SetSecurityDescriptorDacl>

Calls C<SetSecurityDescriptorDacl>.  Expects a pointer to a
C<SecurityDescriptor>, bool C<DaclPresent>, pointer to C<Dacl>, and pointer
to C<DaclDefaulted>.  Dies if the call fails.

=cut

{
my $call;
sub SetSecurityDescriptorDacl {
	my($pSecurityDescriptor, $DaclPresent, $pDacl, $DaclDefaulted) = @_;

	$call ||= Win32::API->new('advapi32',
				'SetSecurityDescriptorDacl', [ _uint64, _uint32, _uint64, _uint32 ], _uint32) or
			Carp::croak("Unable to connect to SetSecurityDescriptorDacl.");

	$call->Call($pSecurityDescriptor, $DaclPresent, $pDacl, $DaclDefaulted) or Carp::croak("Unable to SetSecurityDescriptorDacl.");
}
}


=head2 C<SetFileSecurity>

Pass C<FileName>, C<SecurityInfo>, and pointer (as Perl int) to
C<SecurityDescriptor>.  Useful for setting permissions without
propagating inheritable ACEs.

=cut

{
my $call;
my $os2k;
sub SetFileSecurity {
	my($FileName, $SecurityInfo, $pSecurityDescriptor) = @_;

	$SecurityInfo = &Win32::Security::SECURITY_INFORMATION->build_mask($SecurityInfo);

	unless (defined($os2k)) {
		my(@osver) = Win32::GetOSVersion();
		$os2k = ($osver[4] == 2 && $osver[1] >= 5);
	}

	if (!$os2k && scalar(grep(/PROTECTED/, keys %{&Win32::Security::SECURITY_INFORMATION->break_mask($SecurityInfo)})) ) {
		Carp::croak("Use of PROTECTED SECURITY_INFORMATION constant on a non Win2K or greater OS.");
	}

	$call ||= Win32::API->new('advapi32',
				'SetFileSecurity', [ 'P', _uint32, _uint64 ], _uint32) or
			Carp::croak("Unable to connect to SetFileSecurity.");

	$call->Call($FileName, $SecurityInfo, $pSecurityDescriptor) or
			Carp::croak(&_format_error('SetFileSecurity'));
}
}


=head2 C<SetNamedSecurityInfo>

This expects an object name (i.e. a path to a file, registry key, etc.), an
object type (i.e. C<'SE_FILE_OBJECT'>), and a C<SECURITY_INFORMATION> mask (i.e.
C<'OWNER_SECURITY_INFORMATION|DACL_SECURITY_INFORMATION'>), and byte strings for
C<sidOwner>, C<sidGroup>, C<Dacl>, and C<Sacl>.  The byte strings may be C<undef>
if they are not referenced in the C<SECURITY_INFORMATION> mask.

=cut

{
my $call;
my $os2k;
sub SetNamedSecurityInfo {
	my($ObjectName, $ObjectType, $SecurityInfo, $sidOwner, $sidGroup, $Dacl, $Sacl) = @_;

	$ObjectType = &Win32::Security::SE_OBJECT_TYPE->build_mask($ObjectType);
	$SecurityInfo = &Win32::Security::SECURITY_INFORMATION->build_mask($SecurityInfo);

	unless (defined($os2k)) {
		my(@osver) = Win32::GetOSVersion();
		$os2k = ($osver[4] == 2 && $osver[1] >= 5);
	}

	if (!$os2k && scalar(grep(/PROTECTED/, keys %{&Win32::Security::SECURITY_INFORMATION->break_mask($SecurityInfo)})) ) {
		Carp::croak("Use of PROTECTED SECURITY_INFORMATION constant on a non Win2K or greater OS.");
	}

	defined $sidOwner or $sidOwner = '';
	defined $sidGroup or $sidGroup = '';
	defined $Dacl or $Dacl = '';
	defined $Sacl or $Sacl = '';

	$call ||= Win32::API->new('advapi32',
				'SetNamedSecurityInfo', [ 'P', _uint32, _uint32, 'P', 'P', 'P', 'P' ], _uint32) or
			Carp::croak("Unable to connect to SetNamedSecurityInfo.");

	my $retval = $call->Call($ObjectName, $ObjectType, $SecurityInfo, $sidOwner, $sidGroup, $Dacl, $Sacl);
	$retval and Carp::croak(&_format_error('SetNamedSecurityInfo', $retval));
}
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
			SE_PRIVILEGE_REMOVED            => 0x0004,
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
