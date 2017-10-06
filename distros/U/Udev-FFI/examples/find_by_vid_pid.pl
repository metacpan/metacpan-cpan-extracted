#!/usr/bin/perl

use strict;
use warnings;

use FindBin; # only for this example - load local Udev::FFI module
use lib "$FindBin::Bin/../lib"; # only for this example - load local Udev::FFI module
use Udev::FFI;


my $vid = $ARGV[0];
my $pid = $ARGV[1];

unless(defined($vid) && defined($pid)) {
    die "Usage: find_by_vid_pid.pl VID PID\nExample: find_by_vid_pid.pl 0a12 0001\n"
}


my $udev = Udev::FFI->new() or
    die "Can't create udev context: $@.\n";

my $enumerate = $udev->new_enumerate() or
    die "Can't create enumerate context: $@.\n";

$enumerate->add_match_subsystem('usb');
# some versions of libudev work incorrectly with $enumerate->add_match_sysattr('idVendor', $vid);
$enumerate->add_match_sysattr('idVendor');
$enumerate->add_match_sysattr('idProduct');
$enumerate->scan_devices();

# list context
my @a = $enumerate->get_list_entries();
for(@a) {
    my $device = $udev->new_device_from_syspath($_);
    my $device_vid = $device->get_sysattr_value("idVendor");
    my $device_pid = $device->get_sysattr_value("idProduct");

    if($device_vid eq $vid && $device_pid eq $pid) {
        printf "VID: %s\n", $device_vid;
        printf "PID: %s\n", $device_pid;
        printf "Manufacturer: %s\n", $device->get_sysattr_value("manufacturer") // '';
        printf "Product: %s\n", $device->get_sysattr_value("product") // '';
        printf "Serial: %s\n\n", $device->get_sysattr_value("serial") // '';

        last;
    }
}