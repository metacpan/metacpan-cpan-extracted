use Test2::V0 -no_srand => 1;

use FFI::CheckLib;
use Udev::FFI;

my $udev = Udev::FFI->new();
isnt($udev, undef, "Create new Udev::FFI object");

unless(defined($udev)) {
    diag("Can't create new Udev::FFI object $@");

    my (@libudev) = find_lib('lib' => 'udev');
    my $udev_version = Udev::FFI::udev_version();

    diag(@libudev ? "libudev:\n'" . join("'\n'", @libudev) . "'" : 'libudev not found');
    diag('Udev library version is '.(defined($udev_version) ? $udev_version : 'unknown'));
}

done_testing();
