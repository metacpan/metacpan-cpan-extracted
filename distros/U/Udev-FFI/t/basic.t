use strict;
use warnings;

use Test::More tests => 2;

use Udev::FFI;

my $udev_version = Udev::FFI::udev_version();

isnt($udev_version, undef, "Get udev library version");
note 'udev library version is '.$udev_version
    if defined $udev_version;

my $udev = eval { Udev::FFI->new() };
diag "Can't create Udev::FFI object: $@\nUdev library version is ".(defined($udev_version) ?$udev_version :'unknown')
    if $@;

isa_ok $udev, 'Udev::FFI';