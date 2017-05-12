#!perl

use strict;
use warnings;

use Test::More tests => 7;

use Win32;
use Win32::pwent;

my $loginName = Win32::LoginName();
my $uid = Win32::pwent::getpwnam($loginName);

ok( defined( $uid ) && ( $uid > 0 ), 'get uid' );

my @pwent = Win32::pwent::getpwnam($loginName);
my @grent = Win32::pwent::getgrgid($pwent[3]);

my $gid = $grent[2];

is( $pwent[3], $grent[2], 'gid' );

my $pwentries = 0;
while( @pwent = Win32::pwent::getpwent() )
{
    ++$pwentries;
}
Win32::pwent::endpwent();

ok( $pwentries > 0, 'getpwent' );

my $userName = Win32::pwent::getpwuid($uid);
is( $userName, $loginName, 'getpwnam' );

my $grentries = 0;
while( @grent = Win32::pwent::getgrent() )
{
    ++$grentries;
}
Win32::pwent::endgrent();

ok( $grentries > 0, 'getgrent' );

my $groupName = Win32::pwent::getgrgid($gid);
my $groupId = Win32::pwent::getgrnam($groupName);
@grent = Win32::pwent::getgrnam($groupName);

is( $groupId, $gid, 'getgrgid' );
is( $groupName, $grent[0], 'getgrnam' );
