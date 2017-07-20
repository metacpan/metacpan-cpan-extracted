use strict;
use warnings;

use Test::More tests => 1;

use Udev::FFI;

diag 'udev version is '.Udev::FFI::udev_version();

my $udev = eval { Udev::FFI->new() };
diag $@
    if $@;

isa_ok $udev, 'Udev::FFI';