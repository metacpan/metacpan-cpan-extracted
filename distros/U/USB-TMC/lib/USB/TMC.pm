=head1 NAME

USB::TMC - Perl interface to USB Test & Measurement (USBTMC) backend.

=head1 SYNOPSIS

 use USB::TMC;

 # Open usb connection to  Agilent 34410A digital multimeter
 my $usbtmc = USB::TMC->new(
     vid => 0x0957,
     pid => 0x0607,
     serial => 'MY47000419', # only needed if vid/pid is ambiguous
 );
 
 $usbtmc->write(data => "*CLS\n");
 $usbtmc->write(data => "VOLT:NPLC 10\n");

 print $usbtmc->query(data => ":read?\n", length => 100);
 
 my $capabilities = $usbtmc->get_capabilities();
 my $support_term_char = $capabilities->{support_term_char};

=head1 DESCRIPTION

This module provides a user-space L<USBTMC|http://www.usb.org/developers/docs/devclass_docs/USBTMC_1_006a.zip> driver.

Internally this module is based on L<USB::LibUSB>.

Does not yet support the additional features of USBTMC-USB488. But those could
easily be added if needed.

=head1 METHODS

Errors with USB transfers will result in a croak.

Use L<default timeout|/new> if C<timeout> arg is not given.

=cut

use strict;
use warnings;

package USB::TMC;
$USB::TMC::VERSION = '0.003';
use USB::LibUSB;
use Moose;
use MooseX::Params::Validate 'validated_list';
use Carp;
use Data::Dumper 'Dumper';

use constant {
    MSGID_DEV_DEP_MSG_OUT => 1,
    MSGID_REQUEST_DEV_DEP_MSG_IN => 2,
    MSGID_DEV_DEP_MSG_IN => 2,
    MSGID_VENDOR_SPECIFIC_OUT => 126,
    MSGID_REQUEST_VENDOR_SPECIFIC_IN => 127,
    MSGID_VENDOR_SPECIFIC_IN => 127,

    MESSAGE_FINALIZES_TRANSFER => "\x{01}",
    MESSAGE_DOES_NOT_FINALIZE_TRANSFER => "\x{00}",

    FEATURE_SELECTOR_ENDPOINT_HALT => 0,

    BULK_HEADER_LENGTH => 12,
};

my $null_byte = "\x{00}";

has 'vid' => (
    is => 'ro',
    isa => 'Int',
    required => 1
    );

has 'pid' => (
    is => 'ro',
    isa => 'Int',
    required => 1
    );

has 'serial' => (
    is => 'ro',
    isa => 'Str',
    );

has 'ctx' => (
    is => 'ro',
    isa => 'USB::LibUSB',
    init_arg => undef,
    writer => '_ctx',
    );

has 'device' => (
    is => 'ro',
    isa => 'USB::LibUSB::Device',
    init_arg => undef,
    writer => '_device',
    );

has 'handle' => (
    is => 'ro',
    isa => 'USB::LibUSB::Device::Handle',
    init_arg => undef,
    writer => '_handle',
    );

# Bulk endpoint addresses.
has 'bulk_out_endpoint' => (
    is => 'ro',
    isa => 'Int',
    init_arg => undef,
    writer => '_bulk_out_endpoint',
    );

has 'bulk_in_endpoint' => (
    is => 'ro',
    isa => 'Int',
    init_arg => undef,
    writer => '_bulk_in_endpoint',
    );

has 'btag' => (
    is => 'ro',
    isa => 'Int',
    init_arg => undef,
    writer => '_btag',
    default => 0,
    );

has 'reset_device' => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
    );

has 'debug_mode' => (
    is => 'ro',
    isa => 'Bool',
    default => 0
    );

has 'libusb_log_level' => (
    is => 'ro',
    isa => 'Int',
    default => LIBUSB_LOG_LEVEL_WARNING,
    );

has 'term_char' => (
    is => 'ro',
    isa => 'Maybe[Str]',
    default => undef,
    );

has 'interface_number' => (
    is => 'ro',
    isa => 'Int',
    writer => '_interface_number',
    init_arg => undef,
    
    );

has 'timeout' => (
    is => 'rw',
    isa => 'Num',
    default => 5,
    );

sub _get_timeout_arg {
    my $self = shift;
    my $timeout = shift;
    if (not defined $timeout) {
        $timeout = $self->timeout();
    }

    $timeout = sprintf("%.0f", $timeout * 1000);
    return $timeout;
}

sub _debug {
    my $self = shift;
    if ($self->debug_mode()) {
        carp @_;
    }
}

