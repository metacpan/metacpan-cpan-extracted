use Test2::V0 -no_srand => 1;

use FFI::CheckLib;

my (@libudev) = find_lib('lib' => 'udev');
ok(@libudev, 'libudev found in the system');

if (scalar(@libudev) > 1) {
    diag("More than one libudev was found:\n'".join("'\n'", @libudev)."'");
}

done_testing();
