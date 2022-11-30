use strict;
use warnings;

use Test::More;

use Udev::FFI;

my $udev = eval { return Udev::FFI->new() };
isa_ok($udev, 'Udev::FFI');

done_testing();
