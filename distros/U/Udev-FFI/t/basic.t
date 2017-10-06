use strict;
use warnings;

use Test::More tests => 2;

use Udev::FFI;

my $minimum_udev_version = 189;


my $udev_version = Udev::FFI::udev_version();
diag 'udev version is '.$udev_version;

ok($udev_version >= $minimum_udev_version, "minimum supported udev version is $minimum_udev_version");


my $udev = eval { Udev::FFI->new() };
diag $@
    if $@;

isa_ok $udev, 'Udev::FFI';