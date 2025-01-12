use Test2::V0 -no_srand => 1;

use FFI::CheckLib;
use Udev::FFI;

my $udev = Udev::FFI->new();
isnt($udev, undef, "Create new Udev::FFI object");

#TODO

done_testing();
