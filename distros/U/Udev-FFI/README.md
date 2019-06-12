# NAME

Udev::FFI - Perl bindings for libudev using ffi.

# SYNOPSIS

    use Udev::FFI;
    use Udev::FFI::Devnum qw(:all); # <- import major, minor and makedev
    
    # get udev library version
    my $udev_version = Udev::FFI::udev_version() or
        die "Can't get udev library version: $@";
    
    
    # create Udev::FFI object
    my $udev = Udev::FFI->new() or
        die "Can't create Udev::FFI object: $@";
    
    
    # create udev monitor
    my $monitor = $udev->new_monitor() or
        die "Can't create udev monitor: $@";
    
    # add filter to monitor
    unless ($monitor->filter_by_subsystem_devtype('block')) {
        warn "Ouch!";
    }
    
    # start monitor
    if ($monitor->start()) {
        for (;;) {
            # poll devices, now insert or remove your block device
            my $device = $monitor->poll(); # blocking read
            my $action = $device->get_action();
    
            print 'ACTION: '.$action, "\n";
            print 'SYSNAME: '.$device->get_sysname(), "\n";
            print 'DEVNODE: '.$device->get_devnode(), "\n";
    
            last; # for example
        }
    
        for (;;) {
            # poll devices, now insert or remove your block device
            if (defined(my $device = $monitor->poll(0))) { # non-blocking read like can_read in IO::Select
                my $action = $device->get_action();
    
                print 'ACTION: '.$action, "\n";
                print 'SYSNAME: '.$device->get_sysname(), "\n";
                print 'DEVNODE: '.$device->get_devnode(), "\n";
            }
    
            sleep 1;
    
            last; # for example
        }
    }
    
    
    # enumerate devices
    my $enumerate = $udev->new_enumerate() or
        die "Can't create enumerate context: $@";
    
    $enumerate->add_match_subsystem('block');
    $enumerate->scan_devices();
    
    use Data::Dumper; # for dump values in $href and @a
    
    # scalar context
    my $href = $enumerate->get_list_entries();
    print Dumper($href), "\n";
    
    # list context
    my @a = $enumerate->get_list_entries();
    print Dumper(@a), "\n";
    
    if (@a) { # we got devices
        my $device = $udev->new_device_from_syspath($a[0]);
    
        if (defined($device)) {
            print "Device: ".$device->get_sysname(), "\n";
    
            my $devnum = $device->get_devnum();
    
            # major, minor and makedev from Udev::FFI::Devnum
            my ($ma, $mi) = (major($devnum), minor($devnum));
    
            print "Major: $ma\n";
            print "Minor: $mi\n";
    
            $devnum = makedev($ma, $mi);
            print "Devnum: $devnum\n";
    
    
            # scalar context
            $href = $device->get_properties_list_entries();
            print Dumper($href), "\n";
    
            # list context
            @a = $device->get_properties_list_entries();
            print Dumper(@a), "\n";
        }
    }

# DESCRIPTION

Udev::FFI exposes OO interface to libudev.

# CONSTRUCTOR

- new()

    This is the constructor for a new Udev::FFI object.

    If the constructor fails undef will be returned and an error message will be in
    $@.

        my $udev = Udev::FFI->new() or
            die "Can't create Udev::FFI object: $@";

# METHODS

## new\_monitor( \[SOURCE\] )

Create new udev monitor and connect to a specified event source. Valid sources
identifiers are `'udev'` and `'kernel'`. This argument is optional and
defaults to `'udev'`.

