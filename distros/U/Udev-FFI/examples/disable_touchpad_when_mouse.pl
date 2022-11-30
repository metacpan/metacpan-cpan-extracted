#!/usr/bin/perl
# ATTENTION place it script to startup/autostart applications in your desktop
# environment or run by current x-session user.

use strict;
use warnings;

use Udev::FFI;


use constant {
    DEVICE_INPUT_OTHER          => 0,
    DEVICE_INPUT_MOUSE          => 1,
    DEVICE_INPUT_TOUCHPAD       => 2,
    DEVICE_INPUT_TABLET         => 3,
    DEVICE_INPUT_TOUCHSCREEN    => 4,

    ON_TOUCHPAD_COMMAND => '/usr/bin/synclient touchpadoff=0',
    OFF_TOUCHPAD_COMMAND => '/usr/bin/synclient touchpadoff=1'
};

my $udev;



sub _get_device_type {
    my $device = shift;

    my $id_input_mouse          = $device->get_property_value('ID_INPUT_MOUSE');
    my $id_input_touchpad       = $device->get_property_value('ID_INPUT_TOUCHPAD');
    my $id_input_tablet         = $device->get_property_value('ID_INPUT_TABLET');
    my $id_input_touchscreen    = $device->get_property_value('ID_INPUT_TOUCHSCREEN');

    if (defined($id_input_mouse) && $id_input_mouse eq '1') {
        # ID_INPUT_MOUSE: Touchscreens and tablets have this flag as
        # well, since by the type of events they can produce they act as
        # a mouse.
        # https://askubuntu.com/questions/520359/how-to-detect-touchscreen-devices-from-a-script

        if (defined($id_input_touchpad) && $id_input_touchpad eq '1') {
            return DEVICE_INPUT_TOUCHPAD;
        }
        elsif (defined($id_input_tablet) && $id_input_tablet eq '1') {
            return DEVICE_INPUT_TABLET;
        }
        elsif (defined($id_input_touchscreen) && $id_input_touchscreen eq '1') {
            return DEVICE_INPUT_TOUCHSCREEN;
        }

        return DEVICE_INPUT_MOUSE;
    }
    elsif (defined($id_input_touchpad) && $id_input_touchpad eq '1') {
        return DEVICE_INPUT_TOUCHPAD;
    }
    elsif (defined($id_input_tablet) && $id_input_tablet eq '1') {
        return DEVICE_INPUT_TABLET;
    }
    elsif (defined($id_input_touchscreen) && $id_input_touchscreen eq '1') {
        return DEVICE_INPUT_TOUCHSCREEN;
    }


    return DEVICE_INPUT_OTHER;
}



sub _check_for_mouse_devices {
    my $enumerate = $udev->new_enumerate() or
        die("Can't create enumerate context: $@");

    $enumerate->add_match_subsystem('input') or
        die("Can't add match subsystem: $!");

    $enumerate->scan_devices() or
        die("Can't scan devices: $!");

    my $devices = $enumerate->get_list_entries() or
        die("Can't get devices: $!");

    for (keys(%$devices)) {
        if (defined(my $device = $udev->new_device_from_syspath($_))) {
            if (DEVICE_INPUT_MOUSE == _get_device_type($device)) {
                return 1;
            }
        }
    }

    return 0;
}



$udev = Udev::FFI->new() or
    die("Can't create Udev::FFI object: $@.\n");

my $monitor = $udev->new_monitor() or
    die("Can't create udev monitor: $@");

$monitor->filter_by_subsystem_devtype('input') or
    die("Can't add filter to udev monitor: $!");

$monitor->start() or
    die("Can't start udev monitor: $!");


if (1 == _check_for_mouse_devices()) {
    system(OFF_TOUCHPAD_COMMAND);
}
else {
    system(ON_TOUCHPAD_COMMAND);
}


for (;;) {
    my $device = $monitor->poll(); # blocking read
    my $action = $device->get_action();

    if ($action eq 'add' || $action eq 'remove') {
        if (1 == _check_for_mouse_devices()) {
            system(OFF_TOUCHPAD_COMMAND);
        }
        else {
            system(ON_TOUCHPAD_COMMAND);
        }
    }
}
