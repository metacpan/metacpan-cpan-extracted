use strict;
use warnings;

use Test::More tests => 4;

use_ok 'FFI::Platypus';
use_ok 'FFI::CheckLib';

use_ok 'IPC::Cmd';

isnt( find_lib( lib => 'udev' ), undef, 'Looking for libudev' );