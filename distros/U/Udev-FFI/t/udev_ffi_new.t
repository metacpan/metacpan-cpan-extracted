use strict;
use warnings;

use Test::More tests => 1;

use FFI::CheckLib;
use Udev::FFI;

my ($libudev)       = find_lib(lib => 'udev');
my (@libs)          = find_lib(lib => 'udev');
my $udev_version    = Udev::FFI::udev_version();

my $udev = Udev::FFI->new();
isnt($udev, undef, "Create new Udev::FFI object");

BAIL_OUT "Can't create new Udev::FFI object. Udev library version is ".
    (defined($udev_version) ?$udev_version :'unknown').
    ". Udev library path: $libudev. All possible paths: ".join(' :: ', @libs).
    ". Error message: $@"
    unless defined($udev);