=head2 new

 my $usbtmc = USB::TMC->new(
     vid => $vid,
     pid => $pid,
     serial => $serial, # optional
     reset_device => 0, # default: do device reset
     debug_mode => 1,   # print lots of debug messages
     libusb_log_level => LIBUSB_LOG_LEVEL_DEBUG, # Import LIBUSB_LOG_LEVEL_* constant from USB::LibUSB
     term_char => "\n", # Stop a read request if the term_char occurs in the
                        # byte stream. Default: do not use term char
     timeout => 10,     # timeout in seconds. default: 5
 );

=cut
     
     
     
sub BUILD {
    my $self = shift;

    # TermChar valid?
    my $term_char = $self->term_char();
    if (defined $term_char) {
        if (length $term_char != 1 || $term_char =~ /[^[:ascii:]]/) {
            croak "invalid TermChar";
        }
        $self->_debug("Using TermChar ", Dumper $term_char);
    }
    else {
        $self->_debug("Not using TermChar");
    }

    my $ctx = USB::LibUSB->init();
    $ctx->set_debug($self->libusb_log_level());

    my $handle;
    if ($self->serial()) {
        $handle = $ctx->open_device_with_vid_pid_serial(
            $self->vid(), $self->pid(), $self->serial());
    }
    else {
        # Croak if we have multiple devices with the same vid:pid.
        $handle = $ctx->open_device_with_vid_pid_unique(
            $self->vid(), $self->pid());
    }
    
    if ($self->reset_device()) {
        # Clean up.
        $self->_debug("Doing device reset.");
        $handle->reset_device();
    }
    
    my $device = $handle->get_device();
    
    eval {
        # This will throw on windows and darwin. Catch exception with eval.
        $self->_debug("enable auto detach of kernel driver.");
        $handle->set_auto_detach_kernel_driver(1);
    };
    
    

    
    $self->_ctx($ctx);
    $self->_device($device);
    $self->_handle($handle);

    my $usbtmc_interface_number = $self->_find_usbtmc_interface();
    $self->_interface_number($usbtmc_interface_number);
    
    $self->_debug("Claiming interface no. $usbtmc_interface_number");
    $handle->claim_interface($usbtmc_interface_number);
    
    $self->_get_endpoint_addresses();

    $self->_debug(
        "Request clear_feature endpoint_halt for both bulk endpoints."
        );

    $self->clear_halt_out();
    $self->clear_halt_in();
    $self->clear_feature_endpoint_out();
    $self->clear_feature_endpoint_in();
}

sub _find_usbtmc_interface {
    # Relevant if device has additional non-TMC interfaces.
    my $self = shift;
    my $config = $self->device()->get_active_config_descriptor();
    my @interfaces = @{$config->{interface}};
    for my $interface (@interfaces) {
        if ($interface->{bInterfaceClass} == 0xFE
            && $interface->{bInterfaceSubClass} == 3) {
            my $number = $interface->{bInterfaceNumber};
            $self->_debug("Found USBTMC interface at number $number");
            return $number;
        }
    }
    croak "Did not find a USBTMC interface. Interfaces: ", Dumper \@interfaces;
}

sub _get_endpoint_addresses {
    my $self = shift;
    my $interface_number = $self->interface_number();
    
    my $config = $self->device()->get_active_config_descriptor();
    my $interface = $config->{interface}[$interface_number];
    my @endpoints = @{$interface->{endpoint}};

    if (@endpoints != 2 && @endpoints != 3) {
        croak "USBTMC interface needs either 2 or 3 endpoints.";
    }

    my ($bulk_out_address, $bulk_in_address);
    for my $endpoint (@endpoints) {
        my $address = $endpoint->{bEndpointAddress};
        my $direction = $address & LIBUSB_ENDPOINT_DIR_MASK;
        my $type = $endpoint->{bmAttributes} & LIBUSB_TRANSFER_TYPE_MASK;
        if ($type == LIBUSB_TRANSFER_TYPE_BULK) {
            if ($direction == LIBUSB_ENDPOINT_OUT) {
                $self->_debug("Found bulk-out endpoint with address ".
                              sprintf("0x%x", $address));
                $bulk_out_address = $address;
            }
            elsif ($direction == LIBUSB_ENDPOINT_IN) {
                $self->_debug("Found bulk-in endpoint with address ".
                              sprintf("0x%x", $address));
                $bulk_in_address = $address;
            }
        }
    }
    
    if (!$bulk_out_address || !$bulk_in_address) {
        croak "Did not find all required endpoints.";
    }
    
    $self->_bulk_out_endpoint($bulk_out_address);
    $self->_bulk_in_endpoint($bulk_in_address);
}

=head2 write  

 $usbtmc->write(data => $data, timeout => $timeout);

Do DEV_DEP_MSG_OUT transfer.


=cut

