use Test::More skip_all => " *** NOT IMPLEMENTED";
#test for Perl NetResource Module Extension.
#Written by Jesse Dougherty for hip communications.
#Subsequently hacked by Gurusamy Sarathy <gsar@activestate.com>

#NOTE:
#this test will only work if a username and password are supplied in the 
#$user and $passwd vars.

$user = "";
$passwd = "";

use Win32::NetResource;
$debug = 2;

sub deb {
    if ($debug) {
	print "# @_\n"
    }
}

sub err {
    require Win32 unless defined &Win32::FormatMessage;
    my $err;
    Win32::NetResource::GetError($err);
    deb("|$err| => ", Win32::FormatMessage($err));
}

$tests = 7;
print "1..$tests\n";

$ShareInfo = {
		'path' => 'c:\\',
		'netname' => "myshare",
		'remark' => "This mine, leave it alone",
		'passwd' => "soundgarden",
		'current-users' =>0,
		'permissions' => 0,
		'maxusers' => 10,
		'type'  => 10,
	     };

#
# test the hash conversion

deb("testing the hash conversion routines");

$this = Win32::NetResource::_hash2SHARE( $ShareInfo );
$that = Win32::NetResource::_SHARE2hash( $this );

foreach (keys %$ShareInfo) {
    if ($ShareInfo->{$_} ne $that->{$_}) {
	deb("$_ |$ShareInfo->{$_}| vs |$that->{$_}|");
	print "not ";
    }
}
print "ok 1\n";

err();

#
# Make a share of the current directory.

$ShareInfo = {
		'path' => "c:\\",
		'netname' => "PerlTempShare",
		'remark' => "This mine, leave it alone",
		'passwd' => "",
		'current-users' =>0,
		'permissions' => 0,
		'maxusers' => -1,
		'type'  => 0,
	     };



deb("Testing NetShareAdd");
$ok = $parm = "";
$ok = Win32::NetResource::NetShareAdd( $ShareInfo,$parm );
unless ($ok) {
    Win32::NetResource::GetError(my $err);
    if ($err == 2114) {
	print "ok $_ # skip The Server service is not started.\n" for 2..$tests;
	exit 0;
    }
}

$ok or print "not ";
print "ok 2\n";

err();

deb("testing NetShareGetInfo");
$NewShare = {};
Win32::NetResource::NetShareGetInfo("PerlTempShare", $NewShare) or print "not ";
print "ok 3\n";
err();

foreach (keys %$NewShare) {
    deb("# $_ => $NewShare->{ $_ }");
}

#
# test the GetSharedResources function call

$Aref=[];

my $host = {
    Scope       => RESOURCE_GLOBALNET,
    Type        => RESOURCETYPE_DISK,
    DisplayType => RESOURCEDISPLAYTYPE_SHARE,
    Usage       => RESOURCEUSAGE_CONNECTABLE,
    LocalName   => '',
    RemoteName  => '\\\\' . Win32::NodeName(),
    Comment     => '',
    Provider    => '',
};

deb("testing GetSharedResources");

Win32::NetResource::GetSharedResources($Aref,0,$host) or print "not ";
print "ok 4\n";
err();

deb("-----");
foreach $href (@$Aref){
    foreach( keys %$href ){
	    deb(" $_: $href->{$_}");
    }
    deb("-----");
}

#
# try to connect to the Temp share

# Find the NETRESOURCE information for the Temp share.
$myRef = {};
foreach $href (@$Aref) {
    $myRef = $href if $href->{'RemoteName'} =~ /PerlTempShare/;
}

#$drive = 'I:';
$drive = Win32::GetNextAvailDrive();
deb("drive is $drive");
if (keys %$myRef) {
    $myRef->{'LocalName'} = $drive;
    Win32::NetResource::AddConnection($myRef,$passwd,$user,0);
    err();

    Win32::NetResource::GetUNCName( $UNCName, $drive ) or print "not ";
    print "ok 5\n";
    err();
    deb("uncname is $UNCName");

    Win32::NetResource::CancelConnection($drive,0,1) or print "not ";
    print "ok 6\n";
    err();
}
else {
    print "ok $_ # skip Share not found\n" for 5..6;
}
Win32::NetResource::NetShareDel("PerlTempShare") or print "not ";
print "ok 7\n";
err();
