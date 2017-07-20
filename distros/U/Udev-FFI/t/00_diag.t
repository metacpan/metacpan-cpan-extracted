use strict;
use warnings;

use Test::More tests => 3;

use_ok 'FFI::Platypus';
use_ok 'FFI::CheckLib';

isnt( find_lib( lib => 'udev' ), undef, 'Looking for libudev' );