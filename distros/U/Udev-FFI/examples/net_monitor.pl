#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Udev::FFI;



my $udev = Udev::FFI->new() or
    die "Can't create udev context: $@.\n";

my $monitor = $udev->new_monitor() or
    die "Can't create udev monitor: $@.\n";


unless($monitor->filter_by_subsystem_devtype('net')) {
    warn "Ouch!";
}

if($monitor->start()) {
    #now insert you usb ethernet adapter

    for(;;) {
        if(defined(my $device = $monitor->poll())) {
            my $action = $device->get_action();

            print 'ACTION: '.$action, "\n";
            print 'DEVPATH: '.$device->get_devpath(), "\n";
            print 'SYSNAME: '.$device->get_sysname(), "\n";

            if($action ne 'remove') {
                print 'MACADDR: '.$device->get_sysattr_value('address'), "\n";
            }

            print "\n\n";
        }

        sleep 1;
    }
}