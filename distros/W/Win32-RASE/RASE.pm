# Manipulating RAS/DUN-Entry Properties, outbound dialing
# Mike Blazer <blazer@mail.nevalink.ru>

package Win32::RASE;

use vars qw($VERSION $LOCAL_ID $LOCAL_CODE $LOCAL_AREA $WINVER
 @ISA @EXPORT %RASCS $Time_HiRes_loaded $LastError $IsWindow
 $RasDial $RasEnumConnections $RasHangUp $RasRenameEntry $RasDeleteEntry
 $RasEnumEntries $RasEnumDevices $RasGetConnectStatus $RasGetEntryProperties
 $RasSetEntryProperties $RasDialDlg $RasGetEntryDialParams $RasSetEntryDialParams
 $RasGetCountryInfo $RasCreateEntry $RasEditEntry
 $RasGetErrorString $lineGetTranslateCaps $RasGetProjectionInfo
 %TAPIEnumeration @RASCS_vars @RASEO_vars $PHONEBOOK
 $lineInitialize $lineShutdown $lineSetCurrentLocation
 %RasDevEnumeration
);

require 5.000;
require Win32::API;
use strict "vars";
use Carp;
use enum 1.014;

require Exporter;
@ISA= qw( Exporter );

@RASCS_vars = qw(
    RASCS_OpenPort
    RASCS_PortOpened
    RASCS_ConnectDevice
    RASCS_DeviceConnected
    RASCS_AllDevicesConnected
    RASCS_Authenticate
    RASCS_AuthNotify
    RASCS_AuthRetry
    RASCS_AuthCallback
    RASCS_AuthChangePassword
    RASCS_AuthProject
    RASCS_AuthLinkSpeed
    RASCS_AuthAck
    RASCS_ReAuthenticate
    RASCS_Authenticated
    RASCS_PrepareForCallback
    RASCS_WaitForModemReset
    RASCS_WaitForCallback
    RASCS_Projected
    RASCS_StartAuthentication
    RASCS_CallbackComplete
    RASCS_LogonNetwork
    RASCS_SubEntryConnected
    RASCS_SubEntryDisconnected
    RASCS_Interactive
    RASCS_PAUSED
    RASCS_RetryAuthentication
    RASCS_CallbackSetByCaller
    RASCS_PasswordExpired
    RASCS_Connected
    RASCS_DONE
    RASCS_Disconnected
);

use enum qw(
   :RASCS_=0
    OpenPort
    PortOpened
    ConnectDevice
    DeviceConnected
    AllDevicesConnected
    Authenticate
    AuthNotify
    AuthRetry
    AuthCallback
    AuthChangePassword
    AuthProject
    AuthLinkSpeed
    AuthAck
    ReAuthenticate
    Authenticated
    PrepareForCallback
    WaitForModemReset
    WaitForCallback
    Projected
    StartAuthentication
    CallbackComplete
    LogonNetwork
    SubEntryConnected
    SubEntryDisconnected
    Interactive=4096
    PAUSED=4096
    RetryAuthentication
    CallbackSetByCaller
    PasswordExpired
    Connected=8192
    DONE=8192
    Disconnected
);

# %RASCS to provide short text explaining numeric value
for my $v(@RASCS_vars) {
   next if $v =~ /(PAUSED|DONE)$/;

   ($RASCS{eval $v} = $v) =~ s/^RASCS_//;
}


use enum @RASEO_vars = qw(
  BITMASK:
  RASEO_UseCountryAndAreaCodes
  RASEO_SpecificIpAddr
  RASEO_SpecificNameServers
  RASEO_IpHeaderCompression
  RASEO_RemoteDefaultGateway
  RASEO_DisableLcpExtensions
  RASEO_TerminalBeforeDial
  RASEO_TerminalAfterDial
  RASEO_ModemLights
  RASEO_SwCompression
  RASEO_RequireEncryptedPw
  RASEO_RequireMsEncryptedPw
  RASEO_RequireDataEncryption
  RASEO_NetworkLogon
  RASEO_UseLogonCredentials
  RASEO_PromoteAlternates
  RASEO_SecureLocalFiles
);
shift @RASEO_vars;

use enum qw(
  MAX_PATH=260
 :RAS_
  MaxDeviceType=16
  MaxPhoneNumber=128
  MaxIpAddress=15
  MaxIpxAddress=21
);

BEGIN {
# build number might have problems with some older NTs
# <ras.h> says:

# WINVER values in this file:
#      WINVER < 0x400 = Windows NT 3.5, Windows NT 3.51
#      WINVER = 0x400 = Windows 95, Windows NT SUR (default)
# i.e. 4.0 Shell Update Release
#      WINVER > 0x400 = Windows NT SUR enhancements (nobody knows what's this)
 $WINVER = (Win32::GetOSVersion)[3];
 $WINVER &= 0xFFFF if Win32::IsWin95;
}

use enum $WINVER >= 0x400 ?
 qw(  :RAS_
       MaxEntryName=256
       MaxDeviceName=128
       MaxCallbackNumber=128
 ) :
 qw(  :RAS_
       MaxEntryName=20
       MaxDeviceName=32
       MaxCallbackNumber=48
);

use enum qw(
 :RAS_
  MaxAreaCode=10
  MaxPadType=32
  MaxX25Address=200
  MaxFacilities=200
  MaxUserData=200
);

# RASENTRY 'dwProtocols' bit flags.
use enum qw( BITMASK:RASNP_ NetBEUI Ipx Ip);

# RASENTRY 'dwFramingProtocols' bit flags.
use enum qw( BITMASK:RASFP_ Ppp Slip Ras);

# RASENTRY 'szDeviceType' default strings.
use enum qw( :RASDT_ Modem=modem Isdn=isdn X25=x25);

# from lmcons.h
use enum qw(
  UNLEN=256
  PWLEN=256
  DNLEN=15
  PST_MODEM=6
);


# SpeakerVolume for MODEMSETTINGS
use enum qw( :MDMVOL_=0 LOW MEDIUM HIGH );

# SpeakerMode for MODEMSETTINGS
use enum qw( :MDMSPKR_=0 OFF DIAL ON CALLSETUP);

# Modem Options
use enum qw( BITMASK:MDM_ COMPRESSION ERROR_CONTROL FORCED_EC
 CELLULAR FLOWCONTROL_HARD FLOWCONTROL_SOFT CCITT_OVERRIDE
 SPEED_ADJUST TONE_DIAL BLIND_DIAL V23_OVERRIDE
);

use enum qw(
    RASP_Amb=0x10000
    RASP_PppNbf=0x803F
    RASP_PppIpx=0x802B
    RASP_PppIp=0x8021
    RASP_PppLcp=0xC021
    RASP_Slip=0x20000
);

use enum qw(
 BITMASK:
  TERMINAL_PRE
  TERMINAL_POST
  MANUAL_DIAL
  LAUNCH_LIGHTS
);


@EXPORT = (qw(
 RasEnumConnections RasHangUp HangUp
 RasGetConnectStatus RasDial RasDialDlg
 RasGetProjectionInfo

 TAPICountryName TAPICountryCode IsCountryID
 TAPISetCurrentLocation

 RasCreateEntryDlg RasEditEntryDlg RasEnumDevices
 RasRenameEntry RasDeleteEntry RasEnumEntries IsEntry
 RasGetEntryDialParams RasSetEntryDialParams RasGetUserPwd
 RasGetEntryProperties RasSetEntryProperties
 RasPrintEntryProperties RasChangePhoneNumber RasCopyEntry
 RasCreateEntry RasEnumDevicesByType

 RasGetEntryDevProperties RasPrintEntryDevProperties
), @RASCS_vars, @RASEO_vars);

$VERSION = "1.01";

use constant DWORD_NULL => pack("L",0);

