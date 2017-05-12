package Win32::CryptData;

use 5.006;
use strict;
use Carp;

use Win32;
use Win32::API '0.20';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::IPHelper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'all' => [ qw( CryptProtectData CryptUnprotectData CRYPTPROTECT_PROMPT_ON_UNPROTECT CRYPTPROTECT_PROMPT_ON_PROTECT CRYPTPROTECT_PROMPT_STRONG CRYPTPROTECT_UI_FORBIDDEN CRYPTPROTECT_LOCAL_MACHINE CRYPTPROTECT_AUDIT CRYPTPROTECT_VERIFY_PROTECTION ) ],
	'flags' => [ qw( CRYPTPROTECT_PROMPT_ON_UNPROTECT CRYPTPROTECT_PROMPT_ON_PROTECT CRYPTPROTECT_PROMPT_STRONG CRYPTPROTECT_UI_FORBIDDEN CRYPTPROTECT_LOCAL_MACHINE CRYPTPROTECT_AUDIT CRYPTPROTECT_VERIFY_PROTECTION ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

my $CryptProtectData = new Win32::API ('Crypt32', 'CryptProtectData', ['P', 'P', 'P', 'P', 'P', 'N', 'P'], 'N') or croak 'can\'t find CryptProtectData() function';
my $CryptUnprotectData = new Win32::API ('Crypt32', 'CryptUnprotectData', ['P', 'P', 'P', 'P', 'P', 'N', 'P'], 'N') or croak 'can\'t find CryptUnprotectData() function';
my $LocalFree = new Win32::API ('Kernel32', 'LocalFree', ['N'], 'N') or croak 'can\'t find LocalFree() function';

#############
# Constants #
#############
# $dwPromptFlags
use constant CRYPTPROTECT_PROMPT_ON_UNPROTECT => 0x1;
use constant CRYPTPROTECT_PROMPT_ON_PROTECT   => 0x2;
#use constant CRYPTPROTECT_PROMPT_RESERVED     => 0x4; # reserved, do not use.
use constant CRYPTPROTECT_PROMPT_STRONG       => 0x8;

# $dwFlags
use constant CRYPTPROTECT_UI_FORBIDDEN        => 0x1;
use constant CRYPTPROTECT_LOCAL_MACHINE       => 0x4;
use constant CRYPTPROTECT_AUDIT               => 0x10;
use constant CRYPTPROTECT_VERIFY_PROTECTION   => 0x40;

our $DEBUG = 0;

#################################
# PUBLIC Functions (exportable) #
#################################

#######################################################################
# Win32::CryptData::CryptProtectData()
#
# The CryptProtectData function performs encryption on the data in a
# DATA_BLOB structure. Typically, only a user with the same logon
# credential as the encrypter can decrypt the data. In addition, the
# encryption and decryption usually must be done on the same computer.
#
#######################################################################
# Usage:
#	$ret = CryptProtectData(\$pDataIn, \$szDataDescr, \$pOptionalEntropy, \$pvReserved, \%pPromptStruct, $dwFlags, \$pDataOut);
#
# Output:
#	$ret = 1 for success, undef for failure
#
# Input:
#	\$pDataIn = Pointer to the plaintext string to be encrypted
#	\$szDataDescr  = String with a readable description of the data to be encrypted
#	\$pOptionalEntropy = Pointer to a password or other additional entropy used to encrypt the data
#	\$pvReserved = reserved, must be set to undef
#	\%pPromptStruct = Pointer to a hash that provides information about where and when prompts are to be displayed
#		PromptFlags => one or more of the following values:
#			CRYPTPROTECT_PROMPT_ON_PROTECT = This flag is used to provide the prompt for the protect phase
#			CRYPTPROTECT_PROMPT_ON_UNPROTECT = This flag can be combined with CRYPTPROTECT_PROMPT_ON_PROTECT to enforce the UI (user interface) policy of the caller
#			CRYPTPROTECT_PROMPT_STRONG = This flag forces user to provide an encryption password
#		hwndApp => handle of the parent window if needed modal behaviour
#		Prompt => caption for the prompt
#	$dwFlags = The following flag values are defined:
#		CRYPTPROTECT_LOCAL_MACHINE = When this flag is set, it associates the data encrypted with the current computer instead of with an individual user
#		CRYPTPROTECT_UI_FORBIDDEN = This flag is used for remote situations where presenting a user interface (UI) is not an option
#		CRYPTPROTECT_AUDIT = This flag generates an audit on protect and unprotect operations
#		CRYPTPROTECT_VERIFY_PROTECTION = This flag verifies the protection of a protected string
#
# Output:
#	\$pDataOut = Pointer to the string that receives the encrypted data
#
#######################################################################
# function CryptProtectData
#
#	The CryptProtectData function performs encryption on the data in a DATA_BLOB structure
#
#	BOOL WINAPI CryptProtectData(
#		DATA_BLOB* pDataIn,
#		LPCWSTR szDataDescr,
#		DATA_BLOB* pOptionalEntropy,
#		PVOID pvReserved,
#		CRYPTPROTECT_PROMPTSTRUCT* pPromptStruct,
#		DWORD dwFlags,
#		DATA_BLOB* pDataOut
#	);
#
#######################################################################
sub CryptProtectData
{
	if(scalar(@_) ne 7)
	{
		croak 'Usage: CryptProtectData(\\\$pDataIn, \\\$szDataDescr, \\\$pOptionalEntropy, \\\$pvReserved, \\\%pPromptStruct, \$dwFlags, \\\$pDataOut)';
	}

	my $DataIn = shift;
	my $szDataDescr = _ToUnicodeSz(${shift()});
	my $OptionalEntropy = shift;
	my $pvReserved = pack("L", shift);
	my %PromptStruct = %{ shift() };

	my $dwFlags = shift || 0;

	my $DataOut = shift;

	my $pDataOut = pack("LL", 0x0, 0x0);

	my $pDataIn = pack("LL", length($$DataIn), unpack("L!", pack("P", $$DataIn)));
	my $pOptionalEntropy = pack("LL", length($$OptionalEntropy)+1, unpack("L!", pack("P", $$OptionalEntropy)));
	my $szPrompt = _ToUnicodeSz($PromptStruct{'Prompt'});
	my $pPromptStruct = pack("L4",
							 16,
							 $PromptStruct{'PromptFlags'} || 0,
							 $PromptStruct{'hwndApp'} || 0,
							 unpack("L!", pack("P", $szPrompt))
	);

	if($CryptProtectData->Call($pDataIn, $szDataDescr, $pOptionalEntropy, $pvReserved, $pPromptStruct, $dwFlags, $pDataOut))
	{
		my($len, $ptr) = unpack("LL", $pDataOut);
		$$DataOut = unpack('P'.$len, pack('L!', $ptr));

		$LocalFree->Call($ptr) and warn "Cannot LocalFree() pDataOut buffer: $^E";

		return 1;
	}
}

#######################################################################
# Win32::CryptData::CryptUnprotectData()
#
# The CryptUnprotectData function decrypts and does an integrity check
# of the data in a DATA_BLOB structure. Usually, only a user with the
# same logon credentials as the encrypter can decrypt the data.
#
#######################################################################
# Usage:
#	$ret = CryptUnprotectData(\$pDataIn, \$szDataDescr, \$pOptionalEntropy, \$pvReserved, \%pPromptStruct, $dwFlags, \$pDataOut);
#
# Output:
#	$ret = 1 for success, undef for failure
#
# Input:
#	\$pDataIn = Pointer to the plaintext string to be decrypted
#	\$pOptionalEntropy = Pointer to a password or other additional entropy used to encrypt the data
#	\$pvReserved = reserved, must be set to undef
#	\%pPromptStruct = Pointer to a hash that provides information about where and when prompts are to be displayed
#		PromptFlags => one or more of the following values:
#			CRYPTPROTECT_PROMPT_ON_PROTECT = This flag is used to provide the prompt for the protect phase
#			CRYPTPROTECT_PROMPT_ON_UNPROTECT = This flag can be combined with CRYPTPROTECT_PROMPT_ON_PROTECT to enforce the UI (user interface) policy of the caller
#			CRYPTPROTECT_PROMPT_STRONG = This flag forces user to provide an encryption password
#		hwndApp => handle of the parent window if needed modal behaviour
#		Prompt => caption for the prompt
#	$dwFlags = The following flag values are defined:
#		CRYPTPROTECT_UI_FORBIDDEN = This flag is used for remote situations where presenting a user interface (UI) is not an option
#
# Output:
#	\$szDataDescr  = String with a readable description of the data to be encrypted
#	\$pDataOut = Pointer to the string that receives the encrypted data
#
#######################################################################
# function CryptUnprotectData
#
#	The CryptUnprotectData function decrypts and does an integrity check of the data in a DATA_BLOB structure
#
#	BOOL WINAPI CryptUnprotectData(
#		DATA_BLOB* pDataIn,
#		LPWSTR* ppszDataDescr,
#		DATA_BLOB* pOptionalEntropy,
#		PVOID pvReserved,
#		CRYPTPROTECT_PROMPTSTRUCT* pPromptStruct,
#		DWORD dwFlags,
#		DATA_BLOB* pDataOut
#	);
#
#######################################################################
sub CryptUnprotectData
{
	if(scalar(@_) ne 7)
	{
		croak 'Usage: CryptUnprotectData(\\\$pDataIn, \\\$szDataDescr, \\\$pOptionalEntropy, \\\$pvReserved, \\\$pPromptStruct, \$dwFlags, \\\$pDataOut)';
	}

	my $DataIn = shift;
	my $szDataDescr = shift;
	my $pszDataDescr = pack('L', 0);
	my $OptionalEntropy = shift;
	my $pvReserved = pack('L', shift);
	my %PromptStruct = %{ shift() };

	my $dwFlags = shift || 0;

	my $DataOut = shift;

	my $pDataOut = pack('LL', 0, 0);

	my $pDataIn = pack('LL', length($$DataIn)+1, unpack('L!', pack('P', $$DataIn)));
	my $pOptionalEntropy = pack('LL', length($$OptionalEntropy)+1, unpack('L!', pack('P', $$OptionalEntropy)));
	my $szPrompt = _ToUnicodeSz($PromptStruct{'Prompt'});
	my $pPromptStruct = pack('L4',
							 16,
							 $PromptStruct{'PromptFlags'} || 0,
							 $PromptStruct{'hwndApp'} || 0,
							 unpack('L!', pack('P', $szPrompt))
	);

	if($CryptUnprotectData->Call($pDataIn, $pszDataDescr, $pOptionalEntropy, $pvReserved, $pPromptStruct, $dwFlags, $pDataOut))
	{
		my($len, $ptr) = unpack('LL', $pDataOut);
		$$DataOut = unpack('P'.$len, pack('L!', $ptr));

		$LocalFree->Call($ptr) and warn "Cannot LocalFree() pDataOut buffer: $^E";

		my $i = 0;
		do {
			$i += 2;
			$$szDataDescr = unpack('P'.$i, $pszDataDescr);
		}
		while(substr($$szDataDescr, -2) ne "\0\0");

		$$szDataDescr = _FromUnicode($$szDataDescr);
		$LocalFree->Call(unpack('L', $pszDataDescr)) and warn "Cannot LocalFree() pszDataDescr buffer: $^E";

		return 1;
	}
}

#######################################################################
# WCHAR = _ToUnicodeChar(string)
# converts a perl string in a 16-bit (pseudo) unicode string
#######################################################################
sub _ToUnicodeChar
{
	my $string = shift or return(undef);

	$string =~ s/(.)/$1\x00/sg;

	return $string;
}


#######################################################################
# WSTR = _ToUnicodeSz(string)
# converts a perl string in a null-terminated 16-bit (pseudo) unicode string
#######################################################################
sub _ToUnicodeSz
{
	my $string = shift or return(undef);

	return _ToUnicodeChar($string."\x00");
}


#######################################################################
# string = _FromUnicode(WSTR)
# converts a null-terminated 16-bit unicode string into a regular perl string
#######################################################################
sub _FromUnicode
{
	my $string = shift or return(undef);

	$string = unpack("Z*", pack( "C*", unpack("S*", $string)));

	return($string);
}


1;
__END__

=head1 NAME

Win32::CryptData - Perl wrapper for Win32 CryptProtectData and CryptUnprotectData functions.

=head1 SYNOPSIS

 use Win32::CryptData;

 $ret = Win32::CryptProtect::CryptProtectData();

 $ret = Win32::CryptProtect::CryptUnprotectData();

=head1 DESCRIPTION

Interface to Win32 Crypto API functions and data structures, needed to perform data encryption and decrtyption. Typically, only a user with logon credentials matching those of the encrypter can decrypt the data. In addition, decryption usually can only be done on the computer where the data was encrypted. However, a user with a roaming profile can decrypt the data from another computer on the network.

This module covers a small subset of the functions and data structures provided by the Win32 Crypto API.

B<Purpose>

This documentation provides information about services, components, and tools that enable application developers to add cryptographic security to their applications. This includes CryptoAPI 2.0, Cryptographic Service Providers (CSP), CryptoAPI Tools, CAPICOM, WinTrust, issuing and managing certificates, and developing customizable public-key infrastructures. Certificate and smart card enrollment, certificate management, and custom module development are also described.

B<Developer Audience>

CryptoAPI is intended for use by developers of applications based on the Microsoft® Windows® and Microsoft Windows NT® operating systems that will enable users to create and exchange documents and other data in a secure environment, especially over nonsecure media such as the Internet. Developers should be familiar with the C and C++ programming languages and the Windows programming environment. Although not required, an understanding of cryptography or security-related subjects is advised.

CAPICOM is intended for use by developers who are creating applications using the Microsoft Visual Basic® development system, the Visual Basic Scripting Edition (VBScript) programming language, or the C++ programming language.

B<Run-time Requirements>

The Crypto API is supported on:

=over 4

=item *
Windows Server 2003

=item *
Windows XP

=item *
Windows 2000

=item *
Microsoft Windows 2000

=item *
Microsoft Windows NT, version 4.0, with Service Pack 4 or later

=item *
Windows 98 with Microsoft Internet Explorer 5 or later

=back

B<Note>

CAPICOM 1.0 is supported by the same operating systems, with the addition of Windows 95 with Microsoft Internet Explorer 5 or later.

CAPICOM is available as a redistributable file that can be downloaded from the Platform SDK Redistributables Web site.

=head2 EXPORT

None by default.

=head1 FUNCTIONS

=head2 CryptProtectData(\$DataIn,\$DataDescr,\$OptionalEntropy,\$Reserved,\%PromptStruct,$Flags,\$DataOut)

The CryptProtectData function performs encryption on the data in $DataIn.
Typically, only a user with the same logon credential as the encrypter can decrypt the data.
In addition, the encryption and decryption usually must be done on the same computer.

I<B<Parameters>>

=over 4

=item $DataIn

Reference to a scalar that contains the plaintext to be encrypted.

=item \$DataDescr

Reference to a scalar with a readable description of the data to be encrypted.
This description string is included with the encrypted data.
This parameter is optional and can be set to undef.

=item \$OptionalEntropy

Reference to a scalar that contains a password or other additional entropy used to encrypt the data.
The value used in the encryption phase must also be used in the decryption phase.
This parameter can be set to undef for no additional entropy.

=item \$Reserved

Reserved for future use and must be set to a reference to undef.

=item \%PromptStruct

Reference to a %PromptStruct structure that provides information about where and when prompts
are to be displayed and what the content of those prompts should be.
This parameter can be set to NULL in both the encryption and decryption phases

=item $Flags

This parameter can be one or more of the following flags:

 CRYPTPROTECT_LOCAL_MACHINE
   When this flag is set, it associates the data encrypted with the current computer instead of with an individual user.
   Any user on the computer on which CryptProtectData is called can use CryptUnprotectData to decrypt the data.

 CRYPTPROTECT_UI_FORBIDDEN
   This flag is used for remote situations where presenting a user interface (UI) is not an option.
   When this flag is set and UI is specified for either the protect or unprotect operation, the operation fails.

 CRYPTPROTECT_AUDIT
   This flag generates an audit on protect and unprotect operations.

 CRYPTPROTECT_VERIFY_PROTECTION
   This flag verifies the protection of a protected item.

=item \$DataOut

Reference to a scalar that receives the encrypted data.

=back

B<Example>

  use strict;
  use Win32::CryptData qw(:flags);

  my $DataIn = 'This is plain data';
  my $DataDescr = 'This is the description';
  my $OptionalEntropy = 'mysecret';
  my $Reserved = undef;
  my %PromptStruct = (
    PromptFlags => CRYPTPROTECT_PROMPT_ON_PROTECT | CRYPTPROTECT_PROMPT_ON_UNPROTECT | CRYPTPROTECT_PROMPT_STRONG,
    hwndApp => undef,
    Prompt => 'This is the caption'
  );
  my $Flags = CRYPTPROTECT_AUDIT;
  my $DataOut;

  my $ret = Win32::CryptData::CryptProtectData(\$DataIn, \$DataDescr, \$OptionalEntropy, \$Reserved, \%PromptStruct, $Flags, \$DataOut);

  if($ret)
  {
    print "Encrypted data (hex): " . unpack("H*", $DataOut) . "\n";
  }
  else
  {
    print "Error: $^E\n";
  }

B<Return Values>

If the function succeeds, the return value is 1.

If the function fails, the error code is contained in $^E.

B<Remarks>

Typically, only a user with logon credentials matching those of the encrypter can decrypt the data.
In addition, decryption usually can only be done on the computer where the data was encrypted.
However, a user with a roaming profile can decrypt the data from another computer on the network.

If the CRYPTPROTECT_LOCAL_MACHINE flag is set when the data is encrypted,
any user on the computer where the encryption was done can decrypt the data.

The function creates a session key to perform the encryption.
The session key is re-derived when the data is to be decrypted.

The function also adds a MAC (keyed integrity check) to the encrypted data
to guard against data tampering.

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional.
Server: Included in Windows Server 2003, Windows 2000 Server.
Header: Declared in Wincrypt.h.
Library: Use Crypt32.lib.




=head2 CryptUnprotectData(\$DataIn,\$DataDescr,\$OptionalEntropy,\$Reserved,\%PromptStruct,$Flags,\$DataOut)

The CryptUnprotectData function decrypts and does an integrity check of the data in $DataIn.
Usually, only a user with the same logon credentials as the encrypter can decrypt the data.
In addition, the encryption and decryption must be done on the same computer.

I<B<Parameters>>

=over 4

=item \$DataIn

Reference to a scalar that contains the encrypted data.

=item \$DataDescr

Reference to a scaral that will receive a string-readable description of the encrypted data included with the encrypted data.
This parameter can be set to undef.

=item \$OptionalEntropy

Reference to a scalar that contains a password or other additional entropy used when the data was encrypted.

=item \$Reserved

Reserved for future use and must be set to a reference to undef.

=item \%PromptStruct

Reference to a %PromptStruct structure that provides information about where and when prompts
are to be displayed and what the content of those prompts should be.
This parameter can be set to NULL.

=item $Flags

This parameter can be one or more of the following flags:

 CRYPTPROTECT_UI_FORBIDDEN
   This flag is used for remote situations where the user interface (UI) is not an option.
   When this flag is set and UI is specified for either the protect or unprotect operation, the operation fails.

=item \$DataOut

Reference to a scalar where the function stores the decrypted data.

=back

B<Examples>

  use strict;
  use Win32::CryptData qw(:all);

  my $DataIn = 'This is encrypted data';
  my $DataDescr = undef;
  my $OptionalEntropy = 'mysecret';
  my $Reserved = undef;
  my %PromptStruct = (
    PromptFlags => undef,
    hwndApp => undef,
    Prompt => 'This is the caption'
  );
  my $Flags = undef;
  my $DataOut;

  my $ret = Win32::CryptData::CryptUnprotectData(\$DataIn, \$DataDescr, \$OptionalEntropy, \$Reserved, \%PromptStruct, $Flags, \$DataOut);

  if($ret)
  {
    print "Decrypted data: $DataOut\n";
    print "Description: $DataDescr\n";
  }
  else
  {
    print "Error: $^E\n";
  }

B<Return Values>

If the function succeeds, the return value is 1.

If the function fails, the error code is contained in $^E.

B<Remarks>

The CryptProtectData function creates a session key when the data is encrypted.
That key is re-derived and used to decrypt the data BLOB.

The MAC hash added to the encrypted data can be used to determine whether the encrypted data was altered in any way.
Any tampering results in the return of the ERROR_INVALID_DATA code.

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional.
Server: Included in Windows Server 2003, Windows 2000 Server.
Header: Declared in Wincrypt.h.
Library: Use Crypt32.lib.


=head1 DATA Structures

=head2 %PromptStruct

The %PromptStruct hash defines the behaviour of the prompting dialog box, the valid keys are:

=over 4

=item PromptFlags

any of the valid flags:

  CRYPTPROTECT_PROMPT_ON_PROTECT
    This flag is used to provide the prompt for the protect phase.

  CRYPTPROTECT_PROMPT_ON_UNPROTECT
    This flag can be combined with CRYPTPROTECT_PROMPT_ON_PROTECT to enforce the UI (user interface) policy of the caller.
    When CryptUnprotectData is called, the dwPromptFlags specified in the CryptProtectData call are enforced.

  CRYPTPROTECT_PROMPT_STRONG
    This flag forces user to provide an encryption password

=item hwndApp

Window handle to the parent window

=item Prompt

A string containing the text of a prompt to be displayed

=back

=head1 CREDITS

Thanks to Aldo Calpini for the powerful Win32::API module that makes this thing work.

=head1 AUTHOR

Luigino Masarati, E<lt>lmasarati@hotmail.comE<gt>

=cut