sub write {
    my $self = shift;
    $self->dev_dep_msg_out(@_);
}

=head2 read

 my $data = $usbtmc->read(length => $read_length, timeout => $timeout);

Do REQUEST_DEV_DEP_MSG_IN and DEV_DEP_MSG_IN transfers.

Typically you will not need this method and only use L</query>.

=cut


sub read {
    my $self = shift;
    my ($length, $timeout) = validated_list(
        \@_,
        length => {isa => 'Int'},
        timeout => {isa => 'Maybe[Num]', optional => 1}
        );

    $self->request_dev_dep_msg_in(length => $length, timeout => $timeout);
    return $self->dev_dep_msg_in(length => $length, timeout => $timeout);
}

=head2 query

 my $data = $usbtmc->query(data => $data, length => $read_length, timeout => $timeout);

Send a query command and read the result.

=cut

sub query {
    my $self = shift;
    my ($data, $length, $timeout) = validated_list(
        \@_,
        data => {isa => 'Str'},
        length => {isa => 'Int'},
        timeout => {isa => 'Maybe[Num]', optional => 1},
        );

    $self->write(data => $data, timeout => $timeout);
    return $self->read(length => $length, timeout => $timeout);
}


sub dev_dep_msg_out {
    my $self = shift;
    my ($data, $timeout) = validated_list(
        \@_,
        data => {isa => 'Str'},
        timeout => {isa => 'Maybe[Num]', optional => 1},
        );

    $timeout = $self->_get_timeout_arg($timeout);
    
    $self->_debug("Doing dev_dep_msg_out with data $data");
    
    my $header = $self->_dev_dep_msg_out_header(length => length $data);
    my $endpoint = $self->bulk_out_endpoint();

    # Ensure that total number of bytes is multiple of 4.
    $data .= $null_byte x ((4 - (length $data) % 4) % 4);
    $self->handle()->bulk_transfer_write($endpoint, $header . $data, $timeout);
}

sub dev_dep_msg_in {
    my $self = shift;
    my ($length, $timeout) = validated_list(
        \@_,
        length => {isa => 'Int'},
        timeout => {isa => 'Maybe[Num]', optional => 1}
        );

    $timeout = $self->_get_timeout_arg($timeout);
    
    $self->_debug("Doing dev_dep_msg_in with length $length");
    
    my $endpoint = $self->bulk_in_endpoint();
    my $data = $self->handle()->bulk_transfer_read(
        $endpoint, $length + BULK_HEADER_LENGTH
        , $timeout
        );
    
    if (length $data < BULK_HEADER_LENGTH) {
        croak "dev_dep_msg_in does not contain header";
    }
    
    my $header = substr($data, 0, BULK_HEADER_LENGTH);

    my $transfer_size = unpack('V', substr($header, 4, 4));
    
    # Data may contain trailing alignment bytes!
    # strip them by returning only $transfer_size bytes.
    $data = substr($data, BULK_HEADER_LENGTH, $transfer_size);
    return $data;
}

sub request_dev_dep_msg_in {
    my $self = shift;
    my ($length, $timeout) = validated_list(
        \@_,
        length => {isa => 'Int', default => 1000},
        timeout => {isa => 'Maybe[Num]', optional => 1},
        );

    $timeout = $self->_get_timeout_arg($timeout);
    
    $self->_debug("Doing request_dev_dep_msg_in with length $length");
    my $header = $self->_request_dev_dep_msg_in_header(length => $length);
    my $endpoint = $self->bulk_out_endpoint();

    # Length of $header is already multiple of 4.
    $self->handle()->bulk_transfer_write($endpoint, $header, $timeout);
}

sub _dev_dep_msg_out_header {
    my $self = shift;
    my ($length) = validated_list(\@_, length => {isa => 'Int'});
    
    my $header = $self->_bulk_out_header(MSGID => MSGID_DEV_DEP_MSG_OUT);
    $header .= pack('V', $length);
    $header .= MESSAGE_FINALIZES_TRANSFER;
    $header .= $null_byte x 3;  # Reserved bytes.
    return $header;
}

sub _request_dev_dep_msg_in_header {
    my $self = shift;
    my ($length) = validated_list(\@_, length => {isa => 'Int'});
    my $header = $self->_bulk_out_header(MSGID => MSGID_REQUEST_DEV_DEP_MSG_IN);
    # Transfer length
    $header .= pack('V', $length);
    
    my $term_char = $self->term_char();
    if (defined $term_char) {
        $header .= pack('C', 2);
        $header .= $term_char;
    }
    else {
        $header .= pack('C', 0);
        $header .= $null_byte;
    }
    $header .= $null_byte x 2; # Reserved. Must be 0x00.
    
    return $header;
}


