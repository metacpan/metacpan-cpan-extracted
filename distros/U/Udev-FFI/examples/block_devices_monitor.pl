#!/usr/bin/perl

use strict;
use warnings;

use FindBin; # only for this example - load local Udev::FFI module
use lib "$FindBin::Bin/../lib"; # only for this example - load local Udev::FFI module

use Udev::FFI;



my $udev = Udev::FFI->new() or
    die "Can't create udev context: $@.\n";

my $monitor = $udev->new_monitor() or
    die "Can't create udev monitor: $@.\n";


unless($monitor->filter_by_subsystem_devtype('block')) {
    warn "Ouch!";
}

if($monitor->start()) {
    #now insert you block device

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