use strict;
use warnings;

use Test::More tests => 1;

use Udev::FFI;

my $udev = Udev::FFI->new();
isnt($udev, undef, "Create new Udev::FFI object");

diag "Can't create new Udev::FFI object: $@"
    if not defined($udev);