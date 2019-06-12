#!/usr/bin/perl

use strict;
use warnings;

use Udev::FFI;



my $udev = Udev::FFI->new() or
    die "Can't create Udev::FFI object: $@.\n";

my $monitor = $udev->new_monitor() or
    die "Can't create udev monitor: $@.\n";


unless($monitor->filter_by_subsystem_devtype('block')) {
    warn "Ouch!";
}

if($monitor->start()) {
    #now insert your block device

    for(;;) {
        if(defined(my $device = $monitor->poll(0.5))) { #non-blocking read like can_read in IO::Select
            my $action = $device->get_action();

            print 'ACTION: '.$action, "\n";
            print 'SYSNAME: '.$device->get_sysname(), "\n";
            print 'DEVNODE: '.$device->get_devnode(), "\n";

            print "\n\n";
        }

        sleep 1;
    }
}