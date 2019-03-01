use strict;
use warnings;
package USB::LibUSB::Device::Handle;

use Moo;
use Carp;

our $VERSION = '0.06';

has 'ctx' => (
    is => 'ro',
    required => 1,
    );

has 'handle' => (
    is => 'ro',
    required => 1,
    );

sub _handle_error {
    my $self = shift;
    return $self->ctx()->_handle_error(@_);
}

sub close {
    my $self = shift;
    return $self->handle()->close(@_);
}

sub get_device {
    my $self = shift;
    my $device = $self->handle()->get_device(@_);
    return USB::LibUSB::Device->new(ctx => $self->ctx(), device => $device);
}

sub get_configuration {
    my $self = shift;
    my ($rv, $config) = $self->handle()->get_configuration(@_);
    $self->_handle_error($rv, "get_configuration");
    return $config;
}

sub set_configuration {
    my $self = shift;
    my ($rv) = $self->handle()->set_configuration(@_);
    $self->_handle_error($rv, "set_configuration");
}

sub claim_interface {
    my $self = shift;
    my ($rv) = $self->handle()->claim_interface(@_);
    $self->_handle_error($rv, "claim_interface");
}

sub release_interface {
    my $self = shift;
    my ($rv) = $self->handle()->release_interface(@_);
    $self->_handle_error($rv, "release_interface");
}

sub set_interface_alt_setting {
    my $self = shift;
    my ($rv) = $self->handle()->set_interface_alt_setting(@_);
    $self->_handle_error($rv, "set_interface_alt_setting");
}

sub clear_halt {
    my $self = shift;
    my ($rv) = $self->handle()->clear_halt(@_);
    $self->_handle_error($rv, "clear_halt");
}

sub reset_device {
    my $self = shift;
    my ($rv) = $self->handle()->reset_device(@_);
    $self->_handle_error($rv, "reset_device");
}

# Handle kernel drivers

sub kernel_driver_active {
    my $self = shift;
    my ($rv) = $self->handle()->kernel_driver_active(@_);
    $self->_handle_error($rv, "kernel_driver_active");
    return $rv;
}

sub detach_kernel_driver {
    my $self = shift;
    my ($rv) = $self->handle()->detach_kernel_driver(@_);
    $self->_handle_error($rv, "detach_kernel_driver");
}

sub attach_kernel_driver {
    my $self = shift;
    my ($rv) = $self->handle()->attach_kernel_driver(@_);
    $self->_handle_error($rv, "attach_kernel_driver");
}

sub set_auto_detach_kernel_driver {
    my $self = shift;
    my ($rv) = $self->handle()->set_auto_detach_kernel_driver(@_);
    $self->_handle_error($rv, "set_auto_detach_kernel_driver");
}

# Descriptors

sub get_bos_descriptor {
    my $self = shift;
    my ($rv, $bos) = $self->handle()->get_bos_descriptor(
        $self->ctx()->ctx(), @_);
    $self->_handle_error($rv, "get_bos_descriptor");
    return $bos;
}

sub get_string_descriptor_ascii {
    my $self = shift;
    my ($rv, $string) = $self->handle()->get_string_descriptor_ascii(@_);
    $self->_handle_error($rv, "get_string_descriptor_ascii");
    return $string;
}

sub get_descriptor {
    my $self = shift;
    my ($rv, $string) = $self->handle()->get_descriptor(@_);
    $self->_handle_error($rv, "get_descriptor");
    return $string;
}

sub get_string_descriptor {
    my $self = shift;
    my ($rv, $string) = $self->handle()->get_string_descriptor(@_);
    $self->_handle_error($rv, "get_string_descriptor");
    return $string;
}

# Synchronous device I/O

sub control_transfer_write {
    my $self = shift;
    my ($rv) = $self->handle()->control_transfer_write(@_);
    $self->_handle_error($rv, "control_transfer_write");
    return $rv;
}

sub control_transfer_read {
    my $self = shift;
    my ($rv, $data) = $self->handle()->control_transfer_read(@_);
    $self->_handle_error($rv, "control_transfer_read");
    return $data;
}

sub bulk_transfer_write {
    my $self = shift;
    my ($rv, $transferred) = $self->handle()->bulk_transfer_write(@_);
    $self->_handle_error($rv, "bulk_transfer_write");
    return $transferred;
}

sub bulk_transfer_read {
    my $self = shift;
    my ($rv, $data) = $self->handle()->bulk_transfer_read(@_);
    $self->_handle_error($rv, "bulk_transfer_read");
    return $data;
}

sub interrupt_transfer_write {
    my $self = shift;
    my ($rv, $transferred) = $self->handle()->interrupt_transfer_write(@_);
    $self->_handle_error($rv, "interrupt_transfer_write");
    return $transferred;
}

sub interrupt_transfer_read {
    my $self = shift;
    my ($rv, $data) = $self->handle()->interrupt_transfer_read(@_);
    $self->_handle_error($rv, "interrupt_transfer_read");
    return $data;
}

1;
