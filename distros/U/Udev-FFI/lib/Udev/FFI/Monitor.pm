package Udev::FFI::Monitor;

use strict;
use warnings;

use Errno qw(EPERM);
use Carp qw(croak);
use IO::Select;

use Udev::FFI::Functions qw(:all);
use Udev::FFI::Device;



sub new {
    my $class = shift;

    my $self = {
        _monitor => shift,
        _udev    => shift,
        _is_started => 0
    };

    bless($self, $class);

    return $self;
}



sub get_udev {
    return $_[0]->{_udev};
}



sub set_receive_buffer_size {
    # self, bytes
    if (0 == udev_monitor_set_receive_buffer_size($_[0]->{_monitor}, $_[1])) {
        return 1;
    }

    return 0;
}



sub filter_by_subsystem_devtype {
    if (1 == $_[0]->{_is_started}) {
        $! = EPERM;
        return 0;
    }

    # self, subsystem, devtype
    if (0 == ($! = udev_monitor_filter_add_match_subsystem_devtype($_[0]->{_monitor}, $_[1], $_[2]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}



sub filter_by_tag {
    if (1 == $_[0]->{_is_started}) {
        $! = EPERM;
        return 0;
    }

    # self, tag
    if (0 == ($! = udev_monitor_filter_add_match_tag($_[0]->{_monitor}, $_[1]))) {
        return 1;
    }

    $! = -$!;
    return 0;
}



sub filter_update {
    if (0 == ($! = udev_monitor_filter_update($_[0]->{_monitor}))) {
        return 1;
    }

    $! = -$!;
    return 0;
}



sub filter_remove {
    if (0 != udev_monitor_filter_remove($_[0]->{_monitor})) {
        return 1;
    }

    $! = -$!;
    return 0;
}



sub start {
    my $self = shift;

    return 1
        if $self->{_is_started};

    if (0 != ($! = udev_monitor_enable_receiving($self->{_monitor}))) {
        $! = -$!;
        return 0;
    }

    my $fd = udev_monitor_get_fd($self->{_monitor});

    my $fdh;
    unless (open($fdh, "<&=", $fd)) {
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

     croak('udev monitor is not running')
        unless $self->{_is_started};

    if ($self->{_select}->can_read($timeout)) {
        my $device = udev_monitor_receive_device($self->{_monitor});

        return Udev::FFI::Device->new($device);
    }

    return undef;
}



sub is_started {
    return $_[0]->{_is_started};
}



sub DESTROY {
    udev_monitor_unref($_[0]->{_monitor});
}



1;



__END__



=head1 NAME

Udev::FFI::Monitor

=head1 SYNOPSIS

    use Udev::FFI;
    
    my $udev = Udev::FFI->new() or
        die("Can't create Udev::FFI object: $@");
    
    my $monitor = $udev->new_monitor() or
        die("Can't create udev monitor: $@");
    
    $monitor->filter_by_subsystem_devtype('usb');
    
    $monitor->start();
    
    for (;;) {
        my $device = $monitor->poll(); # blocking read
    
        print('ACTION: '.$device->get_action()."\n");
        print('SYSNAME: '.$device->get_sysname()."\n");
        print('DEVPATH: '.$device->get_devpath()."\n");
    }

=head1 METHODS

=head2 set_receive_buffer_size( BYTES )

Set the size of the kernel socket buffer. This call needs the
appropriate privileges to succeed.

Returns: 1 on success, otherwise 0 on error.

=head2 filter_by_subsystem_devtype( SUBSYSTEM [, DEVTYPE] )

=head2 filter_by_tag( TAG )

=head2 filter_update()

=head2 filter_remove()

=head2 start()

=head2 poll( [TIMEOUT] )

=head2 is_started()

=head2 get_udev()

=head1 SEE ALSO

L<Udev::FFI> main Udev::FFI documentation

=cut
