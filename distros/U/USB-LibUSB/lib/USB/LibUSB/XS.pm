package USB::LibUSB::XS;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    libusb_has_capability
    libusb_error_name
    libusb_get_version
    libusb_setlocale
    libusb_strerror

	LIBUSBX_API_VERSION
	LIBUSB_API_VERSION
	LIBUSB_BM_LPM_SUPPORT
	LIBUSB_BM_LTM_SUPPORT
	LIBUSB_BT_CONTAINER_ID
	LIBUSB_BT_CONTAINER_ID_SIZE
	LIBUSB_BT_SS_USB_DEVICE_CAPABILITY
	LIBUSB_BT_SS_USB_DEVICE_CAPABILITY_SIZE
	LIBUSB_BT_USB_2_0_EXTENSION
	LIBUSB_BT_USB_2_0_EXTENSION_SIZE
	LIBUSB_BT_WIRELESS_USB_DEVICE_CAPABILITY
	LIBUSB_CAP_HAS_CAPABILITY
	LIBUSB_CAP_HAS_HID_ACCESS
	LIBUSB_CAP_HAS_HOTPLUG
	LIBUSB_CAP_SUPPORTS_DETACH_KERNEL_DRIVER
	LIBUSB_CLASS_APPLICATION
	LIBUSB_CLASS_AUDIO
	LIBUSB_CLASS_COMM
	LIBUSB_CLASS_CONTENT_SECURITY
	LIBUSB_CLASS_DATA
	LIBUSB_CLASS_DIAGNOSTIC_DEVICE
	LIBUSB_CLASS_HID
	LIBUSB_CLASS_HUB
	LIBUSB_CLASS_IMAGE
	LIBUSB_CLASS_MASS_STORAGE
	LIBUSB_CLASS_PERSONAL_HEALTHCARE
	LIBUSB_CLASS_PER_INTERFACE
	LIBUSB_CLASS_PHYSICAL
	LIBUSB_CLASS_PRINTER
	LIBUSB_CLASS_PTP
	LIBUSB_CLASS_SMART_CARD
	LIBUSB_CLASS_VENDOR_SPEC
	LIBUSB_CLASS_VIDEO
	LIBUSB_CLASS_WIRELESS
	LIBUSB_CONTROL_SETUP_SIZE
	LIBUSB_DT_BOS
	LIBUSB_DT_BOS_MAX_SIZE
	LIBUSB_DT_BOS_SIZE
	LIBUSB_DT_CONFIG
	LIBUSB_DT_CONFIG_SIZE
	LIBUSB_DT_DEVICE
	LIBUSB_DT_DEVICE_CAPABILITY
	LIBUSB_DT_DEVICE_CAPABILITY_SIZE
	LIBUSB_DT_DEVICE_SIZE
	LIBUSB_DT_ENDPOINT
	LIBUSB_DT_ENDPOINT_AUDIO_SIZE
	LIBUSB_DT_ENDPOINT_SIZE
	LIBUSB_DT_HID
	LIBUSB_DT_HUB
	LIBUSB_DT_HUB_NONVAR_SIZE
	LIBUSB_DT_INTERFACE
	LIBUSB_DT_INTERFACE_SIZE
	LIBUSB_DT_PHYSICAL
	LIBUSB_DT_REPORT
	LIBUSB_DT_SS_ENDPOINT_COMPANION
	LIBUSB_DT_SS_ENDPOINT_COMPANION_SIZE
	LIBUSB_DT_STRING
	LIBUSB_DT_SUPERSPEED_HUB
	LIBUSB_ENDPOINT_ADDRESS_MASK
	LIBUSB_ENDPOINT_DIR_MASK
	LIBUSB_ENDPOINT_IN
	LIBUSB_ENDPOINT_OUT
	LIBUSB_ERROR_ACCESS
	LIBUSB_ERROR_BUSY
	LIBUSB_ERROR_COUNT
	LIBUSB_ERROR_INTERRUPTED
	LIBUSB_ERROR_INVALID_PARAM
	LIBUSB_ERROR_IO
	LIBUSB_ERROR_NOT_FOUND
	LIBUSB_ERROR_NOT_SUPPORTED
	LIBUSB_ERROR_NO_DEVICE
	LIBUSB_ERROR_NO_MEM
	LIBUSB_ERROR_OTHER
	LIBUSB_ERROR_OVERFLOW
	LIBUSB_ERROR_PIPE
	LIBUSB_ERROR_TIMEOUT
	LIBUSB_FULL_SPEED_OPERATION
	LIBUSB_HIGH_SPEED_OPERATION
	LIBUSB_HOTPLUG_ENUMERATE
	LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED
	LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT
	LIBUSB_HOTPLUG_MATCH_ANY
	LIBUSB_ISO_SYNC_TYPE_ADAPTIVE
	LIBUSB_ISO_SYNC_TYPE_ASYNC
	LIBUSB_ISO_SYNC_TYPE_MASK
	LIBUSB_ISO_SYNC_TYPE_NONE
	LIBUSB_ISO_SYNC_TYPE_SYNC
	LIBUSB_ISO_USAGE_TYPE_DATA
	LIBUSB_ISO_USAGE_TYPE_FEEDBACK
	LIBUSB_ISO_USAGE_TYPE_IMPLICIT
	LIBUSB_ISO_USAGE_TYPE_MASK
	LIBUSB_LOG_LEVEL_DEBUG
	LIBUSB_LOG_LEVEL_ERROR
	LIBUSB_LOG_LEVEL_INFO
	LIBUSB_LOG_LEVEL_NONE
	LIBUSB_LOG_LEVEL_WARNING
	LIBUSB_LOW_SPEED_OPERATION
	LIBUSB_RECIPIENT_DEVICE
	LIBUSB_RECIPIENT_ENDPOINT
	LIBUSB_RECIPIENT_INTERFACE
	LIBUSB_RECIPIENT_OTHER
	LIBUSB_REQUEST_CLEAR_FEATURE
	LIBUSB_REQUEST_GET_CONFIGURATION
	LIBUSB_REQUEST_GET_DESCRIPTOR
	LIBUSB_REQUEST_GET_INTERFACE
	LIBUSB_REQUEST_GET_STATUS
	LIBUSB_REQUEST_SET_ADDRESS
	LIBUSB_REQUEST_SET_CONFIGURATION
	LIBUSB_REQUEST_SET_DESCRIPTOR
	LIBUSB_REQUEST_SET_FEATURE
	LIBUSB_REQUEST_SET_INTERFACE
	LIBUSB_REQUEST_SET_SEL
	LIBUSB_REQUEST_SYNCH_FRAME
	LIBUSB_REQUEST_TYPE_CLASS
	LIBUSB_REQUEST_TYPE_RESERVED
	LIBUSB_REQUEST_TYPE_STANDARD
	LIBUSB_REQUEST_TYPE_VENDOR
	LIBUSB_SET_ISOCH_DELAY
	LIBUSB_SPEED_FULL
	LIBUSB_SPEED_HIGH
	LIBUSB_SPEED_LOW
	LIBUSB_SPEED_SUPER
	LIBUSB_SPEED_UNKNOWN
	LIBUSB_SUCCESS
	LIBUSB_SUPER_SPEED_OPERATION
	LIBUSB_TRANSFER_ADD_ZERO_PACKET
	LIBUSB_TRANSFER_CANCELLED
	LIBUSB_TRANSFER_COMPLETED
	LIBUSB_TRANSFER_ERROR
	LIBUSB_TRANSFER_FREE_BUFFER
	LIBUSB_TRANSFER_FREE_TRANSFER
	LIBUSB_TRANSFER_NO_DEVICE
	LIBUSB_TRANSFER_OVERFLOW
	LIBUSB_TRANSFER_SHORT_NOT_OK
	LIBUSB_TRANSFER_STALL
	LIBUSB_TRANSFER_TIMED_OUT
	LIBUSB_TRANSFER_TYPE_BULK
	LIBUSB_TRANSFER_TYPE_CONTROL
	LIBUSB_TRANSFER_TYPE_INTERRUPT
	LIBUSB_TRANSFER_TYPE_ISOCHRONOUS
	LIBUSB_TRANSFER_TYPE_MASK
);

our $VERSION = '0.04';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&USB::LibUSB::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('USB::LibUSB', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

USB::LibUSB::XS - Raw XS bindings to the L<libusb-1.0|http://libusb.info/> API.

=head1 SYNOPSIS

  # import all the constants and non-method subroutines
  use USB::LibUSB::XS;

  my ($rv, $ctx) = USB::LibUSB::XS->init();
  $ctx->set_debug(LIBUSB_LOG_LEVEL_WARNING);
 
  my ($vendor_id, $product_id) = (0x1234, 0x5678);
  my $handle = $ctx->open_device_with_vid_pid($vendor_id, $product_id);

  $rv = $handle->set_auto_detach_kernel_driver(1);
  $rv = $handle->claim_interface($interface);

  $rv = $handle->bulk_transfer_write($endpoint, "some data", $timeout);

  ($rv, my $data) = $handle->bulk_transfer_read($endpoint, $length, $timeout);

=head1 DESCRIPTION

USB::LibUSB::XS provides the raw XS access to the libusb-1.0 API, which can then be used
by modules like L<USB::LibUSB>, which is a more user frienly interface.


=head1 METHODS/FUNCTIONS

The following API is documented in the excellent
L<libusb documentation|http://libusb.sourceforge.net/api-1.0/>.

=head2 Library initialization/deinitialization

Implementation status: complete.

=head3 set_debug

 $ctx->set_debug(LIBUSB_LOG_LEVEL_DEBUG);

=head3 init

 my ($rv, $ctx) = USB::LibUSB::XS->init();

=head3 exit

 $ctx->exit();

=head2 Device handling and enumeration

Implementation status: complete.

=head3 get_device_list

 my ($rv, @device_list) = $ctx->get_device_list();

C<@device_list> contains USB::LibUSB::XS::Device objects.

=head3 get_bus_number

 my $bus_number = $dev->get_bus_number();

=head3 get_port_number

 my $port_number = $dev->get_port_number();

=head3 get_port_numbers

 my ($rv, @port_numbers) = $dev->get_port_numbers();

=head3 get_parent

 my $parent_dev = $dev->get_parent();

=head3 get_device_address

 my $address = $dev->get_device_address();

=head3 get_device_speed

 my $speed = $dev->get_device_speed();

=head3 get_max_packet_size

 my $size = $dev->get_max_packet_size($endpoint);

=head3 get_max_iso_packet_size

 my $size = $dev->get_max_iso_packet_size($endpoint);

=head3 ref_device

 $dev = $dev->ref_device();

=head3 unref_device

 $dev->unref_device();

=head3 open

 my ($rv, $handle) = $dev->open();

Return a USB::LibUSB::XS::Device::Handle object in C<$handle> if C<$rv> is 0.

=head3 open_device_with_vid_pid

 my $handle = $ctx->open_device_with_vid_pid(0x1111, 0x2222);

Return undef on error.

=head3 close

 $handle->close();

=head3 get_device

 my $dev = $hanlde->get_device();

=head3 get_configuration

 my $config = $handle->get_configuration();

=head3 set_configuration

 my $rv = $handle->set_configuration($config);

=head3 claim_interface

 my $rv = $handle->claim_interface($interface_number);

=head3 release_interface

 my $rv = $handle->release_interface($interface_number);

=head3 set_interface_alt_setting

 my $rv = $handle->set_interface_alt_setting($interface_number, $alternate_setting);


=head3 clear_halt

 my $rv = $handle->clear_halt($endpoint);

=head3 reset_device

 my $rv = $handle->reset_device();

=head3 kernel_driver_active

 my $is_active = $handle->kernelt_driver_active($interface_number);

=head3 detach_kernel_driver

 my $rv = $handle->detach_kernel_driver($interface_number);

=head3 attach_kernel_driver

 my $rv = $handle->attach_kernel_driver($interface_number);

=head3 set_auto_detach_kernel_driver

 my $rv = $handle->set_auto_detach_kernel_driver($enable);


=head2 Miscellaneous

Implementation status: complete.

=head3 libusb_has_capability

 my $has_cap = libusb_has_capability($capability);

=head3 libusb_error_name

 my $error_name = libusb_error_name($error_code);

=head3 libusb_get_version

 my $version_hash = libusb_get_version();
 my $major = $version_hash->{major};

=head3 libusb_setlocale

 my $rv = libusb_setlocale($locale);

=head3 libusb_strerror

 my $strerror = libusb_strerror($error_code);

=head2 USB descriptors

Implementation status: complete.

All descriptors are returned as hash references.

=head3 get_device_descriptor

 my ($rv, $desc) = $dev->get_device_descriptor();
 my $iSerialNumber = $desc->{iSerialNumber};

=head3 get_active_config_descriptor

 my ($rv, $config) = $dev->get_active_config_descriptor($ctx);
 my $iConfiguration = $config->{iConfiguration};

=head3 get_config_descriptor

 my ($rv, $config) = $dev->get_config_descriptor($ctx, $config_index);

=head3 get_config_descriptor_by_value

 my ($rv, $config) = $dev->get_config_descriptor_by_value($ctx, $bConfigurationValue);

=head3 get_bos_descriptor

 my ($rv, $bos) = $handle->get_bos_descriptor($ctx);

=head3 get_string_descriptor_ascii

 my ($rv, $data) = $handle->get_string_descriptor_ascii($desc_index, $length);

=head3 get_descriptor

 my ($rv, $data) = $handle->get_descriptor($desc_type, $desc_index, $length);

=head3 get_string_descriptor

 my ($rv, $data) = $handle->get_string_descriptor($desc_index, $langid, $length);

 
=head2 Device hotplug event notification

Implementation status: To be implemented.

=head2 Asynchronous device I/O

Implementation status: To be implemented.

=head2 Polling and timing

Implementation status: To be implemented.

=head2 Synchronous device I/O

Implementation status: complete.

Timeouts are given in milliseconds.

=head3 control_transfer_write

 my $rv = $handle->control_transfer_write($bmRequestType, $bRequest, $wValue, $wIndex, $data, $timeout);

=head3 control_transfer_read

 my ($rv, $data) = $handle->control_transfer_read($bmRequestType, $bRequest, $wValue, $wIndex, $length, $timeout);
 
=head3 bulk_tranfer_write

 my $rv = $handle->bulk_transfer_write($endpoint, $data, $timeout);
 
=head3 bulk_transfer_read

 my ($rv, $data) = $handle->bulk_transfer_read($endpoint, $length, $timeout);
 
=head3 interrupt_transfer_write

 my $rv = $handle->interrupt_transfer_write($endpoint, $data, $timeout);

=head3 interrupt_transfer_read

 my ($rv, $data) = $handle->interrupt_transfer_read($endpoint, $length, $timeout);

=head1 REPORTING BUGS

Please report bugs at L<https://github.com/lab-measurement/USB-LibUSB/issues>.

=head1 CONTACT

Feel free to contact us at the #labmeasurement channel on Freenode IRC.

=head1 AUTHOR

Simon Reinhardt, E<lt>simon.reinhardt@stud.uni-regensburg.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Simon Reinhardt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
