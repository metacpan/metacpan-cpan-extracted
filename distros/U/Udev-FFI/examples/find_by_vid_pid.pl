#!/usr/bin/perl

use strict;
use warnings;

use FindBin; # only for this example - load local Udev::FFI module
use lib "$FindBin::Bin/../lib"; # only for this example - load local Udev::FFI module

use Udev::FFI;


my $vid = $ARGV[0];
my $pid = $ARGV[1];

unless(defined($vid) && defined($pid)) {
    die "Usage: find_by_vid_pid.pl VID PID\nExample: find_by_vid_pid.pl bced 0b08\n"
}


my $udev = Udev::FFI->new() or
    die "Can't create Udev::FFI object: $@.\n";

my $enumerate = $udev->new_enumerate() or
    die "Can't create enumerate context: $@.\n";

$enumerate->add_match_subsystem('usb');

$enumerate->add_match_sysattr('idVendor', $vid);
$enumerate->add_match_sysattr('idProduct', $pid);

$enumerate->scan_devices();

# list context
my @a = $enumerate->get_list_entries();
for(@a) {
    my $device = $udev->new_device_from_syspath($_);
    if(defined $device) {
        printf "Syspath: %s\n", $_;

        printf "Manufacturer: %s\n", $device->get_sysattr_value("manufacturer") // '';
        printf "Product: %s\n", $device->get_sysattr_value("product") // '';
        printf "Serial: %s\n\n", $device->get_sysattr_value("serial") // '';
    }
}