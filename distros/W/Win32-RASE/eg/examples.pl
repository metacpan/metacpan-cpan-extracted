#!/usr/bin/perl -w
#
# This is an exit-separated collection of tests to Win32::RASE module
# move one of the tests on top to run
#
#

$|=1;

use Win32::RASE;


#----------- printing device properties ---------------
RasPrintEntryProperties("MY_ENTRY");
exit;
#----------- printing device properties ---------------
$modem_name = (RasEnumDevicesByType("modem"))[0] or
  die "No one \"$type\" device were found\n";
$CC = Win32::RASE::GetDefaultCommConfig($modem_name);
print length $CC;
exit;

#----------- test of RasSetEntryProperties ---------------
# please try also with "vpn" if you have MS Virtual Private Network installed
$entry = "MY_ENTRY";
$type = "modem";

$modem_name = (RasEnumDevicesByType($type))[0] or
  die "No one \"$type\" device were found\n";

print "First device of type \"$type\": \"$modem_name\"\n\n";
RasSetEntryProperties({
 name             => $entry,
 CountryCode      => "7",
 AreaCode         => "812",
 LocalPhoneNumber => "325-52-95",
 DeviceName       => $modem_name,
 newFlags         => "+KeepOldFlags -UseCountryAndAreaCodes",
 })
 or die Win32::RASE::FormatMessage;

print "Entry \"$entry\" changed successfully\n";
exit;

#----------- test of RasCreateEntry ---------------
# please try also with "vpn"
$new_entry = "MY_ENTRY";
$type = "modem";

$modem_name = (RasEnumDevicesByType($type))[0] or
  die "No one \"$type\" device were found\n";

print "First device of type \"$type\": \"$modem_name\"\n\n";

RasCreateEntry({
 name             => $new_entry,
 CountryCode      => "250",
 AreaCode         => "012",
 LocalPhoneNumber => "325-52-96",
 DeviceName       => $modem_name,
 NetProtocols     => ["Ip"],
 FramingProtocol  => "PPP",
 ipaddrDns        => "195.190.100.28",
 ipaddrDnsAlt     => "195.190.100.12",
 newFlags         => "UseCountryAndAreaCodes SpecificNameServers
   ModemLights NetworkLogon RemoteDefaultGateway",
 })
 or die Win32::RASE::FormatMessage;

print "Entry \"$new_entry\" created successfully\n";
exit;



#=========================


#----------- test of RasDial ---------------
print "\nI'm dialing via the first RAS entry: $first_RAS_entry\n\n";

($UserName, $Password) = RasGetUserPwd($first_RAS_entry)
 or die Win32::RASE::FormatMessage;

print "UserName:";
!$UserName ? chomp($UserName=<>) : print "$UserName\n";

print "Password:";
!$Password ? chomp($Password=<>) : print "$Password\n";


$hrasconn = RasDial($first_RAS_entry, undef , $UserName, $Password)
 or die Win32::RASE::FormatMessage;

#($err, $status) = RasDial("CLICK", "DP 110-6511" , $UserName, $Password,undef,undef)
# or die Win32::RASE::FormatMessage;

print "Connected, \$hrasconn=$hrasconn\n";
exit;

#----------- test of RasGetProjectionInfo ---------------
unless ( $hrasconn = (RasEnumConnections())[1] ) {
	 print "Dialing sequence not started\n";

} elsif ( ($ip, $server_ip) = RasGetProjectionInfo( $hrasconn ) ) {
	 print "LOCAL:$ip  SERVER:$server_ip\n";

} elsif ( Win32::RASE::GetLastError == 731 ) {
	 print "Protocol not configured yet\n";

} else {
	 die Win32::RASE::FormatMessage;
}
exit;

#----------- test of HangUp ---------------
if ( HangUp() ) {
    print "Disconnected successfully.\n";
} else {
    print "Some connections might be still active.\n";
}

exit;

