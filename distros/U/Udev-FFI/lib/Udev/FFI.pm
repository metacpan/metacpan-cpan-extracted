# Udev::FFI - Copyright (C) 2017 Ilya Pavlov
# Udev::FFI is licensed under the
# GNU Lesser General Public License v2.1

package Udev::FFI;

use strict;
use warnings;

use Udev::FFI::Functions qw(:all);
use Udev::FFI::Device;
use Udev::FFI::Monitor;
use Udev::FFI::Enumerate;


$Udev::FFI::VERSION = '0.099004';



*Udev::FFI::udev_version = \&Udev::FFI::Functions::udev_version;



sub new {
    my $class = shift;
    my $self = {};

    if(0 == Udev::FFI::Functions->init()) {
        return undef; # error already in $@
    }

    $self->{_context} = udev_new();
    if(!defined($self->{_context})) {
        $@ = "Can't create udev context";
        return undef;
    }

    bless $self, $class;
    return $self;
}



sub new_device_from_syspath {
    my $self = shift;
    my $syspath = shift;

    my $device = udev_device_new_from_syspath($self->{_context}, $syspath);

    return defined($device) ?Udev::FFI::Device->new( $device ) :undef;
}



sub new_device_from_devnum {
    my $self = shift;
    my $type = shift;
    my $devnum = shift;

    my $device = udev_device_new_from_devnum($self->{_context}, ord($type), $devnum);

    return defined($device) ?Udev::FFI::Device->new( $device ) :undef;
}



sub new_device_from_subsystem_sysname {
    my $self = shift;
    my $subsystem = shift;
    my $sysname = shift;

    my $device = udev_device_new_from_subsystem_sysname($self->{_context}, $subsystem, $sysname);

    return defined($device) ?Udev::FFI::Device->new( $device ) :undef;
}



sub new_device_from_device_id {
    my $self = shift;
    my $id = shift;

    my $device = udev_device_new_from_device_id($self->{_context}, $id);

    return defined($device) ?Udev::FFI::Device->new( $device ) :undef;
}



sub new_device_from_environment {
    my $self = shift;

    my $device = udev_device_new_from_environment($self->{_context});

    return defined($device) ?Udev::FFI::Device->new( $device ) :undef;
}



sub new_monitor {
    my $self = shift;
    my $source = shift || 'udev';

    if($source ne 'udev' && $source ne 'kernel') {
        $@ = 'Valid sources identifiers are "udev" and "kernel"';
        return undef;
    }

    my $monitor = udev_monitor_new_from_netlink($self->{_context}, $source);
    unless(defined($monitor)) {
        $@ = "Can't create udev monitor from netlink";
        return undef;
    }

    return Udev::FFI::Monitor->new($monitor);
}



sub new_enumerate {
    my $self = shift;

    my $enumerate = udev_enumerate_new($self->{_context});
    unless(defined($enumerate)) {
        $@ = "Can't create enumerate context";
        return undef;
    }

    return Udev::FFI::Enumerate->new($enumerate);
}



sub DESTROY {
    my $self = shift;

    udev_unref( $self->{_context} );
}



1;



__END__



=head1 NAME

Udev::FFI - Perl bindings for libudev using ffi.