sub CRUNCH (@) {
 local $_;
 for (@_) { s/\0.*$//s }
}

sub TRIM_LR ($) {
 $_[0] =~ s/^ *(.*?) *$/$1/s;
}

sub DWORD_ALIGN ($) {
  $_[0] = $_[0] + 4 - $_[0] % 4 if $_[0] % 4;
}

# for precise loops
BEGIN{
  eval "require Time::HiRes";
  unless ($@) {
    import Time::HiRes qw(sleep time);
    $Time_HiRes_loaded = 1;
  }
  undef $@;
}



TAPIlineGetTranslateCaps();


sub new (@) {
   my ($ret, $dll);
   ($dll = $_[0])=~ s/(\.dll)?$/.dll/i;
   $ret = new Win32::API(@_) or croak "Win32::RASE: $_[1] not found in $dll\n";
}

sub RASERROR ($) {
  my $ret = shift;
  my $sub = (caller(1))[3];

  croak "$sub: ".FormatMessage($ret)."\n";
}

sub RASCROAK ($) {
  my $sub = (caller(1))[3];

  croak "$sub: ".shift()."\n";
}

=head1 NAME

Win32::RASE - managing dialup entries and network connections on Win32

=head1 SYNOPSIS

  use Win32::RASE;


=head1 ABSTRACT

This module implements the client part of Win32 RAS API.

It is named RASE(RAS-entry) because it was originally designed
to create/delete/change/manage RAS/DUN entries. Now it implements
synchronous dialing, hang up and the wide range of RAS/DUN
entry manipulations.

The current version of Win32::RASE is available at:

  http://www.dux.ru/guest/fno/perl/

=head1 DESCRIPTION

This module is a collection of subroutines. As their names are very long
and specific and almost each corresponds to a Win32 API call I decided
to export a lot of them by default. Everything is exported except those
subs that are claimed as non-exported.

OK, you can C<require> it instead of C<use>.

B<!!! IMPORTANT !!!>
All functions (if the other behavior is not stated explicitly)
return TRUE on success, FALSE on error
to conform the handy calling rule

   RESULT = function(PARAMS) or die MESSAGE;

where RESULT could be scalar or list either. Note that "||" is not
the same thing as "or".

The following logic is used: almost all functions croak on obvious programmer's
errors like invalid entry-name or such.
But they return FALSE and set LastError on internal API errors.
It is made to give the programmer a chance to complete all actions and may be
to trap some errors without exiting the program.

For example if some phonebook file is corrupted you have a chance
to try another one etc.

=over 4


The following two functions are available after any other function was executed.
They are both non-exported to provide feel and look of Win32-Perl built-in
functions with the same names.

=item GetLastError ( )

Returns 0 or the last encountered RAS, TAPI or Windows error number.

  $lastErr = Win32::RASE::GetLastError();

Usually you should call this function after some other function
returned C<undef>. In case of Windows error it returns the same value as
C<Win32::GetLastError>. Unlike the built-in one it always returns 0
if the last called function finished successfully.

You can use it for example like this:

  some_function();
  Win32::RASE::GetLastError and die Win32::RASE::FormatMessage;

or implicitly

  some_function() or die Win32::RASE::FormatMessage;

=cut

#================
sub GetLastError () {
#================
   $LastError||0;
}

=item FormatMessage ( )

Converts the supplied RAS, TAPI or Win32 error number (e.g.
returned by C<Win32::RASE::GetLastError()>) to a descriptive string.

  $message = Win32::RASE::FormatMessage($err_num);

Without the parameter assumes that the result of
C<Win32::RASE::GetLastError()> was sent.

=cut

#================
sub FormatMessage (;$) {
#================
  my ($errnum, $buf) = (shift || GetLastError(), "\0"x1024);

  $errnum =~ /^\-?\d+$/ or
	RASCROAK "non-numeric value `$errnum'";

  if ($errnum >= 600 && $errnum <= 750) {
     $RasGetErrorString ||= new("rasapi32", "RasGetErrorString", [I,P,N], N);

     my $ret = $RasGetErrorString->Call($errnum, $buf, length $buf);
	$ret and RASERROR($ret);

     CRUNCH($buf);
     return "($errnum) $buf";

  } elsif ($errnum == 751) {
     return "(751) ERROR_INVALID_CALLBACK_NUMBER";
  } elsif ($errnum == 752) {
     return "(752) ERROR_SCRIPT_SYNTAX";

# TAPI LINEERR_* constants
  } elsif ($errnum & 0x80000000) {
     return "TAPI-error 0x".(sprintf "%8.8X",$errnum);

# TAPI PHONEERR_* constants
  } elsif ($errnum & 0x90000000) {
     return "TAPI-error 0x".(sprintf "%8.8X",$errnum);

# TAPI TAPIERR_* constants
  } elsif ($errnum > 0xFFFF0000) {
     return "TAPI-error 0x".(sprintf "%8.8X",$errnum);
  }

  "($errnum) ".Win32::FormatMessage($errnum);
}


=item IsWindow ( )

This function is non-exported for not to corrupt some other GUI related
synonym.

  Win32::RASE::IsWindow( $hwnd );

Returns TRUE if $hwnd identifies an existing window, otherwise FALSE.

This function is handy to use before the functions that display a dialog box -
to verify the parent window.

=cut

#================
sub IsWindow ($) {
#================
   my $hwnd = shift;

   # to free dll right after the call (Dlg-functions are rare)
   my $IsWindow = new("user32", "IsWindow", [N], N);
   $IsWindow->Call($hwnd);
}

=pod

=back

B< =====================================>

B< PHONEBOOK RELATED FUNCTIONS>

B< =====================================>

Note that by default all functions in this section work
with the default phonebook (on Windows NT).

The registry key C<"HKEY_CURRENT_USER\Software\Microsoft\RAS Phonebook">
has a dword subkey "PhonebookMode" which could have 3 values:

 0 - the "system" phonebook is in use.
     This is probably %SYSTEMROOT%\system32\ras\rasphone.pbk
 1 - the "user" phonebook is in use.
     This one is located in  %SYSTEMROOT%\system32\ras\<filename>
     <filename> here is the value of "PersonalPhonebookFile" subkey
     that is located under the same key.
 2 - the "alternate" phonebook is in use.
     The full path to the alternate phonebook could be found in the
     "AlternatePhonebookPath" subkey under the same key.

This version of C<Win32::RASE> provides no way to change these registry
settings. If C<"HKEY_CURRENT_USER\Software\Microsoft\RAS Phonebook\PhonebookMode">
is equal to 0 C<Win32::RASE> will use the "system" phonebook, in case 1 -
the "user" phonebook, in case 2 - the "alternate" phonebook.

The user can use the main Dial-Up Networking dialog box to create personal
phonebook files or change defaults (registry settings). The Win32 API does
not currently provide support for creating a phonebook file.

B<IMPORTANT:>

At any time you can set a global variable B<$Win32::RASE::PHONEBOOK> to the full path
of your phonebook file, and this phonebook will be in use until
B<$Win32::RASE::PHONEBOOK> is changed. Setting this variable to 0 or C<undef>
returns us to registry defined phonebook(s).

B<Windows 95/98:> Dial-up networking stores phonebook entries in the registry
rather than in a phonebook file. Windows 9x does not support personal
phonebook files. So B<$Win32::RASE::PHONEBOOK> has no meaning and must
always be C<undef>.

All functions treat entry-names as case-sensitive because RAS functions
are kinda semi-case-sensitive. Some of them fail when entry was given
with case-changes. But at the same time C<RasSetEntryProperties> API call
(in C<RasCopyEntry()>) fails to create both QWERTY and QwErTy, it renames
instead. Ou-h-h MS, MS...

The moral is: don't use names that differ only in upper/lower case.

There also is a danger in using multiple processes that are calling
RAS APIs that update the phonebook. Microsoft reported this problem
has been corrected in Service Pack 3.

http://support.microsoft.com/support/ntserver/serviceware/nts40/E9MSKWBJI.ASP

B<A note on multilink functionality>: there are no ways to use Multilink
programmatically on Win95/98. So, the current version of the module does not
support it for WinNT also. For more info read:

http://support.microsoft.com/support/kb/articles/q198/7/77.asp

Entry names for Windows CE cannot exceed 20 characters.
http://msdn.microsoft.com/library/wincesdk/wcecomm/ras_24.htm

A similiar problem is reported for the InternetMail Service (IMS) on
MS BackOffice Small Business Server version 4.5 and Windows NT Server version 4.0
http://support.microsoft.com/support/kb/articles/Q217/9/37.asp

So, the entries with long names may be unusable by the other applications.

=over 4

=item RasCreateEntryDlg ( )

This function displays a dialog box in which the user types information
about the phonebook entry.

 RasCreateEntryDlg( [$hwnd] );

 $hwnd  - handle to the parent window of the dialog box. Optional.
          If you are using Win32::GUI this would be $Window->{handle}

As this is a synchronous operation and waits for user input it provides no
way to find out whether the new entry was created or not. You should use
C<RasEnumEntries()> to understand what has happened.

Here and everywhere in the functions that display a dialog box - if C<$hwnd>
is omitted or does not identify an existing window a dialog box is centered
on the screen.

=cut

#================
sub RasCreateEntryDlg (;$) {
#================
   my $hwnd = shift;
   $LastError = 0;

   $hwnd = 0 if $hwnd && !IsWindow($hwnd);

   $RasCreateEntry ||= new("rasapi32", "RasCreatePhonebookEntry", [N,P], N);

   my $ret = $RasCreateEntry->Call($hwnd||0, $PHONEBOOK||0);

   $ret and ($LastError = $ret, return);
   1;
}

=item RasEditEntryDlg ( )

This function displays a dialog box in which the user types information
about the phonebook entry. For a programmatical way to edit an existing
entry take a look at C<RasSetEntryProperties()>.

 RasEditEntryDlg( $entry [, $hwnd] );

 $entry - existing phonebook entry to edit.

 $hwnd  - handle to the parent window of the dialog box. Optional.
          If you are using Win32::GUI this would be $Window->{handle}

This is a synchronous operation and waits for user input.

Croaks if C<$entry> does not exist.
You should call C<IsEntry()> before to verify C<$entry>.

=cut

#================
sub RasEditEntryDlg ($;$) {
#================
   my ($entry, $hwnd) = @_;
   $LastError = 0;

   $hwnd = 0 if $hwnd && !IsWindow($hwnd);

   IsEntry($entry) or RASCROAK "`$entry' entry not found";

   $RasEditEntry ||= new("rasapi32", "RasEditPhonebookEntry", [N,P,P], N);

   my $ret = $RasEditEntry->Call($hwnd||0, $PHONEBOOK||0, $entry);

   $ret and ($LastError = $ret, return);
   1;
}

=item RasRenameEntry ( )

 RasRenameEntry( $oldname, $newname );

Croaks if C<$oldname> does not exist or C<$newname> already exists.
You should call C<IsEntry()> or C<RasEnumEntries()> before to verify both.

=cut

#================
sub RasRenameEntry ($$) {
#================
   my ($old, $new) = @_;
   $LastError = 0;

   IsEntry($old)  or RASCROAK "`$old' entry not found";
   IsEntry($new) and RASCROAK "`$new' entry already exists";

   $RasRenameEntry ||= new("rasapi32", "RasRenameEntry", [P,P,P], N);

   my $ret = $RasRenameEntry->Call($PHONEBOOK||0, $old, $new);

   $ret and ($LastError = $ret, return);
   1;
}

=item RasDeleteEntry ( )

 RasDeleteEntry( $entry );

Croaks if C<$entry> does not exist.
You should call C<IsEntry()> or C<RasEnumEntries()> before to verify C<$entry>.

=cut

#================
sub RasDeleteEntry ($) {
#================
   my $entry = shift;
   $LastError = 0;

   IsEntry($entry) or RASCROAK "`$entry' entry not found";

   $RasDeleteEntry ||= new("rasapi32", "RasDeleteEntry", [P,P], N);

   my $ret = $RasDeleteEntry->Call($PHONEBOOK||0, $entry);

   $ret and ($LastError = $ret, return);
   1;
}

=item RasEnumEntries ( )

 @entries = RasEnumEntries();

This function lists all entry names in the phonebook.

As this function is heavily used internally it croaks on errors - for
example if non-existing phonebook name is given. So, FALSE result means
that the selected phonebook is empty.

Command line syntax:

 perl -MWin32::RASE -e "$,=q{, };print RasEnumEntries"

=cut

#================
sub RasEnumEntries () {
#================
   $LastError = 0;
   $RasEnumEntries ||= new("rasapi32", "RasEnumEntries", [P,P,P,P,P], N);

   my $dwSize = RAS_MaxEntryName+1+4; DWORD_ALIGN($dwSize);

   my $RASENTRYNAME = pack "La".(20*$dwSize-4), ($dwSize, "");

   my ($lpcb, $lpcEntries) = (pack("L",length $RASENTRYNAME), DWORD_NULL);

   my $ret = $RasEnumEntries->Call(0, $PHONEBOOK||0,
	 $RASENTRYNAME, $lpcb, $lpcEntries);

   if ($ret) {
      my $cb = unpack "L",$lpcb;
      $RASENTRYNAME = pack "La".($cb-4), ($dwSize, "");

      $ret = $RasEnumEntries->Call(0, $PHONEBOOK||0,
	 $RASENTRYNAME, $lpcb, $lpcEntries) and RASERROR($ret);
   }

   my @entries;

   for my $i(1..unpack "L",$lpcEntries) {
      my $buffer  = substr $RASENTRYNAME, ($dwSize*($i-1)), $dwSize;

      my ($dwSize1, $szEntryName) = unpack "La".($dwSize-4), $buffer;

      CRUNCH($szEntryName);
      push @entries, $szEntryName;
   }
   @entries;
}

=item IsEntry ( )

 IsEntry ( $entry );

 $entry  - name of the RAS/DUN entry

Returns TRUE if C<$entry> was found in the phonebook,
otherwise FALSE.

B<NOTE!> It treats entry-names as case-sensitive (see above).

=cut

#================
sub IsEntry ($) {
#================
   my $entry = shift;
   $LastError = 0;
   grep {$_ eq $entry} RasEnumEntries();
}

=item RasGetEntryDialParams ( )

This function retrieves the connection information saved by the last successful
call to the C<RasDial()> or C<RasSetEntryDialParams()> function for a specified
phonebook entry.

 ($UserName, $Password, $Domain, $CallbackNumber) =
                            RasGetEntryDialParams($entry);

 $entry          - name of RAS/DUN entry
 $UserName       - user's user name ;-)
 $Password       - yes, it's that secure
 $Domain         - domain on which authentication is to occur
 $CallbackNumber - callback phone number

Croaks if C<$entry> does not exist.

=cut

#================
sub RasGetEntryDialParams ($) {
#================
# domain in addr form because DNLEN = 15
# alternate $szPhoneNumber seems like is not stored in phonebook
# because RasSetEntryDialParams() does not set it
   my ($szEntryName, $szPhoneNumber, $szUserName,
       $szPassword, $szDomain, $szCallbackNumber) = shift;
   local $_;
   $LastError = 0;

   IsEntry($szEntryName) or RASCROAK "`$szEntryName' entry not found";

   $RasGetEntryDialParams ||= new("rasapi32", "RasGetEntryDialParams", [P,P,P], N);

   my $dwSize = 4 + RAS_MaxEntryName + 1 + RAS_MaxPhoneNumber + 1 +
      RAS_MaxCallbackNumber + 1 + UNLEN + 1 + PWLEN + 1 + DNLEN + 1 +
      (Win32::IsWinNT && $WINVER >= 0x401 ? 4+4 : 0);

   DWORD_ALIGN($dwSize);

   my $RASDIALPARAMS =
      pack "La".(RAS_MaxEntryName + 1), ($dwSize, $szEntryName);

   $RASDIALPARAMS .= "\0"x($dwSize - length $RASDIALPARAMS);

   my $lpfPassword = DWORD_NULL;
   my $ret;
   $ret = $RasGetEntryDialParams->Call($PHONEBOOK||0,
	 $RASDIALPARAMS, $lpfPassword);

   $ret and ($LastError = $ret, return);

   my $fPassword = unpack "L", $lpfPassword;

   ($szCallbackNumber, $szUserName, $szPassword, $szDomain) =
    unpack "a".(RAS_MaxCallbackNumber + 1)."a".(UNLEN + 1).
    "a".(PWLEN + 1)."a".(DNLEN + 1),
    substr($RASDIALPARAMS, 4 + RAS_MaxEntryName + 1 + RAS_MaxPhoneNumber + 1);

    CRUNCH($szUserName, $szPassword, $szDomain, $szCallbackNumber);
    undef $szPassword unless $fPassword;

   ($szUserName, $szPassword, $szDomain, $szCallbackNumber);
}

=item RasGetUserPwd ( )

The short variant of previous.

 ($UserName, $Password) = RasGetUserPwd($entry);

Croaks if C<$entry> does not exist.

Command line syntax:

 perl -MWin32::RASE -e "print ((RasGetUserPwd('NEV1'))[0])"
 perl -MWin32::RASE -e "@_=RasGetUserPwd('NEV1');print qq{@_}"

=cut

#================
sub RasGetUserPwd ($) {
#================
   $LastError = 0;
   my @a = RasGetEntryDialParams(shift) or return;
   @a[0,1];
}

=item RasSetEntryDialParams ( )

This function changes the connection information for a specified
phonebook entry.

 RasSetEntryDialParams($entry, $UserName, $Password, $Domain,
                       $CallbackNumber, $fRemovePassword);

All parameters except C<$entry> are optional. C<undef> or omitted
parameters are considered to be "" - this means that no changes will
be made to this parameter.

 $entry           - name of RAS/DUN entry
 $UserName        - user name
 $Password        - password for the user specified by $UserName.
      If $UserName is an empty string, the password is not changed.
      If $Password is an empty string and $fRemovePassword is FALSE,
      the password is set to the empty string. If $fRemovePassword is
      TRUE, the password stored in this phonebook entry for the user
      specified by $UserName is removed regardless of the contents
      of the $Password string.
 $Domain          - domain on which authentication is to occur.
                    15 chars limitation.
 $CallbackNumber  - callback phone number
 $fRemovePassword - (above) 0 if undefined/omitted


This is another excerpt from the API docs:

B<Windows NT:> You can use $Password to send a new password to the remote server
when you restart a RasDial() connection from a RASCS_PasswordExpired paused state.
When changing a password on an entry that calls Microsoft Networks, you should
limit the new password to 14 characters in length to avoid down-level
compatibility problems.

Croaks if C<$entry> does not exist.

=cut

#================
sub RasSetEntryDialParams ($;$$$$$) {
#================
# domain in addr form because DNLEN = 15
# alternate $szPhoneNumber is not set
# each empty/undef value here means "don't change old value".

   my ($szEntryName, $szUserName, $szPassword,
       $szDomain, $szCallbackNumber, $fRemovePassword) = @_;
   my $szPhoneNumber;
   local $_;
   $LastError = 0;

   IsEntry($szEntryName) or RASCROAK "`$szEntryName' entry not found";

   $RasSetEntryDialParams ||= new("rasapi32", "RasSetEntryDialParams", [P,P,N], N);

   my $dwSize = 4 + RAS_MaxEntryName + 1 + RAS_MaxPhoneNumber + 1 +
      RAS_MaxCallbackNumber + 1 + UNLEN + 1 + PWLEN + 1 + DNLEN + 1 +
      (Win32::IsWinNT && $WINVER >= 0x401 ? 4+4 : 0);

   DWORD_ALIGN($dwSize);

   my $RASDIALPARAMS =
      pack "La".(RAS_MaxEntryName + 1)."a".(RAS_MaxPhoneNumber + 1).
      "a".(RAS_MaxCallbackNumber + 1)."a".(UNLEN + 1).
      "a".(PWLEN + 1)."a".(DNLEN + 1)
      ,
      ($dwSize, $szEntryName||"", $szPhoneNumber||"", $szCallbackNumber||"",
       $szUserName||"", $szPassword||"", $szDomain||"");

   $RASDIALPARAMS .= "\0"x($dwSize - length $RASDIALPARAMS);

   my $ret = $RasSetEntryDialParams->Call($PHONEBOOK||0,
	 $RASDIALPARAMS, $fRemovePassword||0);

   $ret and ($LastError = $ret, return);
   1;
}

=item RasGetEntryProperties ( )

This function retrieves the properties of a phonebook entry.

 $props = RasGetEntryProperties($entry);

 $entry          - name of RAS/DUN entry
 $props          - pointer to hash


The description of the %$props hash is common for this function and
C<RasSetEntryProperties()>.


  KEY                         VALUE

  name           - copy of $entry
  Flags          - numeric flag value, combination of RASEO_* flags.
                   You don't need to use it directly, it's here for
                   information purpose only. In RasSetEntryProperties()
                   it is ignored if present, you should manipulate
                   mnemonic flags as described below, with the
                   'newFlags' key.
  FlagsReadable  - $props->{FlagsReadable} refers to array of
                   "mnemonic flags" that are affecting the behavior
                   of the other properties.
                   Not used by RasSetEntryProperties().

Manipulating these flags is described in C<RasSetEntryProperties()> section.

  ipaddr         - constant ip-address, ignored unless "SpecificIpAddr"
                   is present in the array of "mnemonic flags"
  ipaddrDns      - primary DNS server
  ipaddrDnsAlt   - secondary(backup) DNS server
  ipaddrWins     - IP address of the primary WINS server
  ipaddrWinsAlt  - secondary WINS server

C<ipaddrDns>, C<ipaddrDnsAlt>, C<ipaddrWins>, C<ipaddrWinsAlt> are
ignored unless "SpecificNameServers" is present in the array of "mnemonic flags"

All IP-addresses are in xxx.xxx.xxx.xxx decimal form without leading zeros
in each part(octet). For example: 195.100.0.28

The common rule here is that empty or blank values will produce 0.0.0.0
(as well as "0.0.0.0" itself).

  CountryID        -
  CountryName      -
  CountryCode      -
  AreaCode         -

(Country ID-Name-Code and AreaCode are described in the
C<TAPIlineGetTranslateCaps()> section except that here they are describing
the computer you want to dial to.)

In C<RasSetEntryProperties()>
C<CountryName> would be ignored. C<CountryID> not matching C<CountryCode>
would give error. You could easily give only one of these two values. C<CountryCode>
would be counted properly if C<CountryID> is given (described in
C<TAPIlineGetTranslateCaps()> section). But if you'll give C<CountryCode>
C<CountryID> would be set equal to C<CountryCode> that is sometimes incorrect
but does not affect the dialup connection.

You can also check the correctness of the C<CountryID> with the
C<IsCountryID()> function.

  LocalPhoneNumber - phone number without country/area parts

  Script           - script file's path.
                     On Win95 this is DialUp Scripting Tool script.

Windows NT: To indicate a SWITCH.INF script name, set the first character
of the name to "[". 

C<RasSetEntryProperties()> function may have a problem
saving the full script path (NT, fixed in the Service Pack 4).
http://support.microsoft.com/support/kb/articles/Q160/1/90.asp

  DeviceType     - one of the following string constants
                   (case-insensitive):
    "modem"    A modem accessed through a COM port
    "isdn"     An ISDN card with corresponding NDISWAN driver installed
    "x25"      An X.25 card with corresponding NDISWAN driver installed
               "x25" type is not implemented in RasSetEntryProperties()
               in this version of the module
    "vpn"      A Microsoft VPN Adapter

You can read a note about VPN and PPTP in the C<RasSetEntryProperties()> section.

  DeviceName    - name of a TAPI device to use with this phonebook entry

  NetProtocols  - network protocols to negotiate.
                  $props->{NetProtocols} refers to the array that can
                  contain one or more of the strings
                  (case insensitive in RasSetEntryProperties()):
    "NetBEUI"  NetBIOS End User Interface standard
    "Ipx"      IPX/SPX Compartible
    "Ip"       TCP/IP

  FramingProtocol  - framing protocol used by the server.
                     One of the following strings:
                     "PPP", "Slip", "RAS"
                     (case insensitive in RasSetEntryProperties())

B<Limitations:>

Subentries(multilink dialing) are currently not supported as well as X.25-related
parameters. Current version of Win32::RASE also does not allow you to change
'DeviceType' and 'DeviceName' elements. This will be added in some future.
Right now any changes in these fields will not affect the
C<RasSetEntryProperties()> execution.

B<Note:> don't misuse this function, in list context it returns
unreadable things for internal needs.

Croaks if C<$entry> does not exist.

For an easy way to change just the phone-number take a look at the
C<RasChangePhoneNumber()> section.

=cut

#================
sub RasGetEntryProperties ($) {
#================
   my $entry = shift;
   $LastError = 0;

   IsEntry($entry) or RASCROAK "`$entry' entry not found";

   $RasGetEntryProperties ||= new("rasapi32", "RasGetEntryProperties", [P,P,P,P,P,P], N);

   my ($RASENTRY, $dwSize) = InitializeRASENTRY();

# first call to find $lpdwDeviceInfoSize
   my ($lpdwEntryInfoSize, $lpbDeviceInfo, $lpdwDeviceInfoSize) =
#   (pack("L",$dwSize), "\0"x1024, pack("L",1024));
   (pack("L",$dwSize), 0, DWORD_NULL);

   my $ret = $RasGetEntryProperties->Call($PHONEBOOK||0, $entry, $RASENTRY,
       $lpdwEntryInfoSize, $lpbDeviceInfo, $lpdwDeviceInfoSize);
#print "get_ret1:$ret\n";
#   $ret and ($LastError = $ret, return);

   my $dwDeviceInfoSize = unpack "L",$lpdwDeviceInfoSize;
#print "\$dwDeviceInfoSize: $dwDeviceInfoSize\n";

   $lpbDeviceInfo = "\0"x$dwDeviceInfoSize;

   $ret = $RasGetEntryProperties->Call($PHONEBOOK||0, $entry, $RASENTRY,
       $lpdwEntryInfoSize, $lpbDeviceInfo, $lpdwDeviceInfoSize);

#print "get_ret2:$ret\n";
   $ret and ($LastError = $ret, return);

#print "DeviceInfo length:".length($lpbDeviceInfo)."\n";

#if ($lpdwDeviceInfoSize) {
#print hexizer($lpbDeviceInfo),"\n";
#}
#sub hexizer {
#   local $_ = uc unpack "H*", shift;
#   s/(..)/$1 /g;
#   s/.{48}/$&\n/g; $_;
#}


   wantarray ? ($RASENTRY, $lpbDeviceInfo) :
     RasBuildEntryProperties($entry, $RASENTRY, $lpbDeviceInfo);
}

#===========================
sub InitializeRASENTRY () {
#===========================
# creates empty RASENTRY

   my $dwSize = 4*13 + 4*((Win32::IsWinNT && $WINVER >= 0x401) ? 10 : 3) +
      (RAS_MaxAreaCode+1)   + (RAS_MaxPhoneNumber+1) + 3*MAX_PATH +
      (RAS_MaxDeviceType+1) + (RAS_MaxDeviceName+1)  +
      (RAS_MaxPadType+1)    + (RAS_MaxX25Address+1)  +
      (RAS_MaxFacilities+1) + (RAS_MaxUserData+1);

   DWORD_ALIGN($dwSize);
   my $dwAlternateOffset = $dwSize;

   my $RASENTRY = pack "La".($dwSize-4), ($dwSize, "");
   substr($RASENTRY,
     (4*4 + RAS_MaxAreaCode+1+RAS_MaxPhoneNumber+1), 4) =
     pack "L", $dwAlternateOffset;

   ($RASENTRY, $dwSize);
}
#====================
sub RasBuildEntryProperties ($$$) {
#====================
  my ($entry, $tagRASENTRY, $lpbDeviceInfo) = @_;
  my (@attr, @attrNP, $attrFP);

  my (
   $dwSize,
   $dwfOptions,          # +4

   $dwCountryID,         # +8
   $dwCountryCode,       # +12
   $szAreaCode,          # +16
   $szLocalPhoneNumber,
   $dwAlternateOffset,

   $ipaddr,
   $ipaddrDns,
   $ipaddrDnsAlt,
   $ipaddrWins,
   $ipaddrWinsAlt,

   $dwFrameSize,
   $dwfNetProtocols,
   $dwFramingProtocol,
   $szScript,
   $szAutodialDll,
   $szAutodialFunc,
   $szDeviceType,
   $szDeviceName,
#   $szX25PadType,
#   $szX25Address,
#   $szX25Facilities,
#   $szX25UserData,
#   $dwChannels,
#   $dwReserved1,
#   $dwReserved2,
#   $dwSubEntries,
#   $dwDialMode,
#   $dwDialExtraPercent,
#   $dwDialExtraSampleSeconds,
#   $dwHangUpExtraPercent,
#   $dwHangUpExtraSampleSeconds,
#   $dwIdleDisconnectSeconds,
   ) =  unpack "LLLLa".(RAS_MaxAreaCode+1)."a".(RAS_MaxPhoneNumber+1).
    "La4a4a4a4a4LLLa".(MAX_PATH)."a".(MAX_PATH)."a".(MAX_PATH).
    "a".(RAS_MaxDeviceType+1)."a".(RAS_MaxDeviceName+1)
#   ."a".(RAS_MaxPadType+1)   ."a".(RAS_MaxX25Address+1).
#    "a".(RAS_MaxFacilities+1)."a".(RAS_MaxUserData+1)
#    .(($WINVER >= 0x401) ? "LLLLLLLLLL" : "LLL")
    , $tagRASENTRY;



   $dwfNetProtocols & RASNP_NetBEUI and push @attrNP, "NetBEUI";
   $dwfNetProtocols & RASNP_Ipx     and push @attrNP, "Ipx";
   $dwfNetProtocols & RASNP_Ip      and push @attrNP, "Ip";

   $dwFramingProtocol eq RASFP_Ppp  and $attrFP = "PPP";
   $dwFramingProtocol eq RASFP_Slip and $attrFP = "Slip";
   $dwFramingProtocol eq RASFP_Ras  and $attrFP = "RAS";

   CRUNCH($szAreaCode, $szLocalPhoneNumber, $szScript,
#	  $szAutodialDll, $szAutodialFunc,
	  $szDeviceType,$szDeviceName);

   %TAPIEnumeration = TAPIEnumCountries() if !defined %TAPIEnumeration;

  my $props = {
  name              => $entry,
  ipaddr            => (join '.',map ord, split//,$ipaddr),
  ipaddrDns         => (join '.',map ord, split//,$ipaddrDns),
  ipaddrDnsAlt      => (join '.',map ord, split//,$ipaddrDnsAlt),
  ipaddrWins        => (join '.',map ord, split//,$ipaddrWins),
  ipaddrWinsAlt     => (join '.',map ord, split//,$ipaddrWinsAlt),
  CountryID         => $dwCountryID,
  CountryName       => (exists($TAPIEnumeration{$dwCountryID}) ?
                        $TAPIEnumeration{$dwCountryID}->[0] : ""),
  CountryCode       => $dwCountryCode,
  AreaCode          => $szAreaCode,
  LocalPhoneNumber  => $szLocalPhoneNumber,
  Script            => $szScript,
#  AutodialDll       => $szAutodialDll,
#  AutodialFunc      => $szAutodialFunc,
  DeviceType        => $szDeviceType,
  DeviceName        => $szDeviceName,
  Flags             => $dwfOptions,
  FlagsReadable     => [],
  NetProtocols      => \@attrNP,
  FramingProtocol   => $attrFP,
  };

  for my $i(@RASEO_vars) {
     push(@{ $props->{FlagsReadable} }, $i) if $dwfOptions & eval($i);
  }

  $props;
}

=item RasPrintEntryProperties ( )

This function provides nice printing of a phonebook entry properties.
For debugging, for fun etc.

 RasPrintEntryProperties( $entry );

 $entry          - name of RAS/DUN entry

Croaks if C<$entry> does not exist.

=cut

#====================
sub RasPrintEntryProperties ($) {
#====================
  my $entry = shift;
  $LastError = 0;

  my $props = RasGetEntryProperties($entry) or return;

  print "RAS/DUN entry: $entry\n\n";

  for my $p(sort keys %$props) {
     next if $p eq "name";
     if (! ref $props->{$p}) {
         printf "%18s: %s\n", $p, $props->{$p};
     } else {
         printf "%18s: %s\n", $p, @{$props->{$p}} ? $props->{$p}->[0] : "";
         map {printf "%18s  %s\n", "",$_} @{$props->{$p}}[1..$#{$props->{$p}}];
     }
  }
  1;
}

=item RasGetEntryDevProperties ( )

This function retrieves the properties of a device used by the phonebook entry
if this entry uses MS Unimodem compartible TSP (Telephone Service Provider) or
in other words - Unimodem compartible driver, on Win95 - always.


 $props = RasGetEntryDevProperties($entry);

 $entry          - name of RAS/DUN entry
 $props          - pointer to hash

(Sorry, the description might not be clear enough, just print your
properties with the C<RasPrintEntryDevProperties()> and it'd be much easier.)

The description of the C<%$props> hash is common for this function and
C<RasSetEntryDevProperties()> (not implemented yet).

It's much likely that only a small part of the described data is
really usefull. Look at the Win32 SDK/MS Platform SDK
(TAPI Prorammer's Reference - "comm/datamodem", "COMMCONFIG", "DCB",
"MODEMSETTINGS" sections) for more info.


 KEY                         VALUE

 name         - copy of $entry
 DeviceName   - name of a TAPI device to use with this phonebook entry
 DeviceType   - described in the RasGetEntryProperties() section

 Options      - numeric flag value, combination of the Option flags
                that appear on the Unimodem Option page.
                This member can be a combination of these values:

   TERMINAL_PRE  (1) - Displays the pre-terminal screen.
   TERMINAL_POST (2) - Displays the post-terminal screen.
   MANUAL_DIAL   (4) - Dials the phone manually, if capable of doing so
   LAUNCH_LIGHTS (8) - Displays the modem tray icon.

   Only the LAUNCH_LIGHTS value is set by default


 OptionsReadable  - an array ref, a readable representation of those
       Options, that are switched on. The array consists of zero or more
       strings
       "TERMINAL_PRE", "TERMINAL_POST", "MANUAL_DIAL", "LAUNCH_LIGHTS"

 WaitBong         - Number of seconds (in two seconds granularity) to
                    replace the wait for credit tone (default - 10 s)

 CallSetupFailTimer - the maximum number of seconds the modem should
       wait, after dialing is completed, for an indication that a
       modem-to-modem connection has been established. If a connection
       is not established in this interval, the call is assumed to have
       failed. This member is equivalent to register S7 in Hayes
       compatible modems.

 InactivityTimeout  - the maximum number of seconds of inactivity
       allowed after a connection is established. If no data is either
       transmitted or received for this period of time, the call is
       automatically terminated.
       This time-out is used to avoid excessive long distance charges
       or online service charges if an application unexpectedly locks up
       or the user leaves.

 SpeakerVolume    - one of the following values: "LOW", "MEDIUM", "HIGH"
       Note that actual volumes are hardware-specific.

 SpeakerMode      - one of the following values:
      "OFF"       - The speaker is always off
      "CALLSETUP" - The speaker is on until a connection is established
      "ON"        - The speaker is always on
      "DIAL"      - The speaker is on until a connection is established,
               except that it is off while the modem is actually dialing

 PreferredModemOptions - a numeric flag value. Specifies the modem
      options requested by the application. The local and remote modems
      negotiate modem options during call setup; this member specifies
      the initial negotiating position of the local modem. A combination
      of bit flags.

 PreferredModemOptionsReadable - refers to array of strings that
      represent bit flags of the previous. Contains zero or more of the
      following strings:
      "COMPRESSION", "ERROR_CONTROL", "FORCED_EC",
      "CELLULAR", "FLOWCONTROL_HARD", "FLOWCONTROL_SOFT",
      "CCITT_OVERRIDE", "SPEED_ADJUST",
      "TONE_DIAL", "BLIND_DIAL", "V23_OVERRIDE"

      Comments:
      CCITT_OVERRIDE - When set, CCITT modulations are enabled for V.21
                       and V.22 or V.23.When clear, bell modulations
                       are enabled for 103 and 212A.
      V23_OVERRIDE   - When set, CCITT modulations are enabled for V.23.
                       When clear, CCITT modulations are enabled for
                       V.21 and V.22.

For V.23 to be set, both CCITT_OVERRIDE and V23_OVERRIDE must be set.

 NegotiatedModemOptions - a numeric flag value. Specifies the modem
      options that are actually in effect. This member is filled in
      after a connection is established and the local and remote
      modems negotiate modem options. This value is read only.
      (On my Win95 - always 0).

 NegotiatedModemOptionsReadable - the same ref to array of the readable
      strings as PreferredModemOptionsReadable,
      but for NegotiatedModemOptions.

 NegotiatedDCERate - Specifies the DCE rate that is in effect.
      This member is filled in after a connection is established and
      the local and remote modems negotiate modem modulations.
      Also read-only.
      
DCE - Open Software Foundation (OSF) Distributed Computing Environment.

The DCB structure defines the control setting for a serial communications device.
The following keys are members of the DCB structure.

 DCB_BaudRate     - Specifies the baud rate at which the communications
      device operates. This member can be one of the following values:
      110, 300, 600, 1200, 2400, 4800, 9600, 14400, 38400,
      56000, 57600, 115200, 128000, 256000

 DCB_Flags        - numeric flag value, concatenation of many DCB flags.
                    You don't need to use it directly, it's here for
                    information purpose only.

 DCB_FlagsReadable - an array ref. The array consists of the 13 string
      values. Each string is in the form "flagname:value".
      The values are in most cases 0/1. The flags names are:

   fBinary          - Specifies whether binary mode is enabled.
       The Win32 API does not support nonbinary mode transfers, so this
       member should be 1. Trying to use 0 will not work.
       Under Windows 3.1, if this member is 0, nonbinary mode is
       enabled, and the character specified by the DBC_EofChar member
       is recognized on input and remembered as the end of data. (0/1)

   fParity          - Specifies whether parity checking is enabled (0/1)

   fOutxCtsFlow     - Specifies whether the CTS (clear-to-send) signal
       is monitored for output flow control. If this member is 1 and CTS
       is turned off, output is suspended until CTS is sent again. (0/1)

   fOutxDsrFlow     - Specifies whether the DSR (data-set-ready) signal
       is monitored for output flow control. If this member is 1 and DSR
       is turned off, output is suspended until DSR is sent again. (0/1)

   fDtrControl      - Specifies the DTR (data-terminal-ready)
                      flow control.
     This member can be one of the following values:
     0 - Disables the DTR line when the device is opened and leaves it
         disabled
     1 - Enables the DTR line when the device is opened and leaves it on
     2 - Enables DTR handshaking

   fDsrSensitivity  - Specifies whether the communications driver is
       sensitive to the state of the DSR signal. If this member is 1,
       the driver ignores any bytes received, unless the DSR modem input
       line is high. (0/1)

   fTXContinueOnXoff - Specifies whether transmission stops when the
       input buffer is full and the driver has transmitted the
       DCB_XoffChar character.
       If this member is 1, transmission continues after the input
       buffer has come within DCB_XoffLim bytes of being full and the
       driver has transmitted the DCB_XoffChar character to stop
       receiving bytes.
       If this member is 0, transmission does not continue until the
       input buffer is within DCB_XonLim bytes of being empty and the
       driver has transmitted the DCB_XonChar character to resume
       reception. (0/1)

   fOutX            - Specifies whether XON/XOFF flow control is used
       during transmission. If this member is 1, transmission stops when
       the DCB_XoffChar character is received and starts again when the
       DCB_XonChar character is received. (0/1)

   fInX              - Specifies whether XON/XOFF flow control is used
       during reception. If this member is 1, the DCB_XoffChar character
       is sent when the input buffer comes within DCB_XoffLim bytes of
       being full, and the DCB_XonChar character is sent when the input
       buffer comes within DCB_XonLim bytes of being empty. (0/1)

   fErrorChar        - Specifies whether bytes received with parity
       errors are replaced with the character specified by the
       DCB_ErrorChar member.
       If this member is 1 and the fParity member is 1, replacement
       occurs. (0/1)

   fNull             - pecifies whether null bytes are discarded.
       If this member is 1, null bytes are discarded when received.(0/1)

   fRtsControl       - Specifies the RTS (request-to-send) flow control.
       This member can be one of the following values:
       0 - Disables the RTS line when the device is opened and leaves
           it disabled.
       1 - Enables the RTS line when the device is opened and leaves
           it on.
       2 - Enables RTS handshaking. The driver raises the RTS line when
           the "type-ahead" (input) buffer is less than one-half full
           and lowers the RTS line when the buffer is more than
           three-quarters full.
       3 - Specifies that the RTS line will be high if bytes are
           available for transmission. After all buffered bytes have
           been sent, the RTS line will be low.

   fAbortOnError    - Specifies whether read and write operations are
       terminated if an error occurs. If this member is 1, the driver
       terminates all read and write operations with an error status if
       an error occurs. (0/1)

 DCB_XonLim      - Specifies the minimum number of bytes allowed in the
       input buffer before the XON character is sent.

 DCB_XoffLim     - Specifies the maximum number of bytes allowed in the
       input buffer before the XOFF character is sent. The maximum
       number of bytes allowed is calculated by subtracting this value
       from the size, in bytes, of the input buffer.

 DCB_ByteSize    - Specifies the number of bits in the bytes transmitted
                   and received.

 DCB_Parity      - Specifies the parity scheme to be used. This member
                   can be one of the following values:
                   "No parity", "Odd", "Even", "Mark", "Space"

 DCB_StopBits    - Specifies the number of stop bits to be used.
                   This member can be one of the following values:
       0 - 1 stop bit
       1 - 1.5 stop bits
       2 - 2 stop bits

 DCB_XonChar     - Specifies the value of the XON character for both
                   transmission and reception.

 DCB_XoffChar    - Specifies the value of the XOFF character for both
                   transmission and reception.

 DCB_ErrorChar   - Specifies the value of the character used to replace
                   bytes received with a parity error.

 DCB_EofChar     - Specifies the value of the character used to signal
                   the end of data.

 DCB_EvtChar     - Specifies the value of the character used to signal
                   an event.


Manipulating these flags is described in C<RasSetEntryDevProperties()> section.
(not implemented yet).

The function croaks if C<$entry> does not exist.


=cut

#==================================
sub RasGetEntryDevProperties ($) {
#==================================
   my $entry = shift;
   local $_;
   $LastError = 0;

   my ($RASENTRY, $lpbDeviceInfo) = RasGetEntryProperties($entry) or return;
   my $props = RasBuildEntryProperties($entry, $RASENTRY, $lpbDeviceInfo);

   my $devOptions = {
	name => $entry,
	DeviceName => $props->{DeviceName},
	DeviceType => $props->{DeviceType},
   };
   return unless $lpbDeviceInfo;
   # MS Unimodem driver
   my ($DEVCFGHDR, $COMMCONFIG) =
	(substr($lpbDeviceInfo, 0,12), substr($lpbDeviceInfo, 12));

   my  ($dwSize1,
	$dwVersion,
	$fwOptions,
	$wWaitBong) = unpack "LLSS", $DEVCFGHDR;

   return unless $dwVersion == 0x10003; # Unimodem
#open O,">out";binmode O;print O $COMMCONFIG;close O;
#exit;

   my  ($dwSize2,
	$wVersion,
	$wReserved,
	$DCB,
	$dwProviderSubType,
	$dwProviderOffset,
	$dwProviderSize,
   ) = unpack "LSS a28 LLL", $COMMCONFIG;

   return unless $dwProviderSubType == PST_MODEM;

   $devOptions->{WaitBong}        = $wWaitBong;
   $devOptions->{Options}         = $fwOptions;
   $devOptions->{OptionsReadable} = [];

   for (qw( TERMINAL_PRE  TERMINAL_POST  MANUAL_DIAL  LAUNCH_LIGHTS )) {

     (eval "$_") & $fwOptions and
	  push @{$devOptions->{OptionsReadable}}, $_;
   }

   my $MODEMSETTINGS = substr $COMMCONFIG, $dwProviderOffset, $dwProviderSize;

   my (	$dwActualSize,               # size of returned data, in bytes
	$dwRequiredSize,             # total size of structure
	$dwDevSpecificOffset,        # offset of provider-defined data
	$dwDevSpecificSize,          # size of provider-defined data

     # Static local options (read/write)
	$dwCallSetupFailTimer,       # call setup timeout, in seconds
	$dwInactivityTimeout,        # inactivity timeout, in tenths of seconds
	$dwSpeakerVolume,            # speaker volume level
	$dwSpeakerMode,              # speaker mode
	$dwPreferredModemOptions,    # bitmap specifying preferred options

     # negotiated options (read only) for current or last call
	$dwNegotiatedModemOptions,   # bitmap specifying actual options
	$dwNegotiatedDCERate,        # DCE rate, in bits per second

     # Variable portion for proprietary expansion
     #    BYTE  abVariablePortion[1]
   ) = unpack "LLLLLLLLLLL", $MODEMSETTINGS;

   $devOptions->{CallSetupFailTimer}     = $dwCallSetupFailTimer;
   $devOptions->{InactivityTimeout}      = $dwInactivityTimeout;
   $devOptions->{SpeakerVolume}          = (qw(LOW MEDIUM HIGH))[$dwSpeakerVolume];
   $devOptions->{SpeakerMode}            = (qw(OFF DIAL ON CALLSETUP))[$dwSpeakerMode];
   $devOptions->{PreferredModemOptions}  = $dwPreferredModemOptions;
   $devOptions->{PreferredModemOptionsReadable}  = [];
   $devOptions->{NegotiatedModemOptions} = $dwNegotiatedModemOptions;
   $devOptions->{NegotiatedModemOptionsReadable} = [];
   $devOptions->{NegotiatedDCERate}      = $dwNegotiatedDCERate;

   for (qw(COMPRESSION ERROR_CONTROL FORCED_EC
	CELLULAR FLOWCONTROL_HARD FLOWCONTROL_SOFT CCITT_OVERRIDE
	SPEED_ADJUST TONE_DIAL BLIND_DIAL V23_OVERRIDE)) {

     (eval "MDM_$_") & $dwPreferredModemOptions and
	  push @{$devOptions->{PreferredModemOptionsReadable}}, $_;

     (eval "MDM_$_") & $dwNegotiatedModemOptions and
	  push @{$devOptions->{NegotiatedModemOptionsReadable}}, $_;
   }

   my ( $DCBlength,
	$BaudRate,     # current baud rate
	$Flags,
	$wReserved2,    # not currently used

	$XonLim,       # transmit XON threshold
	$XoffLim,      # transmit XOFF threshold
	$ByteSize,     # number of bits/byte, 4-8
	$Parity,       # 0-4=no,odd,even,mark,space
	$StopBits,     # 0,1,2 = 1, 1.5, 2
	$XonChar,      # Tx and Rx XON character
	$XoffChar,     # Tx and Rx XOFF character
	$ErrorChar,    # error replacement character

	$EofChar,      # end of input character
	$EvtChar,      # received event character
	$wReserved1,
   ) = unpack "LLLSSSCCCaaaaaS", $DCB;

   my @temp = (
	"fBinary:1",           # binary mode, no EOF check
	"fParity:1",           # enable parity checking
	"fOutxCtsFlow:1",      # CTS output flow control
	"fOutxDsrFlow:1",      # DSR output flow control
	"fDtrControl:2",       # DTR flow control type
	"fDsrSensitivity:1",   # DSR sensitivity

	"fTXContinueOnXoff:1", # XOFF continues Tx
	"fOutX:1",             # XON/XOFF out flow control
	"fInX:1",              # XON/XOFF in flow control
	"fErrorChar:1",        # enable error replacement
	"fNull:1",             # enable null stripping
	"fRtsControl:2",       # RTS flow control
	"fAbortOnError:1",     # abort reads/writes on error
#	"fDummy2:17",          # reserved
   );

   my $BFlags = reverse unpack "B32",reverse pack "L",$Flags;
#print "$BFlags\n";
   my $pos = 0;

   for (0..$#temp) {
	 my($k,$v) = $temp[$_] =~ /^(.+):(\d+)$/;
	 my $b = substr($BFlags, $pos, $v); $pos+=$v;
#	 $devOptions->{"DCB_$k"} = ord pack "B8", substr("00000000".$b, -8);
	 $temp[$_] = "$k:".ord pack "B8", substr("00000000".$b, -8);

   }

   $devOptions->{"DCB_FlagsReadable"} = \@temp;

   my $caller = (caller(1))[3];

   for (qw(BaudRate Flags XonLim XoffLim ByteSize Parity StopBits
	XonChar XoffChar ErrorChar EofChar EvtChar)) {

	$devOptions->{"DCB_$_"} =
	   /Char$/ && $caller =~ /RasPrintEntryDevProperties/
	   ? sprintf("0x%2.2X", ord eval "\$$_") : eval "\$$_";
   }

   $devOptions->{DCB_Parity} =
     ("No parity", "Odd", "Even", "Mark", "Space")[$devOptions->{DCB_Parity}];

   $devOptions;
}

=item RasPrintEntryDevProperties ( )

This function provides nice printing of a phonebook entry device properties
if this entry uses MS Unimodem compartible TSP (Telephone Service Provider) or
in other words - Unimodem compartible driver, on Win95 - always.

Look at the C<RasGetEntryDevProperties()> section and Win32 SDK
for more info.

Char values (XonChar, XoffChar, ErrorChar, EofChar, EvtChar) are printed
in hexadecimal form like 0x13.

For debugging, for fun etc.

 RasPrintEntryDevProperties( $entry );

 $entry          - name of RAS/DUN entry

Croaks if C<$entry> does not exist. Silently returns if the device is not
Unimodem-compartible.

=cut

#====================
sub RasPrintEntryDevProperties ($) {
#====================
  my $entry = shift;
  $LastError = 0;

  my $props = RasGetEntryDevProperties($entry) or return;

  print "RAS/DUN entry: $entry\n\n";

  for my $p(sort keys %$props) {
     next if $p eq "name";
     if (! ref $props->{$p}) {
         printf "%30s: %s\n", $p, $props->{$p};
     } else {
         printf "%30s: %s\n", $p, @{$props->{$p}} ? $props->{$p}->[0] : "";
         map {printf "%30s  %s\n", "",$_} @{$props->{$p}}[1..$#{$props->{$p}}];
     }
  }
  1;
}

=item RasCopyEntry ( )

This function makes a copy of the existing RAS entry.
Some properties of this newly created entry could then be changed with the use
of C<RasSetEntryProperties()>. In previous versions of the
module it was the only way to create a new entry silently, programmatically. But
as of 0.07 we have full featured C<RasCreateEntry()>.

You can also create new entry via dialog, see C<RasCreateEntryDlg()>.

   RasCopyEntry( $oldname, $newname );

Croaks if C<$oldname> does not exist or C<$newname> already exists.
You should call C<IsEntry()> or C<RasEnumEntries()> before to verify both.

C<$newname> must contain at least one non-white-space alphanumeric character
and cannot begin with a period (".").

Username, password etc. (see C<RasGetEntryDialParams()>
and C<RasSetEntryDialParams()>) are not copied
to the newly created entry.

=cut

#======================
sub RasCopyEntry ($$) {
#======================
# NB! country code is not TAPI countryID
  my ($old, $new) = @_;
  $LastError = 0;

  IsEntry($old)  or RASCROAK "`$old' entry not found";
  IsEntry($new) and RASCROAK "`$new' entry already exists";

  $RasSetEntryProperties ||= new("rasapi32", "RasSetEntryProperties", [P,P,P,N,P,N], N);

  my ($tagRASENTRY, $lpbDI) = RasGetEntryProperties($old) or return;

  my $ret = $RasSetEntryProperties->Call($PHONEBOOK||0, $new, $tagRASENTRY,
     length($tagRASENTRY), $lpbDI, length $lpbDI);

  $ret and ($LastError = $ret, return);
  1;
}

=item RasSetEntryProperties ( )

This function changes the connection information for an existing entry.

 RasSetEntryProperties( $props );

 $props          - reference to hash with replacing properties

Mainly keys/values of the %$props hash are described in the
C<RasGetEntryProperties()>
section. But here we can use just part of the full hash - if keys are
undefined no changes will be made to the corresponding properties. Only
$props->{name} has to contain a name of the existing phonebook entry, all other
keys are optional.

Those properties that do exist in %$props will replace current properties.
If $props->{some-key} is defined and empty ("") the corresponding property
will be empty.

C<DeviceType>, C<CountryName>, C<Flags> and
C<FlagsReadable> keys are not used by this function. Anyway, all
unneeded keys will be ignored without any errors.

As of the version 0.07 you B<can> change the RAS device using with
the entry by specifying the new device name in $props->{DeviceName}.
The function finds the device type internally, so $props->{DeviceType}
is ignored if specified.

If "DeviceName" key is present in the C<%$props>
the function resets device properties for C<$props->{name}> entry to the
default values (for the list of device properties see
C<RasGetEntryDevProperties()>). C<RasEnumDevices()> function gives the
RAS-capable devices enumeration.

B<Microsoft has confirmed a possible problem>: With multiple modems installed under
Windows NT 4.0, the RasSetEntryProperties
API function calls will reset the selected modem to the first available modem.
This problem has been corrected in the latest U.S. Service Pack (4).


Print the whole enumeraton like this:

  %devices = RasEnumDevices() or die "Error";
  print map "\"$_\" of type \"$devices{$_}\"\n", keys %devices;

In addition to the keys decribed in the C<RasGetEntryProperties()>
section the string value
$props->{newFlags} can be used for adding/removing the existing flags
within the RAS-entry.

This string has the format: "<token1> <token2>..." (any C<\s> separators are possible)

Each token can be one of the following values (same as mnemonic flags
described in the C<RasGetEntryProperties()> section):

      UseCountryAndAreaCodes
      SpecificIpAddr
      SpecificNameServers
      IpHeaderCompression
      RemoteDefaultGateway
      DisableLcpExtensions
      TerminalBeforeDial
      TerminalAfterDial
      ModemLights
      SwCompression
      RequireEncryptedPw
      RequireMsEncryptedPw
      RequireDataEncryption
      NetworkLogon
      UseLogonCredentials
      PromoteAlternates
      SecureLocalFiles

These strings are just the meaningful parts of C<RASEO_*> constants' names
(from "ras.h" file). They are rather descriptive, you can easily find
their meaning by changing and printing an existing RAS entry. Not
all of them will work in this version of the module.

Each of these flags could be used with or without the "RASEO_" prefix.
With or without
`+' or `-' prefix (no blanks between [+-] and "mnemonic flag") - this
is the token mentioned above.

Additional token that can't be prefixed with `+' or `-' is "KeepOldFlags",
it still can be prefixed with "RASEO_".

If this new flag-string ($props->{newFlags}) is C<defined> the default action
is to reset all old flags. "KeepOldFlags" prevents from this cleanup.

The token with `-' will reset the corresponding flag if it was set, otherwise -
no effect. The token with `+' will set the corresponding flag if it was not
set, otherwise - no effect. The order of tokens is not important, tokens are
separated by any number of blanks. Token without `+' or `-' means `+'.

Examples:

C<"NetworkLogon +SwCompression"> - reset old flags and add these two.

C<"-NetworkLogon -SwCompression KeepOldFlags"> - keep old flags and clean these two.

The function croaks if C<$entry> does not exist and on some impossible
values of the parameters.

B<PPTP note> (Point to Point Tunneling Protocol):
You can use an ip-address in place of LocalPhoneNumber if your DUN/RAS entry
is configured to work with VPN (Virtual Private Networking) via PPTP.
PPTP appears as a new modem type that can be selected in DUN entry only manually.
It DeviceName is "Microsoft VPN Adapter" and DeviceType is "vpn".
In this case you can change the ip-address of the
VPN-host as if it were local phone number. For example

 RasSetEntryProperties({
       name=>"NEV5",
       LocalPhoneNumber=>"21.100.14.12",
 });

You can get info about VPN and PPTP at

http://support.microsoft.com/support/kb/articles/q154/0/91.asp

DUN 1.3 that supports VPN is downloadable from

http://support.microsoft.com/download/support/mslfiles/MSDUN13.EXE

and is described here

http://support.microsoft.com/support/kb/articles/q194/4/77.asp


Thanks to Carl Sewell C<<>csewell@hiwaay.netC<>> for his explanations
and testing of VPN features.

B<Microsoft has confirmed the possible problem:>
After applying Service Pack 2, the RasSetEntryProperties flags for
RASEO_TerminalAfterDial and RASEO_TerminalBeforeDial specified in
the Win32 function call are not set. This problem occurs because
Service Pack 2 causes the parameters to be ignored.
This problem has been corrected in Service Pack 3.

http://support.microsoft.com/support/ntserver/serviceware/nts40/E9MSL2CSA.ASP

B<Microsoft:> When using the RasSetEntryProperties API call to change the connection
information for an entry in the phone book or create a new phone-book entry,
the szScript (C<$props->{Script}> in C<Win32::RASE>) parameter of the RASENTRY
structure is not always preserved.

http://support.microsoft.com/support/kb/articles/q160/1/90.asp

This problem applies to WinNT 4.0 and was corrected in the latest
Microsoft Windows NT 4.0 U.S. Service Pack (4).

The function croaks if the specfied device is not found.

=cut

#======================
sub RasSetEntryProperties ($) {
#======================
  my $props = shift;
  $LastError = 0;

  ref($props) eq "HASH" or RASCROAK "argument is not a hash-reference";

  $props->{name} or RASCROAK "\$props->{name} hash key does not exist";

  IsEntry($props->{name}) or
	RASCROAK "\$props->{name}==`$props->{name}' is not an existing entry";

  my ($RASENTRY, $lpbDeviceInfo) =
	 RasGetEntryProperties($props->{name}) or return;

#  if ($props->{DeviceName}) {
#     my $COMMCONFIG = GetDefaultCommConfig($props->{DeviceName}) or return;
#
#     my $dwDeviceInfoSize = 12 + length $COMMCONFIG;
#     my $DEVCFGHDR        = pack "LLSS", $dwDeviceInfoSize, 0x00010003, 8, 10;
#     $lpbDeviceInfo       = $DEVCFGHDR.$COMMCONFIG;
#  }

  $RASENTRY = ParseRASENTRY($props, $RASENTRY);

  $RasSetEntryProperties ||= new("rasapi32", "RasSetEntryProperties", [P,P,P,N,P,N], N);

  my $ret;

  unless ($props->{DeviceName}) {
     $ret = $RasSetEntryProperties->Call($PHONEBOOK||0,
	    $props->{name}, $RASENTRY, length($RASENTRY),
	    $lpbDeviceInfo, length $lpbDeviceInfo);

#print "ret1:$ret\n";
  } else {
     $ret = $RasSetEntryProperties->Call($PHONEBOOK||0,
	    $props->{name}, $RASENTRY, length($RASENTRY),0,0);
#print "ret2:$ret\n";

     my ($RASENTRY1, $lpbDeviceInfo1) =
	 RasGetEntryProperties($props->{name}) or return;
#print "New lpbDeviceInfo size:".length($lpbDeviceInfo1)."\n";

     $ret = $RasSetEntryProperties->Call($PHONEBOOK||0,
	    $props->{name}, $RASENTRY, length($RASENTRY),
	    $lpbDeviceInfo1, length $lpbDeviceInfo1);
#print "ret3:$ret\n";
  }

  $ret and ($LastError = $ret, return);
  1;
}

=item RasCreateEntry ( )

This function creates RAS/DUN entry programmatically (note that
C<RasCreateEntryDlg()> displays dialo boxes).

  RasCreateEntry( $props );

C<Win32::RASE::PHONEBOOK> defines the phonebook in which the new entry will
be created (WinNT).

For the explanation of the C<%$props> hash see the previous C<RasSetEntryProperties()>
function. The main difference is that these keys

  name, LocalPhoneNumber, NetProtocols, FramingProtocol, DeviceName

are mandatory in this hash.

You have to specify at least one of CountryID and CountryCode keys and AreaCode
key if C<$props->{newFlags}> contains "+UseCountryAndAreaCodes".

All ip-addresses if omitted are assumed to be "0.0.0.0". Empty or non-existing
C<$props->{newFlags}> gives zero numeric flag which means that none of the
C<RASEO_*> options are in use. Flag "KeepOldFlags" has no meaning but makes
no error.

Note that the device settings would be copied from your system defaults and
some minor features still could not be customized (see C<RasGetEntryDevProperties()>).

=cut

#======================
sub RasCreateEntry ($) {
#======================
  my $props = shift;
  local $_;
  $LastError = 0;

  ref($props) eq "HASH" or RASCROAK "argument is not a hash-reference";

  $props->{name} or RASCROAK "\$props->{name} hash key does not exist";

  IsEntry($props->{name}) and
	RASCROAK "\$props->{name}==`$props->{name}' entry already exists";

  my @mandatory = qw(name LocalPhoneNumber NetProtocols FramingProtocol DeviceName);

  for (@mandatory) {
     exists $props->{$_} or
	RASCROAK "\$props->{$_} mandatory key does not exist";
     $props->{$_} or
	RASCROAK "\$props->{$_} is empty";
  }

  my $RASENTRY   = ParseRASENTRY($props);
#  my $COMMCONFIG = GetDefaultCommConfig($props->{DeviceName}) or return;
#
#  my $dwDeviceInfoSize = 12 + length $COMMCONFIG;
#  my $DEVCFGHDR        = pack "LLSS", $dwDeviceInfoSize, 0x00010003, 8, 10;
#  my $lpbDeviceInfo    = $DEVCFGHDR.$COMMCONFIG;

  $RasSetEntryProperties ||= new("rasapi32", "RasSetEntryProperties", [P,P,P,N,P,N], N);

  my $ret = $RasSetEntryProperties->Call($PHONEBOOK||0,
	 $props->{name}, $RASENTRY, length($RASENTRY),0,0);

#print "ret1:$ret\n";

  my($RASENTRY1, $lpbDeviceInfo) = RasGetEntryProperties($props->{name});

#print "lpbDeviceInfo size:".length($lpbDeviceInfo)."\n";

$ret = $RasSetEntryProperties->Call($PHONEBOOK||0,
	 $props->{name}, $RASENTRY, length($RASENTRY),
	 $lpbDeviceInfo, length $lpbDeviceInfo);

#print "ret2:$ret\n";


  $ret and ($LastError = $ret, return);
  1;
}


#======================
sub ParseRASENTRY ($;$) {
#======================
  my ($props, $RASENTRY) = @_;
  my ($NP, $FP, $newFlags);
  my $pat = HOSTNUMBER();
  local $_;


  my ($entry, $Flags, $CountryID, $CountryCode, $AreaCode, $LocalPhoneNumber,
      $NetProtocols, $FramingProtocol, $Script, $DeviceName) =
  map $props->{$_}, qw(
      name newFlags CountryID CountryCode AreaCode LocalPhoneNumber
      NetProtocols FramingProtocol Script DeviceName
  );


  ($RASENTRY) = InitializeRASENTRY() unless $RASENTRY;

  my (
   $dwSize,
   $dwfOptions,

   $dwCountryID,
   $dwCountryCode,
   $szAreaCode,
   $szLocalPhoneNumber,
   $dwAlternateOffset,

   $ipaddr,
   $ipaddrDns,
   $ipaddrDnsAlt,
   $ipaddrWins,
   $ipaddrWinsAlt,

   $dwFrameSize,
   $dwfNetProtocols,
   $dwFramingProtocol,
   $szScript,

   $szAutodialDll,
   $szAutodialFunc,

   $szDeviceType,
   $szDeviceName,
   ) =  unpack "LLLLa".(RAS_MaxAreaCode+1)."a".(RAS_MaxPhoneNumber+1).
    "La4a4a4a4a4LLL".(("a".MAX_PATH) x 3).
    "a".(RAS_MaxDeviceType + 1)."a".(RAS_MaxDeviceName + 1), $RASENTRY;


   if (defined $DeviceName) {
     TRIM_LR($DeviceName);
     CRUNCH($szDeviceName);

     if ($DeviceName ne $szDeviceName) {
        %RasDevEnumeration = RasEnumDevices() unless defined %RasDevEnumeration;
        exists $RasDevEnumeration{$DeviceName} or
	    RASCROAK "device `$DeviceName' not found or non RAS-capable";

	$szDeviceName  = $DeviceName;
	$szDeviceType  = $RasDevEnumeration{$DeviceName};
     }
   }

   if (defined $Script) {
     TRIM_LR($Script);
     RASCROAK "script `$Script' not found/empty"
	 unless $Script eq "" || (-f $Script && -s_);
     $szScript = $Script;
   }

   if (defined $AreaCode) {
     TRIM_LR($AreaCode);
     RASCROAK "wrong area code `$AreaCode'"
	 unless $AreaCode =~ /^\d*$/;
     $szAreaCode = $AreaCode;
   }

   if (defined $LocalPhoneNumber) {
     TRIM_LR($LocalPhoneNumber);

     RASCROAK "wrong local phone number `$LocalPhoneNumber'"
	 unless $LocalPhoneNumber =~ /^[\d\-.]*$/;
     # dot '.' added for ip-address (DUN 1.3 - VPN via PPTP) or French style

     $szLocalPhoneNumber = $LocalPhoneNumber;
   }

   if (defined $CountryID) {
     %TAPIEnumeration = TAPIEnumCountries() if !defined %TAPIEnumeration;

     TRIM_LR($CountryID);

     RASCROAK "wrong CountryID `$CountryID'"
	 unless $CountryID =~ /^\d*$/;

     RASCROAK "CountryID not found `$CountryID'"
	 unless exists $TAPIEnumeration{$CountryID};

     $dwCountryID = $CountryID;

     if (defined $CountryCode) {
	 RASCROAK "CountryID `$CountryID'".
	   " does not match CountryCode `$CountryCode'"
	   unless $CountryCode == $TAPIEnumeration{$CountryID}->[1];
     }

     $dwCountryCode = $TAPIEnumeration{$CountryID}->[1];

   } elsif (defined $CountryCode) {
     %TAPIEnumeration = TAPIEnumCountries() if !defined %TAPIEnumeration;

     TRIM_LR($CountryCode);

     RASCROAK "wrong CountryCode `$CountryCode'" unless $CountryCode =~ /^\d*$/;

     grep {$TAPIEnumeration{$_}->[1] == $CountryCode} keys %TAPIEnumeration or
	RASCROAK "CountryCode not found `$CountryCode'";

     $dwCountryCode = $dwCountryID = $CountryCode;
   }

   for (qw(ipaddrDns ipaddrDnsAlt ipaddrWins ipaddrWinsAlt ipaddr)) {
     if (defined $props->{$_}) {
	 my $var = $props->{$_};

	 TRIM_LR($var);

	 if (!$var) {
	     eval "\$$_ = DWORD_NULL";
	 } else {
	     RASCROAK "wrong $_ `$var'" unless $var =~ /^$pat$/;
	     eval "\$$_ = pack 'C4', split/\\./, \$var";
     	 }
     }
   }

   if (defined $FramingProtocol) {
     ($FP = $FramingProtocol) =~ s/^ *(.*?) *$/uc $1/es;
     RASCROAK "wrong framing protocol `$FramingProtocol'"
	 unless $FP =~ /^(PPP|SLIP|RAS)$/;
     $dwFramingProtocol = RASFP_Ppp  if $FP eq 'PPP';
     $dwFramingProtocol = RASFP_Slip if $FP eq 'SLIP';
     $dwFramingProtocol = RASFP_Ras  if $FP eq 'RAS';
   }

   if (defined $NetProtocols) {
     RASCROAK "\$props->{$NetProtocols} is not an array ref"
	 unless ref $NetProtocols eq "ARRAY";

     ($NP = join "|", @$NetProtocols) =~ s/^ *(.*?) *$/uc $1/es;
     RASCROAK "wrong net protocols `$NetProtocols'"
	 unless $NP =~ /^(NETBEUI|IPX|IP)(\|(NETBEUI|IPX|IP))*$/;
     $dwfNetProtocols  = 0;
     $dwfNetProtocols |= RASNP_NetBEUI if $NP =~ /NETBEUI/;
     $dwfNetProtocols |= RASNP_Ipx     if $NP =~ /IPX/;
     $dwfNetProtocols |= RASNP_Ip      if $NP =~ /IP(\||$)/;
   }

# flags logic
   if (defined $Flags) {
      $newFlags = ($Flags =~ s/\+?(RASEO_)?KeepOldFlags//) ? $dwfOptions : 0;
      $newFlags = 0 if $Flags =~ s/\-(RASEO_)?KeepOldFlags//;


      for(split/\s*\+|\s+/,$Flags) {
         next unless $_;

	 if (defined(&$_)) {
	   $newFlags |= &$_;
	 } elsif (defined &{"RASEO_$_"}) {
	   $newFlags |= &{"RASEO_$_"};
	 } elsif (/^-(.+)$/ && defined &$1) {
	   $newFlags = $newFlags ^ ($newFlags & &$1);
	 } elsif (/^-(.+)$/ && defined &{"RASEO_$1"}) {
	   $newFlags = $newFlags ^ ($newFlags & &{"RASEO_$1"});
	 } else {
	   RASCROAK "wrong flag specified `$_'";
	 }
      }
   } else {
      $newFlags = $dwfOptions;
   }

#print "$newFlags, $dwCountryID, $dwCountryCode, $szAreaCode, $szLocalPhoneNumber,
#$ipaddr, $ipaddrDns, $ipaddrDnsAlt, $ipaddrWins, $ipaddrWinsAlt,
#$dwFrameSize, $dwfNetProtocols, $dwFramingProtocol, $szScript\n";#exit;

# pack new header
   my $newHead = pack "LLLLa".(RAS_MaxAreaCode+1).
    "a".(RAS_MaxPhoneNumber+1)."La4a4a4a4a4LLL".(("a".MAX_PATH) x 3).
    "a".(RAS_MaxDeviceType + 1)."a".(RAS_MaxDeviceName + 1), (
   $dwSize,
   $newFlags,          # +4

   $dwCountryID,         # +8
   $dwCountryCode,       # +12
   $szAreaCode,          # +16
   $szLocalPhoneNumber,
   $dwAlternateOffset,

   $ipaddr,
   $ipaddrDns,
   $ipaddrDnsAlt,
   $ipaddrWins,
   $ipaddrWinsAlt,

   $dwFrameSize,
   $dwfNetProtocols,
   $dwFramingProtocol,
   $szScript,

   $szAutodialDll,
   $szAutodialFunc,

   $szDeviceType,
   $szDeviceName);

   substr($RASENTRY, 0, length $newHead) = $newHead;
   $RASENTRY;
}

=item RasChangePhoneNumber ( )

This is a simplified version of the C<RasSetEntryProperties()>.

 RasChangePhoneNumber($entry, $new_phone_number);

 $entry             - name of RAS/DUN entry
 $new_phone_number  - fully qualified phone number of the remote
                      computer in almost any human-readable form.

For example:

 '7-095-5555555' or '7(095)5555555' or '7 -( 095)-555-5555'
 or '+7 (095) - 5-5-5-5-5-5-5' or '7 095 5555555'

It is smart enough to adjust entry flags to avoid long distance dialing if
country and area codes are the same as in Dialing Properties/Default Location.
All other flags are kept unchanged.

B<Note!> country code here is not TAPI C<countryID>.

=cut

#=======================
sub RasChangePhoneNumber ($$) {
#=======================
# full country-code-area-code-local in the form
  my ($entry, $phone) = @_;
  $LastError = 0;

  TAPIlineGetTranslateCaps()
    unless defined($LOCAL_ID) && defined($LOCAL_CODE) && defined($LOCAL_AREA);

  my $props = {};
  $props->{name} = $entry;

  ($props->{CountryCode}, $props->{AreaCode}, $props->{LocalPhoneNumber}) =
  $phone =~
  /(\d+)(?:[+\- ]*\( *|[+\- ]+)(\d+)(?: *\)[+\- ]*|[+\- ]+)(\d[\d\-]+\d)/ or
	RASCROAK "wrong number `$phone'";

  if ($props->{AreaCode} eq $LOCAL_AREA && $props->{CountryCode} eq $LOCAL_CODE) {
    $props->{newFlags} = 'KeepOldFlags  -UseCountryAndAreaCodes';
  } else {
    $props->{newFlags} = 'KeepOldFlags  +UseCountryAndAreaCodes';
  }

  my $ret = RasSetEntryProperties($props) or return;
  1;
}


=pod

=back

B< =====================================>

B< CONNECTION RELATED FUNCTIONS>

B< =====================================>


=over 4

=item RasEnumConnections ( )

 %connections = RasEnumConnections ( );  or as list

 ($entry1, $hrasconn1, ...) = RasEnumConnections ( );

Returns handles for each active RAS/DUN connection. C<$entry> is entry-name.
C<$hrasconn> is a numeric handle that might be used in C<RasHangUp()> to
hang up the active connection or in C<RasGetConnectStatus()> or in
C<RasGetProjectionInfo()>.

Croaks on errors. Returns FALSE if no one active connection was found.

Note that C<RasDial()> also returns $hrasconn on success.

=cut

#================
sub RasEnumConnections () {
#================
   my ($dwSize, $hrasconn, $szEntryName, $szDeviceType, $szDeviceName);
   $LastError = 0;

   $RasEnumConnections ||= new("rasapi32", "RasEnumConnections", [P,P,P], N);

   $dwSize = 4+4+(RAS_MaxEntryName+1)+
      ($WINVER >= 0x400 ? RAS_MaxDeviceType+1 + RAS_MaxDeviceName+1 : 0);

   DWORD_ALIGN($dwSize);

   my $RASCONN =  pack "LLa".($dwSize-8), ($dwSize, 0, "");

   my ($lpcb, $lpcConnections) =
      (pack ("L", length $RASCONN), DWORD_NULL);

   my $ret = $RasEnumConnections->Call($RASCONN, $lpcb, $lpcConnections);

   my $cb = unpack "L",$lpcb;

   if ($ret) {
      $RASCONN =  pack "LLa".($cb-8), ($dwSize, 0, "");
      $ret = $RasEnumConnections->Call($RASCONN, $lpcb, $lpcConnections);
   }

   $ret and RASERROR($ret);

   my $conns = unpack "L",$lpcConnections;

   my %connects;

   for my $i(1..$conns) {
      my $buffer  = substr $RASCONN, $dwSize*($i-1), $dwSize;
      ($dwSize, $hrasconn, $szEntryName) =
        unpack "LL". "a".($dwSize-8), $buffer;
      CRUNCH($szEntryName);
      $connects{$szEntryName} = $hrasconn;
   }
   %connects;
}

=item RasGetProjectionInfo ( )

In the current version projection info is implemented for IP protocol only.
This is a subject to change.

 ($ip, $server_ip) = RasGetProjectionInfo ( $hrasconn );

 $hrasconn  - handle of the active connection returned by either
              RasDial() or RasEnumConnections().
 $ip        - the client's IP address on the RAS connection
 $server_ip - the IP address of the remote PPP peer (that is, the
              server's IP address)

Both IP addrs are in "nnn.nnn.nnn.nnn" form.


B<From the API docs:>

Remote access projection is the process whereby a remote access server
and a remote client negotiate network protocol-specific information.
A remote access server uses this network protocol-specific information
to represent a remote client on the network.

B<Windows NT:> Remote access projection information is not available until
the operating system has executed the C<RasDial> C<RASCS_Projected> state on the
remote access connection. If C<RasGetProjectionInfo()> is called prior to the
C<RASCS_Projected> state, it returns C<ERROR_PROJECTION_NOT_COMPLETE>.

B<Windows 95:> Windows 95 Dial-Up Networking does not support the
C<RASCS_Projected> state. The projection phase may be done during the
C<RASCS_Authenticate> state. If the authentication is successful, the connection
operation proceeds to the C<RASCS_Authenticated> state, and projection information
is available for successfully configured protocols. If C<RasGetProjectionInfo()>
is called prior to the C<RASCS_Authenticated> state, it returns
C<ERROR_PROTOCOL_NOT_CONFIGURED>.

PPP does not require that servers provide this address, but Windows NT
servers will consistently return the address anyway. Other PPP vendors
may not provide the address. If the address is not available, this member
returns an empty string ("").

I guess the last note is probably outdated because my Advanced Dialer
has a field for "Server's IP address" - so, it expects that it's always available.

If you are using C<Win32::RASE> in a single process application you can't
monitor C<RASCS_*> states (for more info look at C<RasGetConnectStatus()>).
So, the rule is: use this function after C<RasDial()> successfully
returned C<$hrasconn>.

The typical usage if you have only one connection is:

  unless ( $hrasconn = (RasEnumConnections())[1] ) {
	 print "Dialing sequence not started\n";

  } elsif ( ($ip, $server_ip) = RasGetProjectionInfo( $hrasconn ) ) {
	 print "LOCAL:$ip  SERVER:$server_ip\n";

  } elsif ( Win32::RASE::GetLastError == 731 ) {
	 print "Protocol not configured yet\n";

  } else {
	 die Win32::RASE::FormatMessage();
  }

Note also that LastError=6  means that C<$hrasconn> is an invalid handle.

Command line syntax:

 perl -MWin32::RASE -e "$,=', ';print RasGetProjectionInfo((RasEnumConnections)[1])"

=cut

#================
sub RasGetProjectionInfo ($) {
#================
  my $hrasconn = shift;
  my ($RASPPPIP, $dwSize, $lpcb, $dwError, $ip, $server_ip, $ret);
  my $rasprojection = RASP_PppIp;
  $LastError = 0;

  $RasGetProjectionInfo ||= new("rasapi32", "RasGetProjectionInfo",[N,N,P,P],N);

  if ($rasprojection == RASP_PppIp) {
    $dwSize = 4+4+RAS_MaxIpAddress+1+RAS_MaxIpAddress+1;

    DWORD_ALIGN($dwSize);

    $RASPPPIP =  pack "La".($dwSize-4), $dwSize, "";
    $lpcb = pack "L", $dwSize;

    $ret = $RasGetProjectionInfo->Call(
	 $hrasconn, $rasprojection, $RASPPPIP, $lpcb)
	 and ($LastError = $ret, return);

    ($dwSize, $dwError, $ip, $server_ip) =
	 unpack "LL"."a".(RAS_MaxIpAddress+1)."a".(RAS_MaxIpAddress+1), $RASPPPIP;
      CRUNCH($ip, $server_ip);

    $dwError and ($LastError = $dwError, return);

    return ($ip, $server_ip);
  }

}

=item RasHangUp ( )

 RasHangUp($hrasconn [, $timeout]);

 $hrasconn  - handle of the active connection returned by either
              RasDial() or RasEnumConnections().

 $timeout   - in sec, optional (3 sec by default). Maximum time to wait
              for graceful disconnection. You can use float values if
	      Time::HiRes is installed. Otherwise cycle uses sleep(1)
              and thus wastes some additional time.

This function gracefully terminates the connection. You don't need to add any
C<sleep> after it.

The connection is terminated even if the C<RasDial()> call has not yet been completed.

After this call, the $hrasconn handle can no longer be used.

Returns FALSE if invalid handle was given but this is harmless
most of the time. Probably the connection failed itself and C<$hrasconn>
is not valid any more. So, you don't have to trap this error.

Returns FALSE on timeout also (connection might be still active). LastError
is 0 in this case. So the exact logic is:

  if ( RasHangUp($hrasconn, $timeout) ) {
	 print "Connection is terminated successfully.\n";

  } elsif ( !Win32::RASE::GetLastError ) {
	 print "Timeout. Connection is still active.\n";

  } else {
	 # we don't have to die here
	 warn Win32::RASE::FormatMessage(), "\n";
  }

For more take a look at the API docs.

=cut

#================
sub RasHangUp ($;$) {
#================
# returns 0 on success or error-code
   my ($hrasconn, $timeout) = @_;
   $LastError = 0;
   ($LastError = 6, return) unless $hrasconn && $hrasconn !~ /\D/;

   $RasHangUp ||= new("rasapi32", "RasHangUp", [N], N);

   $timeout ||= 3;

   my ($delay) = $Time_HiRes_loaded ? 0.1 : 1;

   my $ret = $RasHangUp->Call($hrasconn);

   $ret and ($LastError = $ret, return);

   my $starttime = time;

   while ($starttime + $timeout >= time) {
      RasGetConnectStatus($hrasconn) or ($LastError = 0, return 1);

      sleep $delay;
   }

   return;
}

=item HangUp ( )

This is the easier version of previous.

Without parameters it will terminate all active connections, otherwise
terminates connections by B<entry-names> given as parameters. Note that
this function uses entry-names, not handles.

 $code = HangUp ( [$entry1, ...] );

Returns FALSE if at least one connection was not terminated gracefully,
otherwise TRUE even if no one active connecton was found.

Command line syntax:

 perl -MWin32::RASE -e HangUp


=cut

#================
sub HangUp (;@) {
#================
   $LastError = 0;
   my %conns = RasEnumConnections() or return 1;
   my @entries = @_;
   my $ret = 1;
   local $_;

   @entries = keys %conns unless @entries;

   for (@entries) {
      next unless exists $conns{$_};

      RasHangUp($conns{$_}) or $ret = 0;
   }
   $ret;
}

=item RasGetConnectStatus ( )

This function is used to monitor active connection in progress. In most
cases it's good to cycle calls to this function after a very small interval,
say 0.1 sec or less - at least at the dialing time. It's possible in
multithreading process (thread safety is not verified in this version)
or one process can monitor another, which is closer to perl practice.

  $status = RasGetConnectStatus($hrasconn);

or

  ($status, $status_text) = RasGetConnectStatus($hrasconn);

  $hrasconn - handle to active RAS/DUN connection

In scalar context returns numeric status (RASCS_* enumerator values) or
FALSE if C<$hrasconn> is not a valid handle (LastError is set to 6).

In list context returns numeric status and the string that characterizes
this status in short (the descriptive part of the corresponding RASCS_ constant's
name, like "OpenPort") or FALSE if handle is invalid.

FALSE is also returned if handle is "not valid any more", i.e. connection
is terminated.

These string constants ("PortOpened" etc.) are stored in a non-exported hash
B<%Win32::RASE::RASCS> where the keys are numeric values of the corresponding RASCS_*
constants. So

 $Win32::RASE::RASCS{1} eq "PortOpened"

You can check status yourself against exported RASCS_* constants:

    RASCS_OpenPort
    RASCS_PortOpened
    RASCS_ConnectDevice
    RASCS_DeviceConnected
    RASCS_AllDevicesConnected
    RASCS_Authenticate
    RASCS_AuthNotify
    RASCS_AuthRetry
    RASCS_AuthCallback
    RASCS_AuthChangePassword
    RASCS_AuthProject
    RASCS_AuthLinkSpeed
    RASCS_AuthAck
    RASCS_ReAuthenticate
    RASCS_Authenticated
    RASCS_PrepareForCallback
    RASCS_WaitForModemReset
    RASCS_WaitForCallback
    RASCS_Projected
    RASCS_StartAuthentication    // Windows 95 only
    RASCS_CallbackComplete       // Windows 95 only
    RASCS_LogonNetwork           // Windows 95 only
    RASCS_SubEntryConnected
    RASCS_SubEntryDisconnected
    RASCS_Interactive  =  RASCS_PAUSED
    RASCS_RetryAuthentication
    RASCS_CallbackSetByCaller
    RASCS_PasswordExpired
    RASCS_Connected  = RASCS_DONE
    RASCS_Disconnected

B<From the API docs:>

The connection process states are divided into three classes: running states,
paused states, and terminal states. An application can easily determine the
class of a specific state by performing Boolean bit operations with the RASCS_PAUSED
and RASCS_DONE bitmasks. Here are some examples:

   $fDoneState = $status & RASCS_DONE;
   $fPausedState = $status & RASCS_PAUSED;
   $fRunState = !($fDoneState || $fPausedState);

=cut

#================
sub RasGetConnectStatus ($) {
#================
# dwError is sometimes 600
# values are in %RASCS
   my $hrasconn = shift;
   $LastError = 0;
   ($LastError = 6, return) unless $hrasconn && $hrasconn !~ /\D/;

   $RasGetConnectStatus ||= new("rasapi32", "RasGetConnectStatus", [N,P], N);

   my $dwSize = 4+4+4 + RAS_MaxDeviceType+1 + RAS_MaxDeviceName+1;

   DWORD_ALIGN($dwSize);

   my $RASCONNSTATUS = pack "La".($dwSize-4), ($dwSize, "");

   my ($ret, $dwError);
   $ret = $RasGetConnectStatus->Call($hrasconn, $RASCONNSTATUS);

   $ret == 6 and ($LastError = 6, return); # invalid handle

   $ret and RASERROR($ret);

   # don't know why do we need another error code if the function
   # itself returns one
   #$dwError = unpack L, substr($RASCONNSTATUS, 8,4) and RASERROR($dwError);

   my $status = unpack "L", substr($RASCONNSTATUS, 4,4);
   wantarray ? ($status, $RASCS{$status}) : $status;
}

=item RasDialDlg ( )

This function tries to establish a RAS connection using
a specified phonebook entry and the credentials of the logged-on user.
It displays a stream of dialog boxes that indicate the state of the connection
operation and returns when the connection is established,
or when the user cancels the operation. B<Windows NT only.>

 RasDialDlg( $EntryName [, $hwnd, $PhoneNumber] );

 $EntryName    - RAS/DUN entry, the only mandatory parameter
 $hwnd         - Identifies the window that owns the modal RasDialDlg
                 dialog boxes.
                 This member can be any valid window handle, or it can
                 be 0, undef (or omitted) if the dialog box has no owner

The dialog box is centered on the owner window unless C<$hwnd> is C<FALSE>
or invalid handle, in which case the dialog box is centered on the screen.

 $PhoneNumber  - an overriding phone number (if not needed - use "" or
                 undef).

It does not inherit anything from phonebook if specified - no prefix,
no callin card, no waiting.
You should even add DP before the number for pulse dialing.

Returns TRUE on success, FALSE if user selects "Cancel" button or an error occurs.
You can check the last case with C<Win32::RASE::GetLastError()>.

  if ( RasDialDlg("NEV4") ) {
	 print "Connection established\n";
  } elsif ( !Win32::RASE::GetLastError ) {
	 print "User selected <Cancel>\n";
  } else {
	 warn Win32::RASE::FormatMessage(), "\n";
  }

=cut

#================
sub RasDialDlg ($;$$) {
#================
   $LastError = 0;
   RASCROAK "this function works on NT only" unless Win32::IsWinNT;

   $RasDialDlg ||= new("rasdlg", "RasDialDlg", [P,P,P,P], N);

   my ($entry, $hwnd, $lpszPhoneNumber) = @_;
   my $dwSize = 36;

   $hwnd = 0 if $hwnd && !IsWindow($hwnd);

   my $RASDIALDLG = pack "LLa".($dwSize-8), ($dwSize, $hwnd||0, "");

   my $ret = $RasDialDlg->Call($PHONEBOOK||0,
	 $entry, $lpszPhoneNumber||0, $RASDIALDLG) and return 1;

   $LastError = unpack "L", substr($RASDIALDLG, 6*4,4);
   return;
}

=item RasDial ( )

This function establishes a RAS/DUN connection. The connection data includes
callback and user authentication information.

 $hrasconn = RasDial($EntryName, $PhoneNumber, $UserName, $Password,
                      $Domain, $CallbackNumber);

 $EntryName   - RAS/DUN entry, the only mandatory parameter
 $PhoneNumber - an overriding phone number (if not needed - use "" or
                undef).
                
It does not inherit anything from the phonebook if specified -
no prefix, no calling card, no waiting.
You should add DP before the number for pulse dialing.

 $UserName    - user's user name (look below)
 $Password    - user's password
 $Domain      - domain on which authentication is to occur. An empty
      string ("" or undef) specifies the domain in which the remote
      access server is a member (NT only). An asterisk specifies the
      domain stored in the phonebook for the entry.
      It's in addr form (size is limited to 15 chars).
 $CallbackNumber - a callback phone number. An empty string ("") or
      undef indicates that callback should not be used. This string is
      ignored unless the user has "Set By Caller" callback permission
      on the RAS server (NT only). An asterisk indicates that the number
      stored in the phonebook should be used for callback.

B<Windows NT:>
[These 2 paragraphs are copied from the API docs. I wanted to add this
for some completeness but I was told that probably this is not truth and if
Username or Password are empty user will get a dialog box with Username/Password
prompts.]

RAS does not actually log the user onto the network. The user does this in the usual
manner, for example, by logging on with cached credentials prior to making the
connection or by using CTRL+ALT+DEL, after the RAS connection is established.

If both the UserName and Password members are empty strings (""), RAS uses the
user name and password of the current logon context for authentication. For a user
mode application, RAS uses the credentials of the currently logged-on interactive user.
For a Win32 service process, RAS uses the credentials associated with the service.

B<Windows 95:>

RAS uses the UserName and Password strings to log the user onto the network.
Windows 95 cannot get the password of the currently logged-on user, so if both
the UserName and the Password members are empty strings ("" or undef), RAS leaves
the user name and password empty during authentication. I.e. it provides no
additional search (look at C<RasGetEntryDialParams()> for that).


B<Note:> It seems that overriding phone number is being dialed "as is" - without using
any long-distance/international phone settings. So you have to provide this number
with all prefixes and waitings (W etc.) if needed. Additional
dashes, blanks and brackets are OK.

 $hrasconn  - on success - handle to active RAS/DUN connection,
              otherwise undef


You can use C<$hrasconn> in C<RasGetConnectStatus()> or C<RasHangUp()>.
Note that this function calls C<RasHangUp()> internally on error, so after that,
the handle of the failed connection is not available and the port is ready
for the next try.

B<Example:>

  ($err, $errtext) = RasDial("CLICK",undef,"ppblazer","qwerty");
  if ($err) {
     print "$err, $errtext\n"; exit;
  } else {
     ... your work here ...
  }

B<Last note:> this is the B<synchronous> operation. Nobody knows if it could really
hang fast enough if the line is busy (for ex.) The best way would be to run C<RasDial()>
in the separate process or thread. In most cases you don't really need C<$hrasconn>
in the main process - you can terminate the connection at any time with C<HangUp()>.
Or you can easily get C<$hrasconn> with the use of C<RasEnumConnections()>.

If you run C<RasDial()> in a child-process and terminate dialing in progress (for ex.
on timeout) you have to free the port yourself (C<RasHangUp()> or C<HangUp()>).

For more info take a look at Win32 API docs (RASDIALPARAMS etc).

Command line syntax:

 perl -MWin32::RASE -e RasDial(NEV1,undef,ppblazer,'6hTR7dwA')
 perl -MWin32::RASE -e "RasDial(NEV1,undef,ppblazer,'6hTR7dwA') or print Win32::RASE::FormatMessage"
 perl -MWin32::RASE -e "print RasDial(NEV1,undef,ppblazer,'6hTR7dwA')||Win32::RASE::FormatMessage"

=cut

#================
sub RasDial ($;$$$$$) {
#================
   my ($szEntryName, $szPhoneNumber, $szUserName,
       $szPassword, $szDomain, $szCallbackNumber) = @_;
   $LastError = 0;

   RASCROAK "entry-name and alt phone-number can't be both empty"
      unless $szEntryName || $szPhoneNumber;

   $RasDial ||= new("rasapi32", "RasDial", [P,P,P,N,P,P], N);

   my $dwSize = 4 + RAS_MaxEntryName + 1 + RAS_MaxPhoneNumber + 1 +
      RAS_MaxCallbackNumber + 1 + UNLEN + 1 + PWLEN + 1 + DNLEN + 1 +
      (Win32::IsWinNT && $WINVER >= 0x401 ? 4+4 : 0);

   DWORD_ALIGN($dwSize);

   my $RASDIALPARAMS =
      pack "La".(RAS_MaxEntryName + 1)."a".(RAS_MaxPhoneNumber + 1).
      "a".(RAS_MaxCallbackNumber + 1)."a".(UNLEN + 1).
      "a".(PWLEN + 1)."a".(DNLEN + 1)
      ,
      ($dwSize, $szEntryName||"", $szPhoneNumber||"", $szCallbackNumber||"",
       $szUserName||"", $szPassword||"", $szDomain||"");

   $RASDIALPARAMS .= "\0"x($dwSize - length $RASDIALPARAMS);

   my $lphRasConn = DWORD_NULL;
   my $ret = $RasDial->Call(0, $PHONEBOOK||0,
	 $RASDIALPARAMS, 0, 0, $lphRasConn);

   my $hrasconn = unpack "L", $lphRasConn;

   if ($ret) {
      RasHangUp($hrasconn) if $hrasconn;
      $LastError = $ret, return;
   } else {
      return $hrasconn;
   }
}


=pod

=back

B< =====================================>

B< TAPI RELATED FUNCTIONS>

B< =====================================>


=over 4

=item RasEnumDevices ( )

 %devices = RasEnumDevices();

This function returns the name and type of all available RAS-capable devices.
In the C<%devices> hash device names are keys and types are values. Common
device types are "modem", "x25", "vpn", "isdn", "rastapi" etc.

Croaks on errors. Returns FALSE if no one RAS capable device was found.

For example the first RAS-capable device name is

  $DeviceName = (RasEnumDevices())[0];

This function fills out a non-exported hash C<%Win32::RASE::RasDevEnumeration>
of the same structure as C<%devices>, so in most cases there is no need to call
this function more then once.

Command line syntax:

 perl -MWin32::RASE -e "print ((RasEnumDevices)[0])"

=cut

#================
sub RasEnumDevices () {
#================
   $LastError = 0;
   $RasEnumDevices ||= new("rasapi32", "RasEnumDevices",[P,P,P],N);

   my $dwSize = RAS_MaxDeviceType+1+RAS_MaxDeviceName+1+4;

   DWORD_ALIGN($dwSize);

   my $RASDEVINFO = pack "La".(10*$dwSize-4), ($dwSize, ""); # 10 devices initially

   my ($lpcb, $lpcDevices) = (pack("L",length $RASDEVINFO), DWORD_NULL);

   my $ret = $RasEnumDevices->Call($RASDEVINFO, $lpcb, $lpcDevices);

   if ($ret) {
      my $b = unpack "L",$lpcb;
      $RASDEVINFO = pack "La".($b-4), ($dwSize, "");
      $ret = $RasEnumDevices->Call($RASDEVINFO, $lpcb, $lpcDevices);
   }

   $ret and RASERROR($ret);

   my %devices;

   for my $i(1..unpack "L",$lpcDevices) {
      my $buffer  = substr $RASDEVINFO, ($dwSize*($i-1)), $dwSize;
      my ($dwSize1, $szDeviceType, $szDeviceName) =
        unpack "La".(RAS_MaxDeviceType+1)."a".(RAS_MaxDeviceName+1), $buffer;

      CRUNCH($szDeviceType, $szDeviceName);
      $devices{$szDeviceName} = $szDeviceType;
   }
   %RasDevEnumeration = %devices;
}

=item RasEnumDevicesByType ( )

The easier version of previous.

  @DevNames = RasEnumDevicesByType( $devtype );

Returns names of RAS-capable devices of type C<$devtype>. For example
the first modem's name

  $ModemName = (RasEnumDevicesByType("modem"))[0];

C<$devtype> is case insensitive.

=cut

#=============================
sub RasEnumDevicesByType ($) {
#=============================
  my $type = shift;
  %RasDevEnumeration  = RasEnumDevices() unless defined %RasDevEnumeration;

  grep {lc($RasDevEnumeration{$_}) eq lc($type)} keys %RasDevEnumeration;
}

=item TAPIlineGetTranslateCaps ( )

This function is not exported and is not intended for public use.
It is called each time you load Win32::RASE and fills out 3 global variables
and global hash (below).

It takes local information from your dialup settings.

 ($countryID, $countryCode, $areaCode) =
    Win32::RASE::TAPIlineGetTranslateCaps ();

The return values are describing the B<Current Location> that is selected
in you dialing properties.

 $countryID  -  the unique number that TAPI assigns to each country.
                It is not what you are typing on your phone, though it
                sometimes has the same value. Different countries always
                have different countryID. This allows multiple entries
                to exist in the country list with the same country code
                (for example, all countries in North America and the
                Caribbean share country code 1, but require separate
                entries in the list).

 $countryCode - this really is the code that would be dialed in an
	        international call to your computer's location.

 $areaCode    - city or area code (local).

These 3 values are copied to non-exported global variables
B<$Win32::RASE::LOCAL_ID>, B<$Win32::RASE::LOCAL_CODE> and
B<$Win32::RASE::LOCAL_AREA>.

They are mainly for internal use, just note that they are here.

The complete TAPI countries list is being copied to non-exported global hash
B<%Win32::RASE::TAPIEnumeration>. Keys are countryID's, each value points
to 3-element array: [0] is country-name, [1] is countryCode described above,
[2] is NextCountryID in TAPI-enumeration (TAPI docs, but in most cases you
don't need to use this hash explicitly).

Use C<TAPIEnumerationPrint()> to print this hash (for fun ;)

=cut

#================
sub TAPIlineGetTranslateCaps () {
#================
  $LastError = 0;
  my ($CurrentLocation, %locations) = TAPIEnumLocations();
  ($LOCAL_ID, $LOCAL_CODE, $LOCAL_AREA) = @{$locations{$CurrentLocation}}[0,1,2];

  IsCountryID($LOCAL_ID) or
    RASCROAK "TAPI could not find your local settings\nPlease, contact the author of this module.";

  TAPICountryCode($LOCAL_ID) == $LOCAL_CODE and $LOCAL_AREA !~ /\D/ or
    RASCROAK "TAPI-error. Please adjust your dialing properties.";

  ($LOCAL_ID, $LOCAL_CODE, $LOCAL_AREA);
}

=item TAPIEnumLocations ( )

Just a handy function (non-exported) to enumerate locations in your Dialing Properties.
It's being executed internally when Win32::RASE needs it, so in most cases you don't
need to use it explicitly.

  ($CurrentLocation, %locations) = Win32::RASE::TAPIEnumLocations;

  $CurrentLocation   - current dialing location's name
  %locations         - keys are location-names, values are anonymous
                       arrays that are filled out like:
     [$CountryID, $CountryCode, $CityCode, $Options, $LocalAccessCode,
      $LongDistanceAccessCode, $TollPrefixList, $PermanentLocationID]

  $Options                - 0/1 tone/pulse dialing, this value could be
                            used to define good timeout for RasDial()
  $LocalAccessCode        - the access code to be dialed before calls to
                            addresses in the local calling area
  $LongDistanceAccessCode - the access code to be dialed before calls to
                            addresses outside the local calling area
  $TollPrefixList         - the toll prefix list for the location. The
                            string will contain only prefixes consisting
                            of the digits "0" through "9", separated
                            from each other by a single comma
  $PermanentLocationID    - internal unique identifier of the location

Other values in array are described in C<TAPIlineGetTranslateCaps()>.

B<Example:>

 ($CurrentLocation, %locations) = Win32::RASE::TAPIEnumLocations;
 print "$CurrentLocation\n";
 print map "$_ => [".(join", ",@{$locations{$_}})."]\n",
     keys %locations;


=cut

#================
sub TAPIEnumLocations () {
#================
   $LastError = 0;
   my ($dwTotalSize, $dwNeededSize, $dwUsedSize, $dwNumLocations,
       $dwLocationListSize, $dwLocationListOffset, $dwCurrentLocationID,
       $dwNumCards, $dwCardListSize, $dwCardListOffset, $dwCurrentPreferredCardID);
   my ($dwPermanentLocationID, $dwLocationNameSize, $dwLocationNameOffset,
       $dwCountryCode, $dwCityCodeSize, $dwCityCodeOffset, $dwPreferredCardID,
       $dwLocalAccessCodeSize, $dwLocalAccessCodeOffset, $dwLongDistanceAccessCodeSize,
       $dwLongDistanceAccessCodeOffset, $dwTollPrefixListSize, $dwTollPrefixListOffset,
       $dwCountryID, $dwOptions, $dwCancelCallWaitingSize, $dwCancelCallWaitingOffset);
   my (%locations, $CityCode, $LocationName, $CurrentLocation, $LocalAccessCode,
       $LongDistanceAccessCode, $TollPrefixList);
   $dwTotalSize = 4*11;

   $lineGetTranslateCaps ||= new("tapi32", "lineGetTranslateCaps", [N,N,P], N);

   my $LINETRANSLATECAPS = pack "La".($dwTotalSize-4), ($dwTotalSize, "");

   my $ret = $lineGetTranslateCaps->Call(0, 0x10004, $LINETRANSLATECAPS);

   $ret and RASERROR($ret);

   ($dwNeededSize, $dwUsedSize) = unpack "LL", substr($LINETRANSLATECAPS, 4);

   $LINETRANSLATECAPS = pack "La".($dwNeededSize-4), ($dwNeededSize, "");

   $ret = $lineGetTranslateCaps->Call(0, 0x10004, $LINETRANSLATECAPS);

   $ret and RASERROR($ret);

   ($dwNeededSize, $dwUsedSize, $dwNumLocations,
    $dwLocationListSize, $dwLocationListOffset, $dwCurrentLocationID,
    $dwNumCards, $dwCardListSize, $dwCardListOffset, $dwCurrentPreferredCardID) =
   unpack "LLLLLLLLLL", substr($LINETRANSLATECAPS, 4);

  for my $i(0..$dwNumLocations-1) {
     ($dwPermanentLocationID, $dwLocationNameSize, $dwLocationNameOffset,
      $dwCountryCode, $dwCityCodeSize, $dwCityCodeOffset, $dwPreferredCardID,
      $dwLocalAccessCodeSize, $dwLocalAccessCodeOffset, $dwLongDistanceAccessCodeSize,
      $dwLongDistanceAccessCodeOffset, $dwTollPrefixListSize, $dwTollPrefixListOffset,
      $dwCountryID, $dwOptions, $dwCancelCallWaitingSize, $dwCancelCallWaitingOffset) =
     unpack "LLLLLLLLLLLLLLLLL",
      # 4*17 - sizeof(LINELOCATIONENTRY)
      substr($LINETRANSLATECAPS, $dwLocationListOffset+$i*4*17);

     $LocationName           = substr($LINETRANSLATECAPS, $dwLocationNameOffset, $dwLocationNameSize);
     $CityCode               = substr($LINETRANSLATECAPS, $dwCityCodeOffset, $dwCityCodeSize);
     $LocalAccessCode        = substr($LINETRANSLATECAPS, $dwLocalAccessCodeOffset, $dwLocalAccessCodeSize);
     $LongDistanceAccessCode = substr($LINETRANSLATECAPS, $dwLongDistanceAccessCodeOffset, $dwLongDistanceAccessCodeSize);
     $TollPrefixList         = substr($LINETRANSLATECAPS, $dwTollPrefixListOffset, $dwTollPrefixListSize);

     CRUNCH($LocationName, $CityCode, $LocalAccessCode,
	    $LongDistanceAccessCode, $TollPrefixList);

     $locations{$LocationName} = [$dwCountryID, $dwCountryCode, $CityCode, $dwOptions,
       $LocalAccessCode, $LongDistanceAccessCode, $TollPrefixList, $dwPermanentLocationID];

     $CurrentLocation = $LocationName if $dwCurrentLocationID == $dwPermanentLocationID;
  }

  ($CurrentLocation, %locations);
}

=item TAPISetCurrentLocation ( )

  TAPISetCurrentLocation( $location );

  $location   - optional, the name of the location that is configured
                in the Dialing Properies.
                If omitted the "Default Location" is used.

Returns TRUE on success, FALSE if C<$location> was not found in the
Dialing Properties, croaks on TAPI errors.

=cut

#================
sub TAPISetCurrentLocation (;$) {
#================
  $LastError = 0;
  my $location = shift || "Default Location";
  $location =~ s/^ *(.*?) *$/$1/;
  my ($CurrentLocation, %locations) = TAPIEnumLocations();
  my $ret;

  exists($locations{$location}) or return;

  $lineSetCurrentLocation ||= new("tapi32", "lineSetCurrentLocation", [N,N], N);

  my $dwLocation = $locations{$location}->[7];

  my $hLineApp = TAPIlineInitialize();

  $ret = $lineSetCurrentLocation->Call($hLineApp, $dwLocation) and
	(TAPIlineShutdown($hLineApp), RASERROR($ret));


  $ret = TAPIlineShutdown($hLineApp) and RASERROR($ret);
  1;
}

#================
sub RasGetCountryInfo ($) {
#================
   $RasGetCountryInfo ||= new("rasapi32", "RasGetCountryInfo", [P,P], N);

   my $dwCountryId = shift;
   my $dwSize  = 20;
   my $SizeBuf = 256;
   my $RASCTRYINFO = pack "LLa".($SizeBuf-8), ($dwSize, $dwCountryId, "");

   my $dwSizeBuf = pack "L", $SizeBuf;
   my $ret       = $RasGetCountryInfo->Call($RASCTRYINFO, $dwSizeBuf);

   if ($ret == 603) {
       $SizeBuf   = unpack "L", $dwSizeBuf;
       $RASCTRYINFO = pack "LLa".($SizeBuf-8), ($dwSize, $dwCountryId, "");
       $ret = $RasGetCountryInfo->Call($RASCTRYINFO, $dwSizeBuf) and RASERROR($ret);
   }

   $ret and RASERROR($ret);

   my ($dwNextCountryID, $dwCountryCode, $dwCountryNameOffset) =
	 unpack "x8 LLL", $RASCTRYINFO;
   my $Country = substr $RASCTRYINFO, $dwCountryNameOffset;

   CRUNCH($Country);

   ($Country, $dwCountryCode, $dwNextCountryID);
}

#================
sub TAPIEnumCountries () {
#================
   my $dwCountryId = 1;
   my ($Country, $dwCountryCode, $dwNextCountryID, %cou);

   do {
      ($Country, $dwCountryCode, $dwNextCountryID) = RasGetCountryInfo($dwCountryId);
      $cou{$dwCountryId} = [$Country, $dwCountryCode, $dwNextCountryID];
      $dwCountryId = $dwNextCountryID;
   } until $dwNextCountryID == 0;
   %cou;
}

=item TAPIEnumerationPrint ( )

This function prints nicely formatted TAPI countries table that is stored in
the B<%Win32::RASE::TAPIEnumeration> (see above). Not exported by default;

    Win32::RASE::TAPIEnumerationPrint();

Columns: CountryID, CountryName, CountryCode, NextCountryID

For more: C<TAPIlineGetTranslateCaps()> and TAPI docs.

Always returns TRUE.

=cut

#================
sub TAPIEnumerationPrint () {
#================
   my $maxlen = 0;
   local $_;
   $LastError = 0;

   %TAPIEnumeration = TAPIEnumCountries() if !defined %TAPIEnumeration;

   for (keys %TAPIEnumeration) {
     $maxlen = length($TAPIEnumeration{$_}->[0])
       if $maxlen < length $TAPIEnumeration{$_}->[0];
   }

   printf "%9s%".($maxlen-6)."s%16s  %6s\n\n", "CountryID", "CountryName",
     "CountryCode", "NextID";

   map { printf "%6d  %${maxlen}s %6d %6d\n", $_, $TAPIEnumeration{$_}->[0],
     $TAPIEnumeration{$_}->[1], $TAPIEnumeration{$_}->[2]} sort keys %TAPIEnumeration;
   1;
}

=item TAPICountryName ( )

Returns CountryName by CountryID or FALSE if given CountryID does not
exist in TAPI-table.

   $CountryName = TAPICountryName($CountryID);

Command line syntax:

 perl -MWin32::RASE -e "print TAPICountryName(1)"

=cut

#================
sub TAPICountryName ($) {
#================
   my $CountryID = shift;
   $LastError = 0;

   %TAPIEnumeration = TAPIEnumCountries() if !defined %TAPIEnumeration;
   exists($TAPIEnumeration{$CountryID}) ? $TAPIEnumeration{$CountryID}->[0] : undef;
}

=item TAPICountryCode ( )

Returns CountryCode by CountryID or FALSE if given CountryID does not
exist in TAPI-table.

   $CountryCode = TAPICountryCode($CountryID);

=cut

#================
sub TAPICountryCode ($) {
#================
   my $CountryID = shift;
   $LastError = 0;

   %TAPIEnumeration = TAPIEnumCountries() if !defined %TAPIEnumeration;
   exists($TAPIEnumeration{$CountryID}) ? $TAPIEnumeration{$CountryID}->[1] : undef;
}

=item IsCountryID ( )

Returns TRUE if given $CountryID exist in TAPI-table, otherwise FALSE.

   IsCountryID($CountryID);

Just to have such a pretty name ;)

=cut

#================
sub IsCountryID ($) {
#================
   my $CountryID = shift;
   $LastError = 0;

   %TAPIEnumeration = TAPIEnumCountries() if !defined %TAPIEnumeration;
   exists($TAPIEnumeration{$CountryID}) ? 1 : 0;
}

#======================
sub GetDefaultCommConfig ($) {
#======================
  my $dev = shift
    or RASCROAK "empty DeviceName";

  my $GetDefaultCommConfig = new("kernel32", "GetDefaultCommConfig", [P,P,P], N);

  my $lpCC     = "";
  my $lpdwSize = DWORD_NULL;

  my $ret = $GetDefaultCommConfig->Call($dev, $lpCC, $lpdwSize);
  my $dwSize = unpack "L", $lpdwSize;

  $lpCC = "\0"x$dwSize;
  $ret  = $GetDefaultCommConfig->Call($dev, $lpCC, $lpdwSize)
	 or ($LastError = Win32::GetLastError(), return);

  substr $lpCC, 0, $dwSize;
}

=item TAPIlineInitialize ( )

This is a non-exported function mainly for internal use. It could be handy only
if you'd start writing your own TAPI-related functions.

  ($hLineApp, $dwNumDevs) = Win32::RASE::TAPIlineInitialize();

or in scalar context

  $hLineApp = Win32::RASE::TAPIlineInitialize();

  $hLineApp  - the application's usage non-zero handle for TAPI
  $dwNumDevs - number of line devices available to the TAPI application

Croaks on TAPI errors.

The applicaton should always call C<TAPIlineShutdown()> to release memory
resources allocated by TAPI.DLL.

=cut

#================
sub TAPIlineInitialize () {
#================
  $LastError = 0;
  $lineInitialize ||= new("tapi32","lineInitialize",[P,N,P,P,P],N);

  # dll-instance
  #my $tapi32dll = $Win32::API::Libraries{"tapi32"};
  my $tapi32dll = $lineInitialize->{dll};

  my ($lphLineApp, $lpfnCallback, $lpdwNumDevs) =
	(DWORD_NULL, DWORD_NULL, DWORD_NULL);

  my $ret;
  $ret = $lineInitialize->Call($lphLineApp,
	$tapi32dll, $lpfnCallback, "Win32::RASE v.$VERSION\0", $lpdwNumDevs)
	and RASERROR($ret);

  my $hLineApp  = unpack "L", $lphLineApp;
  my $dwNumDevs = unpack "L", $lpdwNumDevs;

  wantarray ? ($hLineApp, $dwNumDevs) : $hLineApp;
}

=item TAPIlineShutdown ( )

This is a non-exported function mainly for internal use. It could be handy only
if you'd start writing your own TAPI-related functions.

  Win32::RASE::TAPIlineShutdown($hLineApp);

  $hLineApp  - the application's usage handle for TAPI

Returns zero if the request is successful or a negative error number
if an error has occurred.

=cut

#================
sub TAPIlineShutdown ($) {
#================
  $LastError = 0;
  $lineShutdown ||= new("tapi32","lineShutdown",[N],N);
  $lineShutdown->Call(shift);
}


# from RegExps.pm
sub OCTET      {'(?:1\d\d|2[0-4]\d|25[0-5]|[1-9]\d?|0)'}
sub HOSTNUMBER {'(?:(?:'.OCTET.'\.){3}'.OCTET.'\.?)'}


1;

__END__

=back

=head1 INSTALLATION

As this is just a plain module no special installation is needed. Put it
into the Win32 subdirectory somewhere in your @INC.

This module needs Windows Remote Access Service (RAS) or DialUp Networking (DUN)
to be properly installed including dialing properties.

rasapi32.dll, tapi32.dll

Win32::API module by Aldo Calpini.

enum.pm (1.014 or later, no compilations) by Byron Brummer (aka Zenin)

Time::HiRes (0.18 or later) by Douglas E. Wegscheid makes work more precise.

=head1 CAVEATS

This module has been created and tested in a Win95 environment.  Although
I expect it to function correctly on any version of Windows NT, that fact
has been confirmed for NT 4.0 build 1381 only.

Some of the RAS APIs were not included in the RasAPI32.dll that was shipped with
the old releases of Windows 95. To use the RAS APIs mentioned here, you need to install the
at least Dial Up Networking (DUN) 1.2b upgrade.
This upgrade is available for download on:

http://www.microsoft.com/windows/downloads/contents/Updates/W95DialUpNetw/default.asp

This upgrade was incorporated in Win95 OSR.

From the B<MS KB# Q157765>: Early releases of Windows 95 may require
an additional RNAPH.DLL that
contains some of new phonebook manipulation APIs. There currently is no
workaround for this situation in this version of the module.

Some APIs may also not work properly on WinNT with old Service Packs. Make sure that
you are using the last Service Pack available.
List of Bugs Fixed in Windows NT 4.0 Service Pack 1, 2, and 3
is available at

http://support.microsoft.com/support/kb/articles/q224/7/92.asp

What can we do here, guys? That's how it goes...

=head1 CHANGES

 1.00  First public release
 1.01  The only thing touched is Makefile.PL. The distribution is packed
       now using UNIX conventions (LF only, unlike the 1.00 dist)

=head1 TODO

NT-only API: RasGetCredentials, RasSetCredentials, RasMonitorDlg, RasPhonebookDlg.

Any suggestions are much appreciated.

=head1 BUGS

Please report.

=head1 VERSION

This man page documents "Win32::RASE" version 1.01.

January 19, 2000.

=head1 CREDITS

Thanks to Carl Sewell C<<>csewell@hiwaay.netC<>> for his great help
and patience in testing on NT. If these docs are more or less readable -
it's due to his corrections and improvement.

Thanks to Jan Dubois C<<>jan.dubois@ibm.netC<>> for numerous great tips
and explanations.

Guys, you are cool! ;)

=head1 AUTHOR

Mike Blazer, blazer@mail.nevalink.ru

http://www.dux.ru/guest/fno/perl/

=head1 SEE ALSO

Win32 SDK, TAPI docs.

=head1 COPYRIGHT

Copyright (C) 1999 Mike Blazer.

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