#----------- test of RasHangUp ---------------
$hrasconn = (RasEnumConnections())[1];
if ( RasHangUp($hrasconn, 2) ) {
	 print "Connection was terminated successfully.\n";
} elsif ( !Win32::RASE::GetLastError ) {
	 print "Timeout. Connection is still active.\n";
} else {
	 # we don't have to die here
	 warn Win32::RASE::FormatMessage, "\n";
}
exit;


#----------- test of RasGetConnectStatus ---------------
# start connecton by some other tool (DUN for exmple),
# run this, see how it connects and then hang up - also by yourself

eval "use Time::HiRes qw(sleep)";
$hrasconn = (RasEnumConnections())[1];
$old_status = -1;

while ( ($status, $status_text) = RasGetConnectStatus($hrasconn) ) {
   if ($status != $old_status) {
       print "$status: $status_text\n";
       $old_status =  $status;
   }
   sleep ($@ ? 1 : 0.01);
}
# error 6 - Invalid handle
($err = Win32::RASE::GetLastError) != 6 and die Win32::RASE::FormatMessage($err);
exit;


#----------- test of RasEnumConnections ---------------
if (%conn = RasEnumConnections()) {
   print map "$_: hrasconn=$conn{$_}\n", keys %conn;

} else {
   print "No active connections\n";
}
exit;

#----------- printing device properties ---------------
RasPrintEntryDevProperties($first_RAS_entry);
exit;


#----------- test of RasChangePhoneNumber ---------------
# be carefull!!! this will change the phonenumber
# in your RAS entry

$entry = "<put here>";

IsEntry($entry) or die "Entry \"$entry\" not found.\n";

print "RAS entry: $entry\n";

RasChangePhoneNumber($entry, "1-(212)-211-5555")
 or die Win32::RASE::FormatMessage;

print "Changed successfully\n\n";
RasPrintEntryProperties($entry);
exit;

#----------- test of RasCreateEntry ---------------
# please try also with "vpn"
$new_entry = "<put here>";
$type = "modem";

$modem_name = (RasEnumDevicesByType($type))[0] or
  die "No one \"$type\" device were found\n";

print "First device of type \"$type\": \"$modem_name\"\n\n";

RasCreateEntry({
 name             => $new_entry,
 CountryCode      => "250",
 AreaCode         => "012",
 LocalPhoneNumber => "325-52-96",
 DeviceName       => $modem_name,
 NetProtocols     => ["Ip"],
 FramingProtocol  => "PPP",
 ipaddrDns        => "195.190.100.28",
 ipaddrDnsAlt     => "195.190.100.12",
 newFlags         => "UseCountryAndAreaCodes SpecificNameServers
   ModemLights NetworkLogon RemoteDefaultGateway",
 })
 or die Win32::RASE::FormatMessage;

print "Entry \"$new_entry\" created successfully\n";
exit;

#----------- test of RasSetEntryProperties ---------------
# please try also with "vpn"
$entry = "<put here>";
$type = "modem";

$modem_name = (RasEnumDevicesByType($type))[0] or
  die "No one \"$type\" device were found\n";

print "First device of type \"$type\": \"$modem_name\"\n\n";
RasSetEntryProperties({
 name             => $entry,
 CountryCode      => "250",
 AreaCode         => "012",
 LocalPhoneNumber => "325-52-95",
 DeviceName       => $modem_name,
 newFlags         => "+KeepOldFlags -UseCountryAndAreaCodes",
 })
 or die Win32::RASE::FormatMessage;

print "Entry \"$entry\" changed successfully\n";
exit;

#----------- printing entry properties ---------------
RasPrintEntryProperties($first_RAS_entry);
exit;

#----------- test of RasGetEntryProperties ---------------
print "First RAS entry: $first_RAS_entry\n";

$p = RasGetEntryProperties($first_RAS_entry)
 or die Win32::RASE::FormatMessage;

print map "$_ => $p->{$_}\n",sort keys %$p;
exit;

#----------- test of RasRenameEntry ---------------
$entry_old = "<put here>";
$entry_new = "<put here>";

RasRenameEntry($entry_old, $entry_new)
 or die Win32::RASE::FormatMessage;

print "Entry \"$entry_old\" successfully renamed to \"$entry_new\"\n";
exit;

#----------- test of RasDeleteEntry ---------------
# be carefull!!! this will remove your RAS entry

$entry = "<put here>";

RasDeleteEntry($entry)
 or die Win32::RASE::FormatMessage;

print "Entry \"$entry\" was removed.\n";
exit;

#----------- test of RasCopyEntry ---------------
print "Existing entry: $first_RAS_entry\n";

RasCopyEntry($first_RAS_entry, $first_RAS_entry.".copy")
 or die Win32::RASE::FormatMessage;

print "Entry \"$first_RAS_entry.copy\" created successfully\n";

exit;

#----------- test of RasEnumEntries ---------------
@entries = RasEnumEntries()
 or die Win32::RASE::FormatMessage;
print "@entries\n";
exit;

#----------- test of IsEntry ---------------
$entry = "<put here>";

print (IsEntry($entry) ? "$entry exists" : "$entry does not exist");
exit;

#----------- test of RasSetEntryDialParams (adding the password) --------
# be carefull!!! this will change login/password
# in your RAS entry

$entry = "<put here>";
$UserName = "";
$Password = "";

IsEntry($entry) or die "Entry \"$entry\" not found.\n";

print "RAS entry: $entry\n";

RasSetEntryDialParams($entry, $UserName, $Password)
 or die Win32::RASE::FormatMessage;

print "Changed successfully\n";
exit;

#----------- test of RasSetEntryDialParams (removing the password) --------
# be carefull!!! this will remove password of the specified user
# in your RAS entry

$entry = "<put here>";
$UserName = "<put here>";

IsEntry($entry) or die "Entry \"$entry\" not found.\n";

print "RAS entry: $entry\n";

RasSetEntryDialParams($entry, $UserName, "", undef, undef, 1)
 or die Win32::RASE::FormatMessage;

print "Changed successfully\n";
exit;

#----------- test of RasGetUserPwd ---------------
print "First RAS entry: $first_RAS_entry\n";

($UserName, $Password) = RasGetUserPwd($first_RAS_entry)
 or die Win32::RASE::FormatMessage;

print "UserName: ".($UserName ? $UserName : "<not defined>")."\n";
print "Password: ".($Password ? $Password : "<not defined>")."\n";

exit;

#----------- test of RasGetEntryDialParams ---------------
print "First RAS entry: $first_RAS_entry\n";

($UserName, $Password, $Domain, $CallbackNumber) =
 RasGetEntryDialParams($first_RAS_entry)
    or die Win32::RASE::FormatMessage;

print "UserName: ".($UserName ? $UserName : "<not defined>")."\n";
print "Password: ".($Password ? $Password : "<not defined>")."\n";
print "Domain  : ".($Domain   ? $Domain   : "<not defined>")."\n";
print "CallbackNumber: ".($CallbackNumber ? $CallbackNumber : "<not defined>")."\n";

exit;

#----------- test of RasCreateEntryDlg ---------------
%old = map {$_,1} RasEnumEntries();

RasCreateEntryDlg($hwnd)
 or die Win32::RASE::FormatMessage;

%new = map {$_,1} grep ! exists $old{$_}, RasEnumEntries();

if (keys %new) {
  print "New entry `".((keys %new)[0])."' was created\n";
} else {
  print "Success. No new entries were created.\n";
}

exit;

#----------- test of RasEditEntryDlg ---------------
print "First RAS entry: $first_RAS_entry\n";

RasEditEntryDlg($first_RAS_entry, $hwnd)
 or die Win32::RASE::FormatMessage;

print "Edited successfully\n";

exit;

#----------- test of RasDialDlg ---------------
print "First RAS entry: $first_RAS_entry\n";

