use strict;
use warnings;
package USB::LibUSB::Device;

use Moo;
use Carp;

our $VERSION = '0.05';
    
has 'ctx' => (
    is => 'ro',
    required => 1,
    );

has 'device' => (
    is => 'ro',
    required => 1,
    );

sub _handle_error {
    my $self = shift;
    return $self->ctx()->_handle_error(@_);
}


sub get_bus_number {
    my $self = shift;
    return $self->device()->get_bus_number(@_);
}

sub get_port_number {
    my $self = shift;
    return $self->device()->get_port_number(@_);
}

sub get_port_numbers {
    my $self = shift;
    my ($rv, @numbers) = $self->device()->get_port_numbers(@_);
    $self->_handle_error($rv, "get_port_numbers");
    return @numbers;
}

sub get_parent {
    my $self = shift;
    my $parent = $self->device()->get_parent(@_);
    return USB::LibUSB::Device->new(ctx => $self->ctx(), device => $parent);
}

sub get_device_address {
    my $self = shift;
    return $self->device()->get_device_address(@_);
}

sub get_device_speed {
    my $self = shift;
    return $self->device()->get_device_speed(@_);
}

sub get_max_packet_size {
    my $self = shift;
    my $size = $self->device()->get_max_packet_size(@_);
    $self->_handle_error($size, "get_max_packet_size");
    return $size;
}

sub get_max_iso_packet_size {
    my $self = shift;
    my $size = $self->device()->get_max_iso_packet_size(@_);
    $self->_handle_error($size, "get_max_iso_packet_size");
    return $size;
}


sub ref_device {
    my $self = shift;
    $self->device()->ref_device(@_);
    return $self;
}

sub unref_device {
    my $self = shift;
    return $self->device()->unref_device(@_);
}

sub open {
    my $self = shift;
    my ($rv, $handle) = $self->device()->open(@_);
    $self->_handle_error($rv, "open");
    return USB::LibUSB::Device::Handle->new(
        ctx => $self->ctx(), handle => $handle);
}

sub get_device_descriptor {
    my $self = shift;
    my ($rv, $desc) = $self->device()->get_device_descriptor(@_);
    $self->_handle_error($rv, "get_device_descriptor");
    return $desc;
}

sub get_active_config_descriptor {
    my $self = shift;
    my ($rv, $desc) = $self->device()->get_active_config_descriptor(
        $self->ctx()->ctx(), @_);
    $self->_handle_error($rv, "get_active_config_descriptor");
    return $desc;
}

sub get_config_descriptor {
    my $self = shift;
    my ($rv, $desc) = $self->device()->get_config_descriptor(
        $self->ctx()->ctx(), @_);
    $self->_handle_error($rv, "get_config_descriptor");
    return $desc;
}



    
    
    
    
1;
