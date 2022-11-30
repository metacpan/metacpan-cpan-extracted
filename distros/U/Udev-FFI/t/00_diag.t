use strict;
use warnings;

use Test::More;

use_ok('FFI::Platypus');
use_ok('FFI::CheckLib');
use_ok('File::Which');

my ($libudev) = find_lib(lib => 'udev');
isnt($libudev, undef, 'Looking for libudev');

done_testing();
