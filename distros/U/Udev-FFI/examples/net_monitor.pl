#!/usr/bin/perl

use strict;
use warnings;

use FindBin; # only for this example - load local Udev::FFI module
use lib "$FindBin::Bin/../lib"; # only for this example - load local Udev::FFI module

use Udev::FFI;



my $udev = Udev::FFI->new() or
    die "Can't create Udev::FFI object: $@.\n";

my $monitor = $udev->new_monitor() or
    die "Can't create udev monitor: $@.\n";


unless($monitor->filter_by_subsystem_devtype('net')) {
    warn "Ouch!";
}

if($monitor->start()) {
    #now insert your usb ethernet adapter

    for(;;) {
        my $device = $monitor->poll(); #blocking read
        my $action = $device->get_action();

        print 'ACTION: '.$action, "\n";
        print 'DEVPATH: '.$device->get_devpath(), "\n";
        print 'SYSNAME: '.$device->get_sysname(), "\n";

        if($action ne 'remove') {
            print 'MACADDR: '.$device->get_sysattr_value('address'), "\n";
        }

        print "\n\n";
    }
}