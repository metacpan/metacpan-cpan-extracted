#!/usr/bin/perl

use strict;
use warnings;

use FindBin; # only for this example - load local Udev::FFI module
use lib "$FindBin::Bin/../lib"; # only for this example - load local Udev::FFI module

use Udev::FFI;



my $udev = Udev::FFI->new() or
    die "Can't create udev context: $@.\n";

my $enumerate = $udev->new_enumerate() or
    die "Can't create enumerate context: $@.\n";

$enumerate->add_match_subsystem('block');
$enumerate->scan_devices();

my @a = $enumerate->get_list_entries();
if(@a) {
    my $device = $udev->new_device_from_syspath($a[0]);
    if(defined $device) {
        print "Device: ".$device->get_sysname(), "\n";

        my $parent_device = $device->get_parent_with_subsystem_devtype('block');
        if(defined $parent_device) {
            print "Parent device: ".$parent_device->get_sysname(), "\n";
        }
    }
}