package Udev::FFI::Enumerate;

use strict;
use warnings;

use Udev::FFI::Functions qw(:all);



sub new {
    my $class = shift;

    my $self = {
        _enumerate => shift,
        _udev      => shift
    };

    bless $self, $class;

    return $self;
}



sub get_udev {
    return $_[0]->{_udev};
}



sub add_match_subsystem {
    # self, subsystem
    if (0 == ($! = udev_enumerate_add_match_subsystem($_[0]->{_enumerate}, $_[1]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_nomatch_subsystem {
    # self, subsystem
    if (0 == ($! = udev_enumerate_add_nomatch_subsystem($_[0]->{_enumerate}, $_[1]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_match_sysattr {
    # self, sysattr, value
    if (0 == ($! = udev_enumerate_add_match_sysattr($_[0]->{_enumerate}, $_[1], $_[2]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_nomatch_sysattr {
    # self, sysattr, value
    if (0 == ($! = udev_enumerate_add_nomatch_sysattr($_[0]->{_enumerate}, $_[1], $_[2]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_match_property {
    # self, property, value
    if (0 == ($! = udev_enumerate_add_match_property($_[0]->{_enumerate}, $_[1], $_[2]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_match_sysname {
    # self, sysname
    if (0 == ($! = udev_enumerate_add_match_sysname($_[0]->{_enumerate}, $_[1]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_match_tag {
    # self, tag
    if (0 == ($! = udev_enumerate_add_match_tag($_[0]->{_enumerate}, $_[1]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_match_parent {
    # self, parent
    if (0 == ($! = udev_enumerate_add_match_parent($_[0]->{_enumerate}, $_[1]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_match_is_initialized {
    # self
    if (0 == ($! = udev_enumerate_add_match_is_initialized($_[0]->{_enumerate}))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub add_syspath {
    # self, syspath
    if (0 == ($! = udev_enumerate_add_syspath($_[0]->{_enumerate}, $_[1]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}



sub scan_devices {
    # self
    if (0 == ($! = udev_enumerate_scan_devices($_[0]->{_enumerate}))) {
        return 1;
    }

    $! = -$!;
    return 0;
}


sub scan_subsystems {
    # self
    if (0 == ($! = udev_enumerate_scan_subsystems($_[0]->{_enumerate}))) {
        return 1;
    }

    $! = -$!;
    return 0;
}



sub get_list_entries {
    return get_entries( udev_enumerate_get_list_entry($_[0]->{_enumerate}) );
}



sub DESTROY {
    udev_enumerate_unref( $_[0]->{_enumerate} );
}



1;



__END__



=head1 NAME

Udev::FFI::Enumerate

=head1 SYNOPSIS

    use Udev::FFI;
    
    my $udev = Udev::FFI->new() or
        die "Can't create Udev::FFI object: $@";
    
    my $enumerate = $udev->new_enumerate() or
        die "Can't create enumerate context: $@";
    
    $enumerate->add_match_subsystem('usb');
    $enumerate->add_match_sysattr('idVendor'); #devices with VID
    
    $enumerate->scan_devices();
    
    my @devices = $enumerate->get_list_entries();
    for (@devices) {
        my $device = $udev->new_device_from_syspath($_);
    
        if (defined $device) {
            print "DEVICE: ".$device->get_sysname()."\n";
            print "VID: ".$device->get_sysattr_value('idVendor')."\n";
            print "PID: ".$device->get_sysattr_value('idProduct')."\n\n";
        }
    }

=head1 METHODS

=head2 add_match_subsystem( SUBSYSTEM )

=head2 add_nomatch_subsystem( SUBSYSTEM )

=head2 add_match_sysattr( SYSATTR [, VALUE] )

=head2 add_nomatch_sysattr( SYSATTR [, VALUE] )

=head2 add_match_property( PROPERTY [, VALUE] )

=head2 add_match_sysname( SYSNAME )

=head2 add_match_tag( TAG )

=head2 add_match_parent( PARENT )

=head2 add_match_is_initialized()

=head2 add_syspath( SYSPATH )

=head2 scan_devices()

=head2 scan_subsystems()

=head2 get_list_entries()

=head2 get_udev()

=head1 SEE ALSO

L<Udev::FFI> main Udev::FFI documentation

=cut