#!/usr/bin/perl
# ATTENTION place it script to startup/autostart applications in your desktop
# environment or run by current x-session user.

use strict;
use warnings;

use FindBin; # only for this example - load local Udev::FFI module
use lib "$FindBin::Bin/../lib"; # only for this example - load local Udev::FFI module

use Udev::FFI;


use constant {
    # add your mouse VID and PID in array
    MOUSES => [{
        VID => '046d',
        PID => 'c06d'
    }],

    ON_TOUCHPAD_COMMAND => '/usr/bin/synclient touchpadoff=0',
    OFF_TOUCHPAD_COMMAND => '/usr/bin/synclient touchpadoff=1'
};


my %inserted_mouses;



my $udev = Udev::FFI->new() or
    die "Can't create udev context: $@.\n";


# monitor for new devices
my $monitor = $udev->new_monitor() or
    die "Can't create udev monitor: $@.\n";

$monitor->filter_by_subsystem_devtype('usb', 'usb_device');

# start monitor before enumerate to catch devices inserted between enumerate and
# $monitor->poll()
$monitor->start() or
    die "Can't start udev monitor :(\n";


# check already inserted devices
my $enumerate = $udev->new_enumerate() or
    die "Can't create enumerate context: $@.\n";

$enumerate->add_match_subsystem('usb');
# some versions of libudev work incorrectly with $enumerate->add_match_sysattr('idVendor', $vid);
$enumerate->add_match_sysattr('idVendor');
$enumerate->add_match_sysattr('idProduct');
$enumerate->scan_devices();

my @inserted_devices = $enumerate->get_list_entries();
for(@inserted_devices) {
    my $device = $udev->new_device_from_syspath($_);
    my $device_vid = $device->get_sysattr_value("idVendor");
    my $device_pid = $device->get_sysattr_value("idProduct");

    for(@{+MOUSES}) {
        if($device_vid eq $_->{VID} && $device_pid eq $_->{PID}) {
            $inserted_mouses{ $device->get_devpath() } = 1;
            last;
        }
    }
}

# known mouses > 0
if(%inserted_mouses) {
    system(OFF_TOUCHPAD_COMMAND);
}


for(;;) {
    my $device = $monitor->poll(); # blocking read
    my $action = $device->get_action();
    my $device_vid = $device->get_sysattr_value("idVendor");
    my $device_pid = $device->get_sysattr_value("idProduct");

    if($action eq 'add' && defined($device_vid) && defined($device_pid)) {
        for(@{+MOUSES}) {
            if($device_vid eq $_->{VID} && $device_pid eq $_->{PID}) {
                system(OFF_TOUCHPAD_COMMAND)
                    unless %inserted_mouses;

                $inserted_mouses{ $device->get_devpath() } = 1;
                last;
            }
        }
    }
    elsif($action eq 'remove') {
        delete $inserted_mouses{ $device->get_devpath() };

        # known mouses == 0
        unless(%inserted_mouses) {
            system(ON_TOUCHPAD_COMMAND);
        }
    }
}