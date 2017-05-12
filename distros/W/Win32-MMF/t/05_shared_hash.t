use strict;
use warnings;
use Test::More tests => 1;
use Win32::MMF::Shareable;

tie( my %share1, 'Win32::MMF::Shareable', 'share' ) || die;
tie( my %share2, 'Win32::MMF::Shareable', 'share' ) || die;

$share1{aaa} = 1;
$share2{bbb} = 1;

is( $share1{bbb} + $share2{aaa} + scalar keys %share1, 4, "Shared hash OK" );