Return new [Udev::FFI::Monitor](https://metacpan.org/pod/Udev::FFI::Monitor) object on success, undef with the error in $@
on failure.

    my $monitor = $udev->new_monitor() or
        die "Can't create udev monitor: $@";

## new\_enumerate()

Create an enumeration context to scan /sys.

Return new [Udev::FFI::Enumerate](https://metacpan.org/pod/Udev::FFI::Enumerate) object on success, undef with the error in $@
on failure.

    my $enumerate = $udev->new_enumerate() or
        die "Can't create enumerate context: $@";

## new\_device\_from\_syspath( SYSPATH )

Create new udev device, and fill in information from the sys device and the udev
database entry. The syspath is the absolute path to the device, including the
sys mount point.

Return new [Udev::FFI::Device](https://metacpan.org/pod/Udev::FFI::Device) object or undef, if device does not exist.

    my $device0 = $udev->new_device_from_syspath('/sys/class/block/sda1');
    my $device1 = $udev->new_device_from_syspath('/sys/class/net/eth0');
    
    # ... some code
    my @devices = $enumerate->get_list_entries();
    for (@devices) {
        my $device = $udev->new_device_from_syspath($_);
    # ... some code

## new\_device\_from\_devnum( TYPE, DEVNUM )

Create new udev device, and fill in information from the sys device and the udev
database entry. The device is looked-up by its type and major/minor number.

Return new [Udev::FFI::Device](https://metacpan.org/pod/Udev::FFI::Device) object or undef, if device does not exist.

    use Udev::FFI::Devnum qw(makedev);
    my $device0 = $udev->new_device_from_devnum('b', makedev(8, 1));
    my $device1 = $udev->new_device_from_devnum('c', makedev(189, 515));

## new\_device\_from\_subsystem\_sysname( SUBSYSTEM, SYSNAME )

Create new udev device, and fill in information from the sys device and the udev
database entry. The device is looked up by the subsystem and name string of the
device.

Return new [Udev::FFI::Device](https://metacpan.org/pod/Udev::FFI::Device) object or undef, if device does not exist.

    my $device0 = $udev->new_device_from_subsystem_sysname('block', 'sda1');
    my $device1 = $udev->new_device_from_subsystem_sysname('net', 'lo');
    my $device2 = $udev->new_device_from_subsystem_sysname('mem', 'urandom');

## new\_device\_from\_device\_id( ID )

Create new udev device, and fill in information from the sys device and the udev
database entry. The device is looked-up by a special string:

> `'b8:1'` - block device major:minor
>
> `'c128:2'` - char device major:minor
>
> `'n2'` - network device ifindex
>
> `'+sound:card29'` - kernel driver core subsystem:device name

Return new [Udev::FFI::Device](https://metacpan.org/pod/Udev::FFI::Device) object or undef, if device does not exist.

    my $device = $udev->new_device_from_device_id('b8:1');

## new\_device\_from\_environment()

Create new udev device, and fill in information from the current process
environment. This only works reliable if the process is called from a udev rule.

Return new [Udev::FFI::Device](https://metacpan.org/pod/Udev::FFI::Device) object or undef, if device does not exist.

    # in udev.rules (for example)
    # SUBSYSTEM=="backlight", ACTION=="change", IMPORT{program}="/path/script.pl"
    
    # in script
    my $udev = Udev::FFI->new() or
        die "Can't create Udev::FFI object: $@";
    my $device = $udev->new_device_from_environment();
    if (defined($device)) {
        # $device is the device from the udev rule (backlight in this example)
        # work with $device

## Udev::FFI::udev\_version()

Return the version of the udev library. Because the udev library does not
provide a function to get the version number, this function runs the \`udevadm\`
utility.

Return undef with the error in $@ on failure. Also you can check $! value:
ENOENT (\`udevadm\` not found) or EACCES (permission denied).

    # simple
    my $udev_version = Udev::FFI::udev_version() or
        die "Can't get udev library version: $@";
    
    # or catch the error
    use Errno qw( :POSIX );
    my $udev_version = Udev::FFI::udev_version();
    unless (defined($udev_version)) {
        if ($!{ENOENT}) {
            # udevadm not found
        }
        elsif ($!{EACCES}) {
            # permission denied
        }
    
        die("Can't get udev library version: $@");
    }

# EXAMPLES

Examples are provided with the Udev::FFI distribution in the "examples"
directory.

# SEE ALSO

libudev

eudev

[FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) (Write Perl bindings to non-Perl libraries without C or XS)

[FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) (Check that a library is available for FFI)

# BUGS AND LIMITATIONS

Udev::FFI supports libudev 175 or newer. Older versions may work too, but it was
not tested.

Please report any bugs through the web interface at
[https://github.com/Ilya33/udev-ffi/issues](https://github.com/Ilya33/udev-ffi/issues) or via email to the author. Patches
are always welcome.

# AUTHOR

Ilya Pavlov, <ilux@cpan.org>

Contributors:

Mohammad S Anwar

# COPYRIGHT AND LICENSE

Copyright (C) 2017-2018 by Ilya Pavlov

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
