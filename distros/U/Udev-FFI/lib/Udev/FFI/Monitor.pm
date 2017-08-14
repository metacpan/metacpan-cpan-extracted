package Udev::FFI::Monitor;

use strict;
use warnings;

use IO::Select;

use Udev::FFI::FFIFunctions;
use Udev::FFI::Device;


sub new {
    my $class = shift;

    my $self = {
        _monitor => shift,
        _is_started => 0
    };

    bless $self, $class;

    return $self;
}



sub get_udev {
    my $self = shift;

    return udev_monitor_get_udev($self->{_monitor});
}



sub set_receive_buffer_size {
    my $self = shift;
    my $bytes = shift;

    if(0 != udev_monitor_set_receive_buffer_size($self->{_monitor}, $bytes)) {
        return 0;
    }

    return 1;
}



sub filter_by_subsystem_devtype {
    my $self = shift;
    my $subsystem = shift;
    my $devtype = shift;

    return 0
        if 1 == $self->{_is_started};

    if(0 != udev_monitor_filter_add_match_subsystem_devtype($self->{_monitor}, $subsystem, $devtype)) {
        return 0;
    }

    return 1;
}



sub filter_by_tag {
    my $self = shift;
    my $tag = shift;

    return 0
        if 1 == $self->{_is_started};

    if(0 != udev_monitor_filter_add_match_tag($self->{_monitor}, $tag)) {
        return 0;
    }

    return 1;
}



sub filter_update {
    my $self = shift;

    if(0 != udev_monitor_filter_update($self->{_monitor})) {
        return 0;
    }

    return 1;
}



sub filter_remove {
    my $self = shift;

    if(0 != udev_monitor_filter_remove($self->{_monitor})) {
        return 0;
    }

    return 1;
}



sub start {
    my $self = shift;

    return 1
        if $self->{_is_started};

    if(0 != udev_monitor_enable_receiving( $self->{_monitor} )) {
        return 0;
    }

    my $fd = udev_monitor_get_fd($self->{_monitor});

    my $fdh;
    if(!open($fdh, "<&=", $fd)) {
        return 0;
    }

    $self->{_select} = IO::Select->new();
    $self->{_select}->add($fdh);

    $self->{_is_started} = 1;
    return 1;
}



sub poll {
    my $self = shift;
    my $timeout = shift;

    unless($self->{_is_started}) {
        die "udev monitor is not running";
    }

    if($self->{_select}->can_read($timeout)) {
        my $device = udev_monitor_receive_device( $self->{_monitor} );

        return Udev::FFI::Device->new( $device );
    }

    return undef;
}



sub is_started {
    my $self = shift;

    return $self->{_is_started};
}



sub DESTROY {
    my $self = shift;

    udev_monitor_unref( $self->{_monitor} );
}



1;