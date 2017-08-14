# Udev::FFI - Copyright (C) 2017 Ilya Pavlov
# Udev::FFI is licensed under the
# GNU Lesser General Public License v2.1

package Udev::FFI;

use strict;
use warnings;

use Udev::FFI::FFIFunctions;
use Udev::FFI::Device;
use Udev::FFI::Monitor;
use Udev::FFI::Enumerate;

use IPC::Cmd qw(can_run run);


$Udev::FFI::VERSION = '0.098000';


use constant {
    UDEVADM_LOCATIONS => [
        '/bin/udevadm'
    ]
};



sub udev_version {
    my $full_path = can_run('udevadm');

    if(!$full_path) {
        for(@{ +UDEVADM_LOCATIONS }) {
            if(-f) {
                $full_path = $_;
                last;
            }
        }
    }

    if(!$full_path) {
        $@ = "Can't find udevadm utility";
        return undef;
    }


    my ( $success, $error_message, undef, $stdout_buf, $stderr_buf ) =
        run( command => [$full_path, '--version'], timeout => 60, verbose => 0 );

    if(!$success) {
        $@ = $error_message;
        return undef;
    }
    if($stdout_buf->[0] !~ /^(\d+)\s*$/) {
        $@ = "Can't get udev version from udevadm utility";
        return undef;
    }

    return $1;
}



sub new {
    my $class = shift;

    my $self = {};

    if(0 == Udev::FFI::FFIFunctions->load_lib()) {
        $@ = "Can't find udev library";
        return undef;
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
    if(defined($device)) {
        return Udev::FFI::Device->new( $device );
    }

    return undef;
}



sub new_device_from_devnum {
    my $self = shift;
    my $type = shift;
    my $devnum = shift;

    my $device = udev_device_new_from_devnum($self->{_context}, ord($type), $devnum);
    if(defined($device)) {
        return Udev::FFI::Device->new( $device );
    }

    return undef;
}



sub new_device_from_subsystem_sysname {
    my $self = shift;
    my $subsystem = shift;
    my $sysname = shift;

    my $device = udev_device_new_from_subsystem_sysname($self->{_context}, $subsystem, $sysname);
    if(defined($device)) {
        return Udev::FFI::Device->new( $device );
    }

    return undef;
}



sub new_device_from_device_id {
    my $self = shift;
    my $id = shift;

    my $device = udev_device_new_from_device_id($self->{_context}, $id);
    if(defined($device)) {
        return Udev::FFI::Device->new( $device );
    }

    return undef;
}



sub new_device_from_environment {
    my $self = shift;

    my $device = udev_device_new_from_environment($self->{_context});
    if(defined($device)) {
        return Udev::FFI::Device->new( $device );
    }

    return undef;
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

=head1 DESCRIPTION

Udev::FFI exposes OO interface to libudev.

=head1 EXAMPLES

See examples folder.

=head1 SEE ALSO

libudev

L<FFI::Platypus> (Write Perl bindings to non-Perl libraries without C or XS)

L<FFI::CheckLib> (Check that a library is available for FFI)

=head1 AUTHOR

Ilya Pavlov, E<lt>ilux@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ilya Pavlov

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


=cut