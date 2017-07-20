package Udev::FFI::Device;

use strict;
use warnings;

use Udev::FFI::FFIFunctions;



sub new {
    my $class = shift;

    my $self = {
        _device => shift
    };

    bless $self, $class;

    return $self;
}



sub get_udev {
    my $self = shift;

    return udev_device_get_udev($self->{_device});
}



sub get_devpath {
    my $self = shift;

    return udev_device_get_devpath($self->{_device});
}


sub get_subsystem {
    my $self = shift;

    return udev_device_get_subsystem($self->{_device});
}


sub get_devtype {
    my $self = shift;

    return udev_device_get_devtype($self->{_device});
}


sub get_syspath {
    my $self = shift;

    return udev_device_get_syspath($self->{_device});
}


sub get_sysname {
    my $self = shift;

    return udev_device_get_sysname($self->{_device});
}


sub get_sysnum {
    my $self = shift;

    return udev_device_get_sysnum($self->{_device});
}


sub get_devnode {
    my $self = shift;

    return udev_device_get_devnode($self->{_device});
}


sub get_is_initialized {
    my $self = shift;

    return udev_device_get_is_initialized($self->{_device});
}


sub get_property_value {
    my $self = shift;
    my $key = shift;

    return udev_device_get_property_value($self->{_device}, $key);
}


sub get_driver {
    my $self = shift;

    return udev_device_get_driver($self->{_device});
}


sub get_devnum {
    my $self = shift;

    return udev_device_get_devnum($self->{_device});
}


sub get_action {
    my $self = shift;

    return udev_device_get_action($self->{_device});
}


sub get_seqnum {
    my $self = shift;

    return udev_device_get_seqnum($self->{_device});
}


sub get_usec_since_initialized {
    my $self = shift;

    return udev_device_get_usec_since_initialized($self->{_device});
}


sub get_sysattr_value {
    my $self = shift;
    my $sysattr = shift;

    return udev_device_get_sysattr_value($self->{_device}, $sysattr);
}


sub set_sysattr_value {
    my $self = shift;
    my $sysattr = shift;
    my $value = shift;

    return udev_device_set_sysattr_value($self->{_device}, $sysattr, $value);
}


sub has_tag {
    my $self = shift;
    my $tag = shift;

    return udev_device_has_tag($self->{_device}, $tag);
}



sub get_parent {
    my $self = shift;

    my $device = udev_device_get_parent( $self->{_device} );
    if(defined($device)) {
        udev_device_ref($device);

        return Udev::FFI::Device->new( $device );
    }

    return undef;
}


sub get_parent_with_subsystem_devtype {
    my $self = shift;
    my $subsystem = shift;
    my $devtype = shift;

    my $device = udev_device_get_parent_with_subsystem_devtype( $self->{_device}, $subsystem, $devtype );
    if(defined($device)) {
        udev_device_ref($device);

        return Udev::FFI::Device->new( $device );
    }

    return undef;
}



sub get_devlinks_list_entries {
    my $self = shift;

    return get_entries( udev_device_get_devlinks_list_entry( $self->{_device} ) );
}


sub get_properties_list_entries {
    my $self = shift;

    return get_entries( udev_device_get_properties_list_entry( $self->{_device} ) );
}


sub get_tags_list_entries {
    my $self = shift;

    return get_entries( udev_device_get_tags_list_entry( $self->{_device} ) );
}


sub get_sysattr_list_entries {
    my $self = shift;

    return get_entries( udev_device_get_sysattr_list_entry( $self->{_device} ) );
}



sub DESTROY {
    my $self = shift;

    udev_device_unref( $self->{_device} );
}



1;