sub _bulk_out_header {
    my $self = shift;
    my ($MSGID) = validated_list(\@_, MSGID => {isa => 'Int'});
    my $bulk_out_header = pack('C', $MSGID);
    my ($btag, $btag_inverse) = $self->_btags();
    $bulk_out_header .= $btag . $btag_inverse;

    $bulk_out_header .= $null_byte;    # Reserved. Must be 0x00;

    return $bulk_out_header;
}

sub _btags {
    my $self = shift;
    my $btag = $self->btag();
    $btag++;
    if ($btag == 256) {
        $btag = 1;
    }
    $self->_btag($btag);
    my $btag_inverse = ($btag ^ 0xff);
    return (pack('C', $btag), pack('C', $btag_inverse));
}

sub clear {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_, timeout => {isa => 'Maybe[Num]', optional => 1});

    $timeout = $self->_get_timeout_arg($timeout);
    
    my $bmRequestType = 0xa1;   # See USBTMC 4.2.1.6 INITIATE_CLEAR
    my $bRequest = 5;
    my $wValue = 0;
    my $wIndex = $self->interface_number();
    my $wLength = 1;
    return $self->handle()->control_transfer_read($bmRequestType, $bRequest, $wValue, $wIndex, $wLength, $timeout);
    # FIXME: check clear status in loop.
    
}

sub clear_feature_endpoint_out {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_, timeout => {isa => 'Maybe[Num]', optional => 1});

    $timeout = $self->_get_timeout_arg($timeout);
    
    my $endpoint = $self->bulk_out_endpoint();
    my $bmRequestType = LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_STANDARD
        | LIBUSB_RECIPIENT_ENDPOINT;
    my $bRequest = LIBUSB_REQUEST_CLEAR_FEATURE;
    my $wValue = FEATURE_SELECTOR_ENDPOINT_HALT;
    my $wIndex = $endpoint;
    $self->handle()->control_transfer_write(
        $bmRequestType, $bRequest, $wValue, $wIndex, "", $timeout);
}

sub clear_feature_endpoint_in {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_, timeout => {isa => 'Maybe[Num]', optional => 1});

    $timeout = $self->_get_timeout_arg($timeout);
    
    my $endpoint = $self->bulk_in_endpoint();
    my $bmRequestType = LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_STANDARD
        | LIBUSB_RECIPIENT_ENDPOINT;
    my $bRequest = LIBUSB_REQUEST_CLEAR_FEATURE;
    my $wValue = FEATURE_SELECTOR_ENDPOINT_HALT;
    my $wIndex = $endpoint;
    $self->handle()->control_transfer_write(
        $bmRequestType, $bRequest, $wValue, $wIndex, "", $timeout);
}

sub clear_halt_out {
    my $self = shift;
    my $endpoint = $self->bulk_out_endpoint();
    $self->handle()->clear_halt($endpoint);
}

sub clear_halt_in {
    my $self = shift;
    my $endpoint = $self->bulk_in_endpoint();
    $self->handle()->clear_halt($endpoint);
}

=head2 get_capabilities

 my $capabilites = $usbtmc->get_capabilities(timeout => $timeout);

Do GET_CAPABILITIES request.

The C<$capabilities> hash contains the following keys:

=over

=item bcdUSBTMC

=item listen_only

=item talk_only

=item accept_indicator_pulse

=item support_term_char

=back

=cut


sub get_capabilities {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_, timeout => {isa => 'Maybe[Num]', optional => 1});

    $timeout = $self->_get_timeout_arg($timeout);
    
    my $bmRequestType = 0xa1;
    my $bRequest = 7;
    my $wValue = 0;
    my $wIndex = $self->interface_number();
    my $wLength = 0x18;

    my $handle = $self->handle();
    my $caps = $handle->control_transfer_read($bmRequestType, $bRequest, $wValue, $wIndex, $wLength, $timeout);
    if (length $caps != $wLength) {
        croak "Incomplete response in get_capabilities.";
    }
    
    my $status = unpack('C', substr($caps, 0, 1));
    
    if ($status != 1) {
        croak "GET_CAPABILITIES not successfull. status = $status";
    }
    
    my $bcdUSBTMC = unpack('v', substr($caps, 2, 2));
    my $interface_capabilities = unpack('C', substr($caps, 4, 1));
    my $device_capabilites = unpack('C', substr($caps, 5, 1));
    
    return {
        bcdUSBTMC => $bcdUSBTMC,
        listen_only => $interface_capabilities & 1,
        talk_only => ($interface_capabilities >> 1) & 1,
        accept_indicator_pulse => ($interface_capabilities >> 2) & 1,
        support_term_char => $device_capabilites & 1,
    };
}

__PACKAGE__->meta->make_immutable();

1;


