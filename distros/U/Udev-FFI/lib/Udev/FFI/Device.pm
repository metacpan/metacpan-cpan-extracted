package Udev::FFI::Device;

use strict;
use warnings;

use Udev::FFI::Functions qw(:all);
use Udev::FFI::Helper;



sub new {
    my $class = shift;

    my $self = {
        _device => shift,
        _udev   => shift
    };

    bless($self, $class);

    return $self;
}



sub get_udev {
    return $_[0]->{_udev};
}


sub get_devpath {
    return udev_device_get_devpath($_[0]->{_device});
}

sub get_subsystem {
    return udev_device_get_subsystem($_[0]->{_device});
}

sub get_devtype {
    return udev_device_get_devtype($_[0]->{_device});
}

sub get_syspath {
    return udev_device_get_syspath($_[0]->{_device});
}

sub get_sysname {
    return udev_device_get_sysname($_[0]->{_device});
}

sub get_sysnum {
    return udev_device_get_sysnum($_[0]->{_device});
}

sub get_devnode {
    return udev_device_get_devnode($_[0]->{_device});
}

sub get_is_initialized {
    return udev_device_get_is_initialized($_[0]->{_device});
}

sub get_property_value {
    # self, key
    return udev_device_get_property_value($_[0]->{_device}, $_[1]);
}

sub get_driver {
    return udev_device_get_driver($_[0]->{_device});
}

sub get_devnum {
    return udev_device_get_devnum($_[0]->{_device});
}

sub get_action {
    return udev_device_get_action($_[0]->{_device});
}

sub get_seqnum {
    return udev_device_get_seqnum($_[0]->{_device});
}

sub get_usec_since_initialized {
    return udev_device_get_usec_since_initialized($_[0]->{_device});
}

sub get_sysattr_value {
    # self, sysattr
    return udev_device_get_sysattr_value($_[0]->{_device}, $_[1]);
}

sub set_sysattr_value {
    # self, sysattr, value
    return udev_device_set_sysattr_value($_[0]->{_device}, $_[1], $_[2]);
}

sub has_tag {
    # self, tag
    return udev_device_has_tag($_[0]->{_device}, $_[1]);
}


sub get_parent {
    my $self = shift;

    my $device = udev_device_get_parent($self->{_device});
    if (defined($device)) {
        udev_device_ref($device);

        return Udev::FFI::Device->new($device, $self->{_udev});
    }

    return undef;
}


sub get_parent_with_subsystem_devtype {
    my $self = shift;
    my $subsystem = shift;
    my $devtype = shift;

    my $device = udev_device_get_parent_with_subsystem_devtype($self->{_device}, $subsystem, $devtype);
    if (defined($device)) {
        udev_device_ref($device);

        return Udev::FFI::Device->new($device, $self->{_udev});
    }

    return undef;
}


sub get_devlinks_list_entries {
    return Udev::FFI::Helper::get_entries_all( udev_device_get_devlinks_list_entry($_[0]->{_device}) );
}

sub get_properties_list_entries {
    return Udev::FFI::Helper::get_entries_all( udev_device_get_properties_list_entry($_[0]->{_device}) );
}

sub get_tags_list_entries {
    return Udev::FFI::Helper::get_entries_all( udev_device_get_tags_list_entry($_[0]->{_device}) );
}

sub get_sysattr_list_entries {
    return Udev::FFI::Helper::get_entries_all( udev_device_get_sysattr_list_entry($_[0]->{_device}) );
}



sub DESTROY {
    udev_device_unref($_[0]->{_device});
}



1;



__END__



=head1 NAME

Udev::FFI::Device

=head1 SYNOPSIS

    use Udev::FFI;
    
    my $udev = Udev::FFI->new() or
        die("Can't create Udev::FFI object: $@");
    
    my $device = $udev->new_device_from_subsystem_sysname('block', 'sda1');
    if (defined($device)) {
        print("SYSPATH: ".$device->get_syspath()."\n");

        if (my $fs = $device->get_property_value('ID_FS_TYPE')) {
            print("FS: $fs\n");
        }
        if (my $uuid = $device->get_property_value('ID_FS_UUID')) {
            print("UUID: $uuid\n");
        }
    }

=head1 METHODS

=head2 get_devpath()

=head2 get_subsystem()

=head2 get_devtype()

=head2 get_syspath()

=head2 get_sysname()

=head2 get_sysnum()

=head2 get_devnode()

=head2 get_is_initialized()

=head2 get_property_value( KEY )

=head2 get_driver()

=head2 get_devnum()

=head2 get_action()

=head2 get_seqnum()

=head2 get_usec_since_initialized()

=head2 get_sysattr_value( SYSATTR )

=head2 set_sysattr_value( SYSATTR, VALUE )

=head2 has_tag( TAG )

=head2 get_parent()

=head2 get_parent_with_subsystem_devtype( SUBSYSTEM [, DEVTYPE] )

=head2 get_devlinks_list_entries()

=head2 get_properties_list_entries()

=head2 get_tags_list_entries()

=head2 get_sysattr_list_entries()

=head2 get_udev()

=head1 SEE ALSO

L<Udev::FFI> main Udev::FFI documentation

=cut
