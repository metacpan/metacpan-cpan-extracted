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
    my $self = shift;
    my $subsystem = shift;

    if(0 != udev_enumerate_add_match_subsystem($self->{_enumerate}, $subsystem)) {
        return 0;
    }

    return 1;
}


sub add_nomatch_subsystem {
    my $self = shift;
    my $subsystem = shift;

    if(0 != udev_enumerate_add_nomatch_subsystem($self->{_enumerate}, $subsystem)) {
        return 0;
    }

    return 1;
}


sub add_match_sysattr {
    my $self = shift;
    my $sysattr = shift;
    my $value = shift;

    if(0 != udev_enumerate_add_match_sysattr($self->{_enumerate}, $sysattr, $value)) {
        return 0;
    }

    return 1;
}


sub add_nomatch_sysattr {
    my $self = shift;
    my $sysattr = shift;
    my $value = shift;

    if(0 != udev_enumerate_add_nomatch_sysattr($self->{_enumerate}, $sysattr, $value)) {
        return 0;
    }

    return 1;
}


sub add_match_property {
    my $self = shift;
    my $property = shift;
    my $value = shift;

    if(0 != udev_enumerate_add_match_property($self->{_enumerate}, $property, $value)) {
        return 0;
    }

    return 1;
}


sub add_match_sysname {
    my $self = shift;
    my $sysname = shift;

    if(0 != udev_enumerate_add_match_sysname($self->{_enumerate}, $sysname)) {
        return 0;
    }

    return 1;
}


sub add_match_tag {
    my $self = shift;
    my $tag = shift;

    if(0 != udev_enumerate_add_match_tag($self->{_enumerate}, $tag)) {
        return 0;
    }

    return 1;
}


sub add_match_parent {
    my $self = shift;
    my $parent = shift;

    if(0 != udev_enumerate_add_match_parent($self->{_enumerate}, $parent)) {
        return 0;
    }

    return 1;
}


sub add_match_is_initialized {
    my $self = shift;

    if(0 != udev_enumerate_add_match_is_initialized($self->{_enumerate})) {
        return 0;
    }

    return 1;
}


sub add_syspath {
    my $self = shift;
    my $syspath = shift;

    if(0 != udev_enumerate_add_syspath($self->{_enumerate}, $syspath)) {
        return 0;
    }

    return 1;
}



sub scan_devices {
    my $self = shift;

    if(0 != udev_enumerate_scan_devices($self->{_enumerate})) {
        return 0;
    }

    return 1;
}


sub scan_subsystems {
    my $self = shift;

    if(0 != udev_enumerate_scan_subsystems($self->{_enumerate})) {
        return 0;
    }

    return 1;
}



sub get_list_entries {
    return get_entries( udev_enumerate_get_list_entry($_[0]->{_enumerate}) );
}



sub DESTROY {
    udev_enumerate_unref( $_[0]->{_enumerate} );
}



1;