=head1 SYNOPSIS

    use Udev::FFI;

    # get udev library version
    my $udev_version = Udev::FFI::udev_version()
        or die "Can't get udev library version: $@";


    # create Udev::FFI object
    my $udev = Udev::FFI->new() or
        die "Can't create Udev::FFI object: $@";


    # create udev monitor
    my $monitor = $udev->new_monitor() or
        die "Can't create udev monitor: $@.\n";

    # add filter to monitor
    unless($monitor->filter_by_subsystem_devtype('block')) {
        warn "Ouch!";
    }

    # start monitor
    if($monitor->start()) {
        for(;;) {
            # poll devices, now insert or remove your block device
            my $device = $monitor->poll(); #blocking read
            my $action = $device->get_action();

            print 'ACTION: '.$action, "\n";
            print 'SYSNAME: '.$device->get_sysname(), "\n";
            print 'DEVNODE: '.$device->get_devnode(), "\n";

            last; # for example
        }

        for(;;) {
            # poll devices, now insert or remove your block device
            if(defined(my $device = $monitor->poll(0))) { #non-blocking read like can_read in IO::Select
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
        die "Can't create enumerate context\n";

    $enumerate->add_match_subsystem('block');
    $enumerate->scan_devices();

    use Data::Dumper; # for dump values in $href and @a

    # scalar context
    my $href = $enumerate->get_list_entries();
    print Dumper($href), "\n";

    # list context
    my @a = $enumerate->get_list_entries();
    print Dumper(@a), "\n";

    if(@a) { # get major and minor
        use Udev::FFI::Devnum qw(:all); # import major, minor and mkdev

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

=head1 DESCRIPTION

Udev::FFI exposes OO interface to libudev.

=head1 CONSTRUCTOR
 
=over 4
 
=item new ()
 
This is the constructor for a new Udev::FFI object.

If the constructor fails undef will be returned and an error message will be in
$@.

    my $udev = Udev::FFI->new() or
        die "Can't create Udev::FFI object: $@";

=back

=head1 METHODS

=over 4

=item new_monitor ( [SOURCE] )

=item new_enumerate ()

E<nbsp>

=item new_device_from_syspath ( SYSPATH )

Create new udev device, and fill in information from the sys device and the udev
database entry. The syspath is the absolute path to the device, including the
sys mount point.

Return new L<Udev::FFI::Device> object or undef, if device does not exist.

    my $device0 = $udev->new_device_from_syspath('/sys/class/block/sda1');
    my $device1 = $udev->new_device_from_syspath('/sys/class/net/eth0');
    
    # ... some code
    my @devices = $enumerate->get_list_entries();
    for(@devices) {
        my $device = $udev->new_device_from_syspath($_);
    # ... some code

=item new_device_from_devnum ( TYPE, DEVNUM )

Create new udev device, and fill in information from the sys device and the udev
database entry. The device is looked-up by its type and major/minor number.

Return new L<Udev::FFI::Device> object or undef, if device does not exist.

    use Udev::FFI::Devnum qw(mkdev);
    my $device = $udev->new_device_from_devnum('b', mkdev(8, 1));

=item new_device_from_subsystem_sysname ( SUBSYSTEM, SYSNAME )

Create new udev device, and fill in information from the sys device and the udev
database entry. The device is looked up by the subsystem and name string of the
device.

Return new L<Udev::FFI::Device> object or undef, if device does not exist.

    my $device0 = $udev->new_device_from_subsystem_sysname('block', 'sda1');
    my $device1 = $udev->new_device_from_subsystem_sysname('net', 'lo');
    my $device2 = $udev->new_device_from_subsystem_sysname('mem', 'urandom');

=item new_device_from_device_id ( ID )

Create new udev device, and fill in information from the sys device and the udev
database entry. The device is looked-up by a special string:

=over 8

=item b8:2 - block device major:minor

=item c128:1 - char device major:minor

=item n3 - network device ifindex

=item +sound:card29 - kernel driver core subsystem:device name

=back

Return new L<Udev::FFI::Device> object or undef, if device does not exist.

    my $device = $udev->new_device_from_device_id('b8:1');

=item new_device_from_environment ()

Create new udev device, and fill in information from the current process
environment. This only works reliable if the process is called from a udev rule.

Return new L<Udev::FFI::Device> object or undef, if device does not exist.

    # in udev.rules (for example)
    # SUBSYSTEM=="backlight", ACTION=="change", IMPORT{program}="/path/script.pl"
    
    # in script
    my $udev = Udev::FFI->new() or
        die "Can't create Udev::FFI object: $@";
    my $device = $udev->new_device_from_environment();
    if(defined $device) {
        # $device is the device from the udev rule (backlight in this example)
        # work with $device

=item Udev::FFI::udev_version ()

Return the version of the udev library. Because the udev library does not
provide a function to get the version number, this function runs the `udevadm`
utility.

Return undef with the error in $@ on failure. Also you can check $! value:
ENOENT (`udevadm` not found) or EACCES (permission denied).

    # simple
    my $udev_version = Udev::FFI::udev_version()
        or die "Can't get udev library version: $@";
    
    # or catch the error
    use Errno qw( :POSIX );
    my $udev_version = Udev::FFI::udev_version();
    unless(defined $udev_version) {
        if($!{ENOENT}) {
            # udevadm not found
        }
        elsif($!{EACCES}) {
            # permission denied
        }
    
        die "Can't get udev library version: $@";
    }

=back

=head1 EXAMPLES

Examples are provided with the Udev::FFI distribution in the "examples"
directory.

=head1 SEE ALSO

libudev

L<FFI::Platypus> (Write Perl bindings to non-Perl libraries without C or XS)

L<FFI::CheckLib> (Check that a library is available for FFI)

=head1 BUGS AND LIMITATIONS

Udev::FFI supports libudev 175 or newer. Older versions may work too, but it was
not tested.

Please report any bugs through the web interface at
L<https://github.com/Ilya33/udev-ffi/issues> or via email to the author. Patches
are always welcome.

=head1 AUTHOR

Ilya Pavlov, E<lt>ilux@cpan.orgE<gt>

Contributors:

Mohammad S Anwar

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ilya Pavlov

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


=cut