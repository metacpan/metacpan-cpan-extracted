# NAME

Udev::FFI - Perl bindings for libudev using ffi.

# SYNOPSIS

    use Udev::FFI;

    #get udev version
    my $udev_version = Udev::FFI::udev_version();
    if(defined $udev_version) {
        print $udev_version. "\n";
    }
    else {
        warn "Can't get udev version: $@";
    }


    #create udev context
    my $udev = Udev::FFI->new() or
        die "Can't create udev context: $@";


    #create udev monitor
    my $monitor = $udev->new_monitor() or
        die "Can't create udev monitor: $@.\n";

    #add filter to monitor
    unless($monitor->filter_by_subsystem_devtype('block')) {
        warn "Ouch!";
    }

    #start monitor
    if($monitor->start()) {
        for(;;) {
            #poll devices, now insert or remove your block device
            my $device = $monitor->poll(); #blocking read
            my $action = $device->get_action();

            print 'ACTION: '.$action, "\n";
            print 'SYSNAME: '.$device->get_sysname(), "\n";
            print 'DEVNODE: '.$device->get_devnode(), "\n";

            last; #for example
        }

        for(;;) {
            #poll devices, now insert or remove your block device
            if(defined(my $device = $monitor->poll(0))) { #non-blocking read like can_read in IO::Select
                my $action = $device->get_action();

                print 'ACTION: '.$action, "\n";
                print 'SYSNAME: '.$device->get_sysname(), "\n";
                print 'DEVNODE: '.$device->get_devnode(), "\n";
            }

            sleep 1;

            last; #for example
        }
    }


    #enumerate devices
    my $enumerate = $udev->new_enumerate() or
        die "Can't create enumerate context\n";

    $enumerate->add_match_subsystem('block');
    $enumerate->scan_devices();

    use Data::Dumper; #for dump values in $href and @a

    # scalar context
    my $href = $enumerate->get_list_entries();
    print Dumper($href), "\n";

    # list context
    my @a = $enumerate->get_list_entries();
    print Dumper(@a), "\n";

    if(@a) { #get major and minor
        use Udev::FFI::Devnum qw(:all); #import major, minor and mkdev

        my $device = $udev->new_device_from_syspath($a[0]);
        if(defined $device) {
            print "Device: ".$device->get_sysname(), "\n";

            my $devnum = $device->get_devnum();
            my ($ma, $mi) = (major($devnum), minor($devnum));

            print "Major: $ma\n";
            print "Minor: $mi\n";

            $devnum = undef;

            $devnum = mkdev($ma, $mi);
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

- new ()

    This is the constructor for a new Udev::FFI object.

    If the constructor fails undef will be returned and an error message will be in $@.

        my $udev = Udev::FFI->new() or
            die "Can't create udev context: $@";

# EXAMPLES

Examples are provided with the Udev::FFI distribution in the "examples" directory.

# SEE ALSO

libudev

[FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) (Write Perl bindings to non-Perl libraries without C or XS)

[FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) (Check that a library is available for FFI)

# AUTHOR

Ilya Pavlov, <ilux@cpan.org>

Contributors:

Mohammad S Anwar

# COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ilya Pavlov

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
