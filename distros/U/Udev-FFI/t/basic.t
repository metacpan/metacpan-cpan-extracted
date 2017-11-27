use strict;
use warnings;

use Test::More tests => 1;

use Udev::FFI;

my $udev_version = Udev::FFI::udev_version();
diag 'udev version is '.$udev_version;

my $udev = eval { Udev::FFI->new() };
diag $@
    if $@;

isa_ok $udev, 'Udev::FFI';