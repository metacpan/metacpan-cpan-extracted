use strict;
use warnings;
package USB::LibUSB;

use Moo;
use USB::LibUSB::XS;
use USB::LibUSB::Device;
use USB::LibUSB::Device::Handle;
use Carp;


# Export USB::LibUSB::XS constants
use Exporter 'import';
our @EXPORT = @USB::LibUSB::XS::EXPORT;

our $VERSION = '0.07';

has 'ctx' => (
    is => 'ro',
    init_arg => undef,
    writer => '_ctx',
    );

has last_retval => (
    is => 'ro',
    init_arg => undef,
    writer => '_last_retval',
    default => sub {0;},
    );

sub _handle_error {
    my ($self, $rv, $function) = @_;

    if ($rv >= 0) {
        return $rv;
    }
    $function = "libusb_$function";
    my $strerror = libusb_strerror($rv);

    $self->_last_retval($rv);

    croak("error in $function: $strerror");
}

sub BUILD {
    my ($self, @args) = @_;

    my ($rv, $ctx) = USB::LibUSB::XS->init();
    $self->_handle_error($rv, "init");
    $self->_ctx($ctx);
}

sub init {
    return new(@_);
}

sub set_debug {
    my $self = shift;
    $self->ctx()->set_debug(@_);
}

# libusb_open_device_with_vid_pid: create USB::LibUSB::Device::Handle objects

sub exit {
    my $self = shift;
    $self->ctx()->exit();
}

sub get_device_list {
    my $self = shift;
    my $ctx = $self->ctx();
    my ($rv, @dev_list) = $ctx->get_device_list();
    $self->_handle_error($rv, "get_device_list");
    return map USB::LibUSB::Device->new(ctx => $self, device => $_), @dev_list;
}

sub open_device_with_vid_pid {
    my $self = shift;
    my $ctx = $self->ctx();
    my $handle = $ctx->open_device_with_vid_pid(@_);
    if (not defined $handle) {
        croak "Error in libusb_open_device_with_vid_pid.",
        " use libusb_open for detailed error message.";
    }
    return USB::LibUSB::Device::Handle->new(ctx => $self, handle => $handle);
}

sub open_device_with_vid_pid_unique {
    my ($self, $target_vid, $target_pid) = @_;
    
    my $vid_pid_string = sprintf("%04x:%04x", $target_vid, $target_pid);

    my @device_list = $self->get_device_list();

    @device_list = grep {
        my $dev = $_;
        my $desc = $dev->get_device_descriptor();
        ($desc->{idVendor} == $target_vid
         && $desc->{idProduct} == $target_pid);
    } @device_list;

    my $num_devs = @device_list;
    
    if ($num_devs == 0) {
        croak "did not find any device with vid:pid = $vid_pid_string.";
    }
    
    if ($num_devs > 1) {
        croak "non-unique vid:pid combination $vid_pid_string. ".
            "Found $num_devs device with this combination.";
    } 
    
    return $device_list[0]->open();
}

sub open_device_with_vid_pid_serial {
    my ($self, $target_vid, $target_pid, $target_serial_number) = @_;
    
    my $vid_pid_string = sprintf("%04x:%04x", $target_vid, $target_pid);

    my @device_list = $self->get_device_list();

    if (@device_list == 0) {
        croak "did not find any devices";
    }

    my $valid_device;
    
    for my $dev (@device_list) {
        my $desc = $dev->get_device_descriptor();
        my $vid = $desc->{idVendor};
        my $pid = $desc->{idProduct};
        
        if ($vid != $target_vid || $pid != $target_pid) {
            next;
        }

        # correct vid and pid. Look at serial number.
        my $iserial = $desc->{iSerialNumber};
        if ($iserial == 0) {
            croak "device with vid/pid = $vid_pid_string does have a serial number.";
        }

        my $handle = $dev->open();
        my $serial_number = $handle->get_string_descriptor_ascii(
            $iserial, 1000
            );
        
        if ($serial_number eq $target_serial_number) {
            if (defined $valid_device) {
                croak "non-unique serial number";
            }
            $valid_device = $dev;
        }
        $handle->close();
    }
    
    if (not defined $valid_device) {
        croak "did not find any device with pid:vid = $vid_pid_string".
            " and serial number $target_serial_number.";
    }
    
    return $valid_device->open();
}

1;

=head1 NAME

USB::LibUSB - Perl interface to the libusb-1.0 API.

