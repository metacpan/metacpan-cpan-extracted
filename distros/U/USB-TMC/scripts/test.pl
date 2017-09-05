#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib 'lib';
use USB::TMC;

use Benchmark 'timethis';

my $driver = USB::TMC->new(
    vid => 0x0957, pid => 0x0607, # serial => 'MY47000419'
    # debug_mode => 1, 
    # libusb_log_level => LIBUSB_LOG_LEVEL_DEBUG
    );

$driver->write(data => "*CLS\n");
$driver->write(data => "VOLT:NPLC 10\n", timeout => 0.001);
print $driver->query(data => ":read?\n", length => 200, timeout => 1);

# sleep 3;
# #timethis(1000, sub {print $driver->query(data => ":read?\n", length => 200);});
# for my $i (1..300) {
#     say $i;
#     print $driver->query(data => "*IDN?\n", length => 200);
#     #print $driver->query(data => ":read?\n", length => 200);
# }

# for (1..1000) {
#     $driver->write(data => ":read?");
#     print $driver->read(length => 100);
#     # $driver->write(data => "*IDN?\n");
#     # print "idn: ", $driver->read(length => 200);
# }