if ( RasDialDlg($first_RAS_entry, $hwnd) ) {
	 print "Connection established\n";
} elsif ( !Win32::RASE::GetLastError ) {
	 print "User selected <Cancel>\n";
} else {
	 warn Win32::RASE::FormatMessage, "\n";
}
exit;

#----------- test of TAPISetCurrentLocation ---------------
TAPISetCurrentLocation("Hotel")
 or print "Location \"Hotel\" not found\n";
exit;


#----------- test of TAPIEnumLocations ---------------
($CurrentLocation, %locations) = Win32::RASE::TAPIEnumLocations;
print "Current Location: $CurrentLocation\n";
print map "$_ => [".(join", ",@{$locations{$_}})."]\n", keys %locations;
exit;


#----------- test of TAPIEnumerationPrint ---------------
Win32::RASE::TAPIEnumerationPrint();
exit;


#----------- test of IsCountryID ---------------
$CountryID = 112;
if ( IsCountryID($CountryID) ) {
    print "$CountryID - valid CountryID\n";
} else {
    print "$CountryID - invalid CountryID\n";
}
exit;

#----------- test of TAPICountryCode ---------------
$CountryID = 112;
if ($code = Win32::RASE::TAPICountryCode($CountryID)) {
    print "$CountryID: code ($code) - ".Win32::RASE::TAPICountryName($CountryID)."\n";
} else {
    print "Invalid CountryID\n";
}
exit;

#----------- test of TAPICountryName ---------------
if ($name = Win32::RASE::TAPICountryName(113)) {
	 print "$name\n";
} else {
	 print "Invalid CountryID\n";
}
exit;

#----------- test of TAPIlineGetTranslateCaps ---------------
($id, $code, $area) = Win32::RASE::TAPIlineGetTranslateCaps();
print "CountryID: $id\nCountryCode: $code\nAreaCode: $area\n";
exit;

#----------- test of RasEnumDevicesByType -- find modem device IDs ----
@modem_names = RasEnumDevicesByType("modem");
print @modem_names." modem(s) found\n";
exit;

#----------- test of RasEnumDevices ---------------
%devices = RasEnumDevices();
print map "\"$_\" of type \"$devices{$_}\"\n", keys %devices;
exit;

#----------- test of Win32::RASE::FormatMessage ---------------
print Win32::RASE::FormatMessage(630);
exit;

#----------- list of Ras errors  ---------------
print map "$_ => ".Win32::RASE::FormatMessage($_)."\n", 600..752;
exit;


#=============== don't edit under this line ==============
sub FindOpenedFolders () {
# returns array of hwnd's of the opened folders
  my $findAfter = 0;
  my @folders;
  $FindWindowEx ||= new Win32::API("user32", "FindWindowEx", [N,N,P,P], N);

  while($findAfter = $FindWindowEx->Call(0, $findAfter, "CabinetWClass", 0)) {
     push @folders, $findAfter;
  }

  $findAfter = 0;
  while($findAfter = $FindWindowEx->Call(0, $findAfter, "ExploreWClass", 0)) {
     push @folders, $findAfter;
  }
  @folders;
}

sub CloseWindow ($) {
# arg - hwnd
  $PostMessage ||= new Win32::API("user32", "PostMessage", [N,N,N,N], I);
  $WN_CLOSE = 0x10;

  $PostMessage->Call(shift, $WN_CLOSE, 0, 0);
}

BEGIN {
  require Win32::API;

  unless ($hwnd = (FindOpenedFolders())[0]) {
    system 'start explorer /n,C:\\';
    $start_time = time;
    while (!($hwnd = (FindOpenedFolders())[0]) && $start_time+3 < time) {}

    $hwnd or die "Could not open C:\\ window\n";
    $hwnd_opened = 1;
  }

  $first_RAS_entry = (RasEnumEntries())[0]
    or die "No one RAS entry were found\n";
}

END { CloseWindow($hwnd) if $hwnd_opened }
