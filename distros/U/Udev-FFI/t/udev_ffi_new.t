use strict;
use warnings;

use Test::More;

use FFI::CheckLib;
use Udev::FFI;



sub _print_paths {
    my ($libudev)   = find_lib(lib => 'udev');
    my (@libs)      = find_lib(lib => 'udev');

    return "Udev library path: $libudev. All possible paths: ".
        join(' :: ', @libs);
}



my $udev_version = Udev::FFI::udev_version();
diag("$@. "._print_paths())
    unless defined($udev_version);

isnt($udev_version, undef, "Get udev library version");


my $udev = Udev::FFI->new();
isnt($udev, undef, "Create new Udev::FFI object");

BAIL_OUT("Can't create new Udev::FFI object. Udev library version is ".
    (defined($udev_version) ? $udev_version : 'unknown').'. '._print_paths().
    ". Error message: $@"
)
    unless defined($udev);

done_testing();
