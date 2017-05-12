package Win32::MprApi;

use 5.006;
use strict;
#use warnings;
use Carp;

use Socket;
use Win32::API;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::MprApi ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'all' => [ qw( MprConfigServerConnect MprConfigServerDisconnect MprConfigGetGuidName MprConfigGetFriendlyName ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

my $MprConfigServerConnect = new Win32::API ('Mprapi', 'MprConfigServerConnect', ['P', 'P'], 'N') or croak 'can\'t find MprConfigServerConnect() function';
my $MprConfigServerDisconnect = new Win32::API ('Mprapi', 'MprConfigServerDisconnect', ['N'], 'N') or croak 'can\'t find MprConfigServerDisconnect() function';
my $MprConfigGetGuidName = new Win32::API ('Mprapi', 'MprConfigGetGuidName', ['N', 'P', 'P', 'N'], 'N') or croak 'can\'t find MprConfigGetGuidName() function';
my $MprConfigGetFriendlyName = new Win32::API ('Mprapi', 'MprConfigGetFriendlyName', ['N', 'P', 'P', 'N'], 'N') or croak 'can\'t find MprConfigGetFriendlyName() function';

# Preloaded methods go here.

use enum qw(
	NO_ERROR=0
	:MAX_INTERFACE_
		NAME_LENGTH=128
	:MAX_ADAPTER_
		ADDRESS_LENGTH=8
		DESCRIPTION_LENGTH=128
		NAME=128
		NAME_LENGTH=256
	:ERROR_
		SUCCESS=0
		NOT_SUPPORTED=50
		INVALID_PARAMETER=87
		BUFFER_OVERFLOW=111
		INSUFFICIENT_BUFFER=122
		NO_DATA=232
);

our $DEBUG = 0;

#################################
# PUBLIC Functions (exportable) #
#################################

#######################################################################
# Win32::MprApi::MprConfigServerConnect()
#
# The MprConfigServerConnect function connects to the Windows 2000
# router to be configured. Call this function before making any other
# calls to the server. The handle returned by this function is used in
# subsequent calls to configure interfaces and transports on the server.
#
#######################################################################
# Prototype
#
#	DWORD MprConfigServerConnect(
#		LPWSTR lpwsServerName,
#		HANDLE* phMprConfig
#	);
#
# Parameters
#	lpwsServerName 
#		[in] Pointer to a Unicode string that specifies the name of the
#			remote server to configure. If this parameter is NULL, the
#			function returns a handle to the router configuration on the local machine . 
#	phMprConfig 
#		[out] Pointer to a handle variable. This variable receives a
#			handle to the router configuration. 
#
# Return Values
#	If the function succeeds, the return value is NO_ERROR.
#	If the function fails, the return value is one of the following error codes.
#
# Value Meaning 
#	ERROR_INVALID_PARAMETER  The phMprConfig parameter is NULL. 
#	ERROR_NOT_ENOUGH_MEMORY  Insufficient resources to complete the operation. 
#	Other                    Use FormatMessage to retrieve the system error message that
#	                         corresponds to the error code returned. 
#
# Usage:
#	$ret = MprConfigServerConnect(\$ServerName, \$hMprConfig);
#
#######################################################################
sub MprConfigServerConnect
{
	if(scalar(@_) ne 2)
	{
		croak 'Usage: MprConfigServerConnect(\\\$ServerName, \\\$hMprConfig)';
	}

	my $lpwsServerName = shift;
	my $phMprConfig = shift;
	
#	$MprConfigServerConnect = new Win32::API ('Mprapi', 'MprConfigServerConnect', ['P', 'P'], 'N') or croak 'can\'t find MprConfigServerConnect() function';
	
	# prepare buffer
	$$phMprConfig = pack("L", 0);

	# function call
	my $ret = $MprConfigServerConnect->Call(_ToUnicodeSz($$lpwsServerName), $$phMprConfig);
	
	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "MprConfigServerConnect() %s\n", Win32::FormatMessage($ret);
	}
	
	# unpack handle for later uses...
	$$phMprConfig = unpack('L', $$phMprConfig);
	
	return $ret;
}


#######################################################################
# Win32::MprApi::MprConfigServerDisconnect()
#
# The MprConfigServerDisconnect function disconnects a connection made
# by a previous call to MprConfigServerConnect.
#
#######################################################################
# Usage:
#	$ret = MprConfigServerDisconnect($hMprConfig);
#
# Parameters:
#	hMprConfig 
#		[in] Handle to a router configuration obtained from a previous call to MprConfigServerConnect. 
#
#######################################################################
# function MprConfigServerDisconnect
#
# The MprConfigServerDisconnect function disconnects a connection made
# by a previous call to MprConfigServerConnect.
#
#
#	void MprConfigServerDisconnect(
#		HANDLE hMprConfig
#	);
#
#
#######################################################################
sub MprConfigServerDisconnect
{
	if(scalar(@_) ne 1)
	{
		croak 'Usage: MprConfigServerDisconnect(\$hMprConfig)';
	}

	my $hMprConfig = shift;
	
#	$MprConfigServerDisconnect = new Win32::API ('Mprapi', 'MprConfigServerDisconnect', ['N'], 'N') or croak 'can\'t find MprConfigServerDisconnect() function';
	
	# function call
	$MprConfigServerDisconnect->Call($hMprConfig);
	
	return undef;
}


#######################################################################
# Win32::MprApi::MprConfigGetGuidName()
#
# The MprConfigGetGuidName function returns the GUID name for an
# interface that corresponds to the specified friendly name.
#
#######################################################################
# Usage:
#	$ret = MprConfigGetGuidName($hMprConfig, \$FriendlyName, \$GUIDName [, $dwBufferSize]);
#
# Output:
#	$ret = 0 for success, a number for error
#
# Parameters:
#
# $hMprConfig 
#	[in] Handle to the router configuration. Obtain this handle by calling MprConfigServerConnect. 
# $pszFriendlyName 
#	[in] Pointer to a Unicode string that specifies the friendly name for the interface. 
# $pszBuffer 
#	[out] Pointer to a buffer that receives the GUID name for the interface. 
# $dwBufferSize 
#	[in] Specifies the size, in bytes, of the buffer pointed to by pszBuffer.
#
#######################################################################
#
#	DWORD MprConfigGetGuidName(
#		HANDLE hMprConfig,
#		PWCHAR pszFriendlyName,
#		PWCHAR pszBuffer,
#		DWORD dwBufferSize
#	);
#
#######################################################################
sub MprConfigGetGuidName
{
	if((scalar(@_) ne 3) and (scalar(@_) ne 4))
	{
		croak 'Usage: MprConfigGetGuidName(\$hMprConfig, \\\$FriendlyName, \\\$GUIDName [, \$dwBufferSize])';
	}

	my $phMprConfig = shift;
	my $szFriendlyName = shift;
	my $pszBuffer = shift;
	my $dwBufferSize = shift || 256;
	
#	$MprConfigGetGuidName = new Win32::API ('Mprapi', 'MprConfigGetGuidName', ['N', 'P', 'P', 'N'], 'N') or croak 'can\'t find MprConfigGetGuidName() function';
	
	# prepare buffer
	$$pszBuffer = "\x00" x $dwBufferSize;

	# function call
	my $ret = $MprConfigGetGuidName->Call($phMprConfig, _ToUnicodeSz($$szFriendlyName), $$pszBuffer, $dwBufferSize);
	
	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "MprConfigGetGuidName() %s\n", Win32::FormatMessage($ret);
	}
	
	# translate resulting guid name from wide char
	$$pszBuffer = _FromUnicode($$pszBuffer);
	
	return $ret;
}


#######################################################################
# Win32::MprApi::MprConfigGetFriendlyName()
#
# The MprConfigGetFriendlyName function returns the friendly name for
# an interface that corresponds to the specified GUID name.
#
#######################################################################
# Usage:
#	$ret = MprConfigGetFriendlyName($hMprConfig, \$GUIDName, \$FriendlyName [, $BufferSize]);
#
# Output:
#	$ret = 0 for success, a number for error
#
# Parameters:
#
# $hMprConfig 
#	[in] Handle to the router configuration. Obtain this handle by calling MprConfigServerConnect. 
# $pszGuidName 
#	[in] Pointer to a null-terminated Unicode string that specifies the GUID name for the interface. 
# $pszBuffer 
#	[out] Pointer to a buffer that receives the friendly name for the interface. 
# $dwBufferSize 
#	[in] Specifies the size, in bytes, of the buffer pointed to by pszBuffer.
#
#######################################################################
#
#	DWORD MprConfigGetFriendlyName(
#		HANDLE hMprConfig,
#		PWCHAR pszFriendlyName,
#		PWCHAR pszBuffer,
#		DWORD dwBufferSize
#	);
#
#######################################################################
sub MprConfigGetFriendlyName
{
	if((scalar(@_) ne 3) and (scalar(@_) ne 4))
	{
		croak 'Usage: MprConfigGetFriendlyName(\$hMprConfig, \\\$GUIDName, \\\$FriendlyName [, \$BufferSize])';
	}

	my $phMprConfig = shift;
	my $szGuidName = shift;
	my $pszBuffer = shift;
	my $dwBufferSize = shift || 256;
	
#	$MprConfigGetFriendlyName = new Win32::API ('Mprapi', 'MprConfigGetFriendlyName', ['N', 'P', 'P', 'N'], 'N') or croak 'can\'t find MprConfigGetFriendlyName() function';
	
	# prepare buffer
	$$pszBuffer = "\x00" x $dwBufferSize;

	# function call
	my $ret = $MprConfigGetFriendlyName->Call($phMprConfig, _ToUnicodeSz($$szGuidName), $$pszBuffer, $dwBufferSize);
	
	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "MprConfigGetFriendlyName() %s\n", Win32::FormatMessage($ret);
	}
	
	# translate resulting friendly name from wide char
	$$pszBuffer = _FromUnicode($$pszBuffer);

	return $ret;
}


######################################
# PRIVATE Functions (not exportable) #
######################################

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
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::MprApi - Perl wrapper for Win32 Router Configuration functions.

=head1 SYNOPSIS

 use Win32::MprApi;

 $ret = Win32::MprApi::MprConfigServerConnect(\$ServerName, \$hMprConfig);

 $ret = Win32::MprApi::MprConfigGetGuidName($hMprConfig, \$FriendlyName, \$GUIDName);

 $ret = Win32::MprApi::MprConfigGetFriendlyName($hMprConfig, \$GUIDName, \$FriendlyName);

 $ret = Win32::MprApi::MprConfigServerDisconnect($hMprConfig);

=head1 DESCRIPTION

Interface to Win32 IP Router Configuration useful functions, needed to translate a Friendly Name (like I<"Local Area Connection")> into a GUID (like I<"{88CE272F-847A-40CF-BFBA-001D9AD97450}">) and vice-versa.

This module covers only a small subset of the functions and data structures provided by the Win32 Router Configuration API.

The API is supported on platforms where MprApi.dll is available:

=over 4

=item *
Microsoft Windows 2000

=item *
Microsoft Windows XP

=item *
Microsoft Windows .NET Server 2003 family

=back

The complete SDK Reference documentation is available online through Microsoft MSDN Library (http://msdn.microsoft.com/library/default.asp)

=head2 EXPORT

None by default.

=head1 FUNCTIONS

=head2 MprConfigServerConnect(\$ServerName, \$hMprConfig)

The MprConfigServerConnect function connects to the Windows 2000 router to be configured.
Call this function before making any other calls to the server.
The handle returned by this function is used in subsequent calls to configure interfaces and transports on the server.

B<Example>

  use Win32::MprApi;

  my $ServerName; # if no name is defined, local server is used instead
  my $hMprConfig; # receives the handle to connected server

  # Connect to the server router
  $ret = Win32::MprApi::MprConfigServerConnect(\$ServerName, \$hMprConfig);

  if($ret == 0)
  {
    printf "MprConfigServerConnect() Server connected successfuly, handle is %u\n", $hMprConfig;

    # Disconnect from the server router
    Win32::MprApi::MprConfigServerDisconnect($hMprConfig);
  }
  else
  {
    printf "MprConfigServerConnect() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Mprapi.h.
Library: Use Mprapi.dll.

=head2 MprConfigGetGuidName($hMprConfig, \$FriendlyName, \$GUIDName)

The MprConfigGetGuidName function returns the GUID name for an interface that corresponds to the specified friendly name.

B<Example>

  use Win32::MprApi;

  my $ServerName; # if no name is defined, local server is used instead
  my $hMprConfig; # receives the handle to connected server
  my $FriendlyName = 'Local Area Connection';
  my $GUIDName; # buffer for the translated GUID Name

  # Connect to the server router
  $ret = Win32::MprApi::MprConfigServerConnect(\$ServerName, \$hMprConfig);

  if($ret == 0)
  {
    $ret = Win32::MprApi::MprConfigGetGuidName($hMprConfig, \$FriendlyName, \$GUIDName);

      if($ret == 0)
      {
        printf "The GUID Name for connection %s is: %s\n", $FriendlyName, $GUIDName;
      }
      else
      {
        printf "MprConfigGetGuidName() error %u: %s\n", $ret, Win32::FormatMessage($ret);
      }

      # Disconnect from the server router
      Win32::MprApi::MprConfigServerDisconnect($hMprConfig);
  }
  else
  {
    printf "MprConfigServerConnect() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Mprapi.h.
Library: Use Mprapi.dll.

=head2 MprConfigGetFriendlyName($hMprConfig, \$GUIDName, \$FriendlyName)

The MprConfigGetFriendlyName function returns the Friendly Name for an interface that corresponds to the specified GUID name.

B<Example>

  use Win32::MprApi;

  my $ServerName; # if no name is defined, local server is used instead
  my $hMprConfig; # receives the handle to connected server
  my $GUIDName = '{88CE272F-847A-40CF-BFBA-001D9AD97450}';
  my $FriendlyName; # buffer for the translated Friendly Name

  # Connect to the server router
  $ret = Win32::MprApi::MprConfigServerConnect(\$ServerName, \$hMprConfig);

  if($ret == 0)
  {
    $ret = Win32::MprApi::MprConfigGetFriendlyName($hMprConfig, \$GUIDName, \$FriendlyName);

      if($ret == 0)
      {
        printf "The Friendly Name for GUID %s is: %s\n", $GUIDName, $FriendlyName;
      }
      else
      {
        printf "MprConfigGetFriendlyName() error %u: %s\n", $ret, Win32::FormatMessage($ret);
      }

      # Disconnect from the server router
      Win32::MprApi::MprConfigServerDisconnect($hMprConfig);
  }
  else
  {
    printf "MprConfigServerConnect() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Mprapi.h.
Library: Use Mprapi.dll.

=head2 MprConfigServerDisconnect( $hMprConfig )

The MprConfigServerDisconnect function disconnects a connection made by a previous call to MprConfigServerConnect.

B<Example>

I<See previous examples>

B<Return Values>

This function has no return values. 

B<Requirements>

Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Mprapi.h.
Library: Use Mprapi.dll.

=head1 CREDITS 

Thanks to Aldo Calpini for the powerful Win32::API module that makes this thing work.

=head1 AUTHOR

Luigino Masarati, E<lt>lmasarati@hotmail.comE<gt>

=cut

