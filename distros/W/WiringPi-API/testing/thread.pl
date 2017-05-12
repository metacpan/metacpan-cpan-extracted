use warnings;
use strict;

use RPi::WiringPi::Pin;

my $obj = RPi::WiringPi::Pin->new(1);

$obj->thread_create("callback");

sub callback {
    print "hello, world!\n";
    return 'NULL';
}
