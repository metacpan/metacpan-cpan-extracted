use Test2::V0 -no_srand => 1;

use FFI::CheckLib;
use Udev::FFI;

my $udev_version = Udev::FFI::udev_version();
isnt($udev_version, undef, 'Get udev library version');

unless(defined($udev_version)) {
    my (@libudev) = find_lib('lib' => 'udev');

    diag(@libudev ? "libudev:\n'" . join("'\n'", @libudev) . "'" : 'libudev not found');
}

done_testing();