=head1 SYNOPSIS

 use USB::LibUSB;

 #
 # simple program to list all devices on the USB
 #
 
 my $ctx = USB::LibUSB->init();
 my @devices = $ctx->get_device_list();
 
 for my $dev (@devices) {
     my $bus_number = $dev->get_bus_number();
     my $device_address = $dev->get_device_address();
     my $desc = $dev->get_device_descriptor();
     my $idVendor = $desc->{idVendor};
     my $idProduct = $desc->{idProduct};
     
     printf("Bus %03d Device %03d: ID %04x:%04x\n", $bus_number,
            $device_address, $idVendor, $idProduct);
 }
    
 #
 # Synchronous bulk transfers
 #

 my $ctx = USB::LibUSB->init();
 my $handle = $ctx->open_device_with_vid_pid(0x1111, 0x2222);

 $handle->set_auto_detach_kernel_driver(1); # Linux only

 # We want to use interface 0
 $handle->claim_interface(0);

 $handle->bulk_transfer_write($endpoint, $data, $timeout);
 my $data = $handle->bulk_transfer_read($endpoint, $length, $timeout);
 

=head1 DESCRIPTION

This module provides a Perl interface to the libusb-1.0 API.
It provides access to most basic libusb functionality including read-out of
device descriptors and synchronous device I/O. 

The design of the module is basically a two-tier system:

=over

=item L<USB::LibUSB::XS>

Raw XS interface, stay as close at possible to the libusb API. Not intended to
be used directly.

=item USB::LibUSB

Based on USB::LibUSB::XS, adds convenient error handling and additional
high-level functionality (e.g. device discovery with vid, pid and serial
number). Easy to build more functionality without knowing about XS.

=back

=head1 INSTALLATION

=head2 Prerequisites

=head3 Linux/UNIX

This requires libusb (>= 1.0.17) development files and pkg-config installed.

On Debian like B<Linux>:

 $ apt-get install libusb-1.0-0-dev pkg-config

On L<Cygwin|https://www.cygwin.com/> you need the pkg-config, libusb1.0-devel
and libcrypt-devel packages.

=head3 Windows

On Windows you have to manually download the libusb binaries from
L<http://libusb.info> and extract them somewhere.

Assuming that the location of the extracted libusb folder is
F<C:\Users\simon\libusb-1.0>, you need to set the
C<USB_LIBUSB_INCLUDE> and C<USB_LIBUSB_LIB> environment variables as follows:

 > SET USB_LIBUSB_INCLUDE=-IC:\Users\simon\libusb-1.0\include\libusb-1.0
 > SET USB_LIBUSB_LIB=-lC:\Users\simon\libusb-1.0\MinGW64\dll\libusb-1.0.dll.a

You will also need to add

 C:\Users\simon\libusb-1.0\MinGW64\dll

to the B<Path> environment variable.

For StrawberryPerl, version 5.26 or newer is required
(see L<https://rt.cpan.org/Public/Bug/Display.html?id=121219>).

=head4 Driver Installation

On Windows you need an additional driver to use a device with libusb. See
the L<Windows|https://github.com/libusb/libusb/wiki/Windows> section in the
libusb wiki.

=head2 Building USB::LibUSB

The rest of the installation can be done by a CPAN client like cpanm:

 $ cpanm USB::LibUSB

 
=head1 METHODS/FUNCTIONS

=head2 Library initialization/deinitialization

=head3 set_debug

 $ctx->set_debug(LIBUSB_LOG_LEVEL_DEBUG);

=head3 init

 my $ctx = USB::LibUSB->init();

=head3 exit

 $ctx->exit();

=head3 last_retval

 my $retval = $ctx->last_retval();

Get return value of last called libusb function.

=head2 Device handling and enumeration

=head3 get_device_list

 my @device_list = $ctx->get_device_list();

Returned elements are USB::LibUSB::Device objects.

=head3 get_bus_number

 my $bus_number = $dev->get_bus_number();

=head3 get_port_number

 my $port_number = $dev->get_port_number();

=head3 get_port_numbers

 my @port_numbers = $dev->get_port_numbers();

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

 $dev->ref_device();

=head3 unref_device

 $dev->unref_device();

=head3 open

 my $handle = $dev->open();

Return a USB::LibUSB::Device::Handle object.

=head3 open_device_with_vid_pid

 my $handle = $ctx->open_device_with_vid_pid(0x1111, 0x2222);

Return a USB::LibUSB::Device::Handle object. If the vid:pid combination is not
unique, return the first device which is found.

=head3 open_device_with_vid_pid_unique

 my $handle = $ctx->open_device_with_vid_pid_unique(0x1111, 0x2222);

Like C<open_device_with_vid_pid>, but croak in case of multiple devices with
this vid:pid combination.

=head3 open_device_with_vid_pid_serial

 my $handle = $ctx->open_device_with_vid_pid_serial(0x0957, 0x0607, "MY47000419");

Like C<open_device_with_vid_pid>, but also requires a serial number.
 
=head3 close

 $handle->close();

=head3 get_device

 my $dev = $handle->get_device();

=head3 get_configuration

 my $config = $handle->get_configuration();

=head3 set_configuration

 $handle->set_configuration($config);

=head3 claim_interface

 $handle->claim_interface($interface_number);

=head3 release_interface

 $handle->release_interface($interface_number);

=head3 set_interface_alt_setting

 $handle->set_interface_alt_setting($interface_number, $alternate_setting);

=head3 clear_halt

 $handle->clear_halt($endpoint);

=head3 reset_device

 $handle->reset_device();

=head3 kernel_driver_active

 my $is_active = $handle->kernelt_driver_active($interface_number);

=head3 detach_kernel_driver

 $handle->detach_kernel_driver($interface_number);

=head3 attach_kernel_driver

 $handle->attach_kernel_driver($interface_number);

=head3 set_auto_detach_kernel_driver

 $handle->set_auto_detach_kernel_driver($enable);

Throws exception on Windows and Darwin.

=head2 Miscellaneous

=head3 libusb_has_capability

 my $has_cap = libusb_has_capability($capability);

=head3 libusb_error_name

 my $error_name = libusb_error_name($error_code);

=head3 libusb_get_version

 my $version_hash = libusb_get_version();

Return hashref C<$version_hash> with the following keys:

=over

=item major

=item minor

=item micro

=item nano

=item rc

=back


=head3 libusb_setlocale

 my $rv = libusb_setlocale($locale);

=head3 libusb_strerror

 my $strerror = libusb_strerror($error_code);

=head2 USB descriptors

All descriptors are returned as hash references.

=head3 get_device_descriptor

 my $desc = $dev->get_device_descriptor();

Return hashref C<$desc> with the following keys

=over

=item bLength

=item bDescriptorType

=item bcdUSB

=item bDeviceClass

=item bDeviceSubClass

=item bDeviceProtocol

=item bMaxPacketSize0

=item idVendor

=item idProduct

=item bcdDevice

=item iManufacturer

=item iProduct

=item iSerialNumber

=item bNumConfigurations

=back

All keys hold a scalar value.

=head3 get_active_config_descriptor

 my $config = $dev->get_active_config_descriptor();

Return hashref C<$config> with the following keys:

=over

=item bLength

=item bDescriptorType

=item wTotalLength

=item bNumInterfaces

=item bConfigurationValue

=item iConfiguration

=item bmAttributes

=item MaxPower

=item interface

=item extra

=back

With the exception of B<interface>, all values are scalars.
B<interface> holds an arrayref of bNumInterfaces interface descriptors. Each interface consists of an array of alternate settings. These are hashrefs with the
following keys:

=over

=item bLength

=item bDescriptorType

=item bInterfaceNumber

=item bAlternateSetting

=item bNumEndpoints

=item bInterfaceClass

=item bInterfaceSubClass

=item bInterfaceProtocol

=item iInterface

=item endpoint

=item extra

=back

With the exception of B<endpoint>, all values are scalars.
B<endpoint> holds an arrayref of endpoint descriptors. These are hashrefs with the
following keys:

=over

=item bLength

=item bDescriptorType

=item bEndpointAddress

=item bmAttributes

=item wMaxPacketSize

=item bInterval

=item bRefresh

=item bSynchAddress

=item extra

=back

All values are scalars. If the endpoint supports USB 3.0 SuperSpeed, the
hashref will contain an additional key C<superspeed> which holds a
SuperSpeed Endpoint Companion descriptor with the following keys:

=over

=item bLength

=item bDescriptorType

=item bMaxBurst

=item bmAttributes

=item wBytesPerInterval

=back

=head4 Example

Dump C<$config> with L<YAML::XS>:

 use YAML::XS;
 print Dump($config);
 
For a B<Linux Foundation 3.0 root hub>:

 ---
 MaxPower: 0
 bConfigurationValue: 1
 bDescriptorType: 2
 bLength: 9
 bNumInterfaces: 1
 bmAttributes: 224
 extra: ~
 iConfiguration: 0
 interface:
 - - bAlternateSetting: 0
     bDescriptorType: 4
     bInterfaceClass: 9
     bInterfaceNumber: 0
     bInterfaceProtocol: 0
     bInterfaceSubClass: 0
     bLength: 9
     bNumEndpoints: 1
     endpoint:
     - bDescriptorType: 5
       bEndpointAddress: 129
       bInterval: 12
       bLength: 7
       bRefresh: 0
       bSynchAddress: 0
       bmAttributes: 3
       extra: "\x060\0\0\x02\0"
       ss_endpoint_companion:
         bDescriptorType: 48
         bLength: 6
         bMaxBurst: 0
         bmAttributes: 0
         wBytesPerInterval: 2
       wMaxPacketSize: 4
     extra: ~
     iInterface: 0
 wTotalLength: 31
 

=head3 get_config_descriptor

 my $config = $dev->get_config_descriptor($config_index);

Return config descriptor as hashref.

=head3 get_config_descriptor_by_value

 my $config = $dev->get_config_descriptor_by_value($bConfigurationValue);

Return config descriptor as hashref.

=head3 get_bos_descriptor

 my $bos = $handle->get_bos_descriptor();

Return BOS descriptor as hashref with the following keys:

=over

=item bLength

=item bDescriptorType

=item wTotalLength

=item bNumDeviceCaps

=item dev_capability

=back

C<dev_capability> holds an arrayref of BOS Device Capability descriptors. They
have the following keys:

=over

=item bLength

=item bDescriptorType

=item bDevCapabilityType

=item dev_capability_data

=back

Additional parsing of the capability data is performed if C<bDevCapabilityType>
has one of the following values:

=over

=item LIBUSB_BT_USB_2_0_EXTENSION

The hashref will contain a key C<usb_2_0_extension>.

=item  LIBUSB_BT_SS_USB_DEVICE_CAPABILITY 

The hashref will contain a key C<ss_usb_device_capability>.

=item LIBUSB_BT_CONTAINER_ID

The hashref will contain a key C<container_id>.

=back

=head4 Example

Dump C<$bos> with L<YAML::XS>:

 use YAML::XS;
 print Dump($bos);
 
For a B<Linux Foundation 3.0 root hub>:

 bDescriptorType: 15
 bLength: 5
 bNumDeviceCaps: 1
 dev_capability:
 - bDescriptorType: 16
   bDevCapabilityType: 3
   bLength: 10
   dev_capability_data: "\x02\b\0\x03\0\0\0"
   ss_usb_device_capability:
     bDescriptorType: 16
     bDevCapabilityType: 3
     bFunctionalitySupport: 3
     bLength: 10
     bU1DevExitLat: 0
     bU2DevExitLat: 0
     bmAttributes: 2
     wSpeedSupported: 8
 wTotalLength: 15

=head3 get_string_descriptor_ascii

 my $data = $handle->get_string_descriptor_ascii($desc_index, $length);

=head3 get_descriptor

 my $data = $handle->get_descriptor($desc_type, $desc_index, $length);

=head3 get_string_descriptor

 my $data = $handle->get_string_descriptor($desc_index, $langid, $length);

 
=head2 Device hotplug event notification

To be implemented.

=head2 Asynchronous device I/O

To be implemented.

=head2 Polling and timing

To be implemented.

=head2 Synchronous device I/O

=head3 control_transfer_write

 $handle->control_transfer_write($bmRequestType, $bRequest, $wValue, $wIndex, $data, $timeout);

=head3 control_transfer_read

 my $data = $handle->control_transfer_read($bmRequestType, $bRequest, $wValue, $wIndex, $length, $timeout);
 
=head3 bulk_tranfer_write

 my $transferred = $handle->bulk_transfer_write($endpoint, $data, $timeout);
 
=head3 bulk_transfer_read

 my $data = $handle->bulk_transfer_read($endpoint, $length, $timeout);
 
=head3 interrupt_transfer_write

 my $transferred = $handle->interrupt_transfer_write($endpoint, $data, $timeout);

=head3 interrupt_transfer_read

 my $data = $handle->interrupt_transfer_read($endpoint, $length, $timeout);

=head1 REPORTING BUGS

Please report bugs at L<https://github.com/lab-measurement/USB-LibUSB/issues>.

=head1 CONTACT

Feel free to contact us at the #labmeasurement channel on Freenode IRC.

=head1 AUTHOR

Simon Reinhardt, E<lt>simon.reinhardt@physik.uni-r.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Simon Reinhardt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
