use strict;
use warnings;

use Test;
use Win32::NetResource;

my $user   = "";
my $passwd = "";

eval {require Win32};
my $is_admin = defined &Win32::IsAdminUser && Win32::IsAdminUser();

my $tests = $is_admin ? 7 : 1;
plan tests => $tests;

sub err {
    Win32::NetResource::GetError(my $err);
    print "# LastError:  $err => ", Win32::FormatMessage($err);
}
sub check { err(); ok(shift)}

my %share_info = (
    'path'          => 'c:\\',
    'netname'       => "myshare",
    'remark'        => "This mine, leave it alone",
    'passwd'        => "soundgarden",
    'current-users' => 0,
    'permissions'   => 0,
    'maxusers'      => 10,
    'type'          => 10,
);

# test the hash conversion

print "# testing the hash conversion routines\n";

my $this = Win32::NetResource::_hash2SHARE(\%share_info);
my $that = Win32::NetResource::_SHARE2hash($this);

my $ok = 1;
foreach (keys %share_info) {
    next if $share_info{$_} eq $that->{$_};
    print "# $_ |$share_info{$_}| vs |$that->{$_}|\n";
    $ok = 0;
}
ok($ok);

exit(0) unless $is_admin;

# Make a share of the current directory.

%share_info = (
    'path'          => "c:\\",
    'netname'       => "PerlTempShare",
    'remark'        => "This mine, leave it alone",
    'passwd'        => "",
    'current-users' => 0,
    'permissions'   => 0,
    'maxusers'      => -1,
    'type'          => 0,
);


print "# Testing NetShareAdd\n";
$ok = Win32::NetResource::NetShareAdd(\%share_info, my $parm);
unless ($ok) {
    Win32::NetResource::GetError(my $err);
    if ($err == 2114) {
	skip("The Server service is not started.") for 2..$tests;
	exit 0;
    }
}
check($ok);

print "# testing NetShareGetInfo\n";
check(Win32::NetResource::NetShareGetInfo("PerlTempShare", my $new_share));
print "# $_ => $new_share->{ $_ }\n" foreach keys %$new_share;

# test the GetSharedResources function call

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

print "# testing GetSharedResources\n";

check(Win32::NetResource::GetSharedResources(my $resources, 0, $host));

print "# -----\n";
foreach my $resource (@$resources){
    print "# $_: $resource->{$_}\n" for keys %$resource;
    print "# -----\n";
}

# try to connect to the Temp share

my($my_share) = grep $_->{RemoteName} =~ /PerlTempShare/, @$resources;

my $drive = Win32::GetNextAvailDrive();
print "# drive is $drive\n";
if (keys %$my_share) {
    $my_share->{'LocalName'} = $drive;
    Win32::NetResource::AddConnection($my_share, $passwd, $user, 0);
    err();

    check(Win32::NetResource::GetUNCName(my $unc_name, $drive));
    print "# UNC name is $unc_name\n";

    check(Win32::NetResource::CancelConnection($drive, 0, 1));
}
else {
    skip("Share not found") for 1..2;
}
check(Win32::NetResource::NetShareDel("PerlTempShare"));
