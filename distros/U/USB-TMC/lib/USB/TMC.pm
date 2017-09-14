
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
$USB::TMC::VERSION = '0.004';
use USB::LibUSB;
use Moose;
use MooseX::Params::Validate 'validated_list';
use Carp;
use Data::Dumper 'Dumper';

use constant {
    MSGID_DEV_DEP_MSG_OUT            => 1,
    MSGID_REQUEST_DEV_DEP_MSG_IN     => 2,
    MSGID_DEV_DEP_MSG_IN             => 2,
    MSGID_VENDOR_SPECIFIC_OUT        => 126,
    MSGID_REQUEST_VENDOR_SPECIFIC_IN => 127,
    MSGID_VENDOR_SPECIFIC_IN         => 127,

    MESSAGE_FINALIZES_TRANSFER         => "\x{01}",
    MESSAGE_DOES_NOT_FINALIZE_TRANSFER => "\x{00}",

    FEATURE_SELECTOR_ENDPOINT_HALT => 0,

    BULK_HEADER_LENGTH => 12,

    # bRequest values
    INITIATE_ABORT_BULK_OUT     => 1,
    CHECK_ABORT_BULK_OUT_STATUS => 2,
    INITIATE_ABORT_BULK_IN      => 3,
    CHECK_ABORT_BULK_IN_STATUS  => 4,
    INITIATE_CLEAR              => 5,
    CHECK_CLEAR_STATUS          => 6,
    GET_CAPABILITIES            => 7,

    # status values
    STATUS_SUCCESS => 0x01,
    STATUS_PENDING => 0x02,
    STATUS_FAILED  => 0x80,

};

my $null_byte = "\x{00}";

has 'vid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'pid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'serial' => (
    is  => 'ro',
    isa => 'Str',
);

has 'ctx' => (
    is       => 'ro',
    isa      => 'USB::LibUSB',
    init_arg => undef,
    writer   => '_ctx',
);

has 'device' => (
    is       => 'ro',
    isa      => 'USB::LibUSB::Device',
    init_arg => undef,
    writer   => '_device',
);

has 'handle' => (
    is       => 'ro',
    isa      => 'USB::LibUSB::Device::Handle',
    init_arg => undef,
    writer   => '_handle',
);

# Bulk endpoint addresses.
has 'bulk_out_endpoint' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    writer   => '_bulk_out_endpoint',
);

has 'bulk_in_endpoint' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    writer   => '_bulk_in_endpoint',
);

has 'btag' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    writer   => '_btag',
    default  => 0,
);

has 'reset_device' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'debug_mode' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has 'libusb_log_level' => (
    is      => 'ro',
    isa     => 'Int',
    default => LIBUSB_LOG_LEVEL_WARNING,
);

has 'term_char' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => undef,
);

has 'interface_number' => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_interface_number',
    init_arg => undef,

);

has 'timeout' => (
    is      => 'rw',
    isa     => 'Num',
    default => 5,
);

sub _get_timeout_arg {
    my $self    = shift;
    my $timeout = shift;
    if ( not defined $timeout ) {
        $timeout = $self->timeout();
    }

    $timeout = sprintf( "%.0f", $timeout * 1000 );
    return $timeout;
}

sub _timeout_arg {
    return ( timeout => { isa => 'Maybe[Num]', optional => 1 } );
}

sub _debug {
    my $self = shift;
    if ( $self->debug_mode() ) {
        warn "USBTMC debug: ", @_, "\n";
    }
}

=head2 new

 my $usbtmc = USB::TMC->new(
     vid => $vid,
     pid => $pid,
     serial => $serial, # optional
     reset_device => 1, # default: do not reset device
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
    if ( defined $term_char ) {
        if ( length $term_char != 1 || $term_char =~ /[^[:ascii:]]/ ) {
            croak "invalid TermChar";
        }
        $self->_debug( "Using TermChar ", Dumper $term_char);
    }
    else {
        $self->_debug("Not using TermChar");
    }

    my $ctx = USB::LibUSB->init();
    $ctx->set_debug( $self->libusb_log_level() );

    my $handle;
    if ( $self->serial() ) {
        $handle = $ctx->open_device_with_vid_pid_serial(
            $self->vid(),
            $self->pid(), $self->serial()
        );
    }
    else {
        # Croak if we have multiple devices with the same vid:pid.
        $handle = $ctx->open_device_with_vid_pid_unique(
            $self->vid(),
            $self->pid()
        );
    }

    if ( $self->reset_device() ) {
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

    # $self->_debug(
    #     "Request clear_feature endpoint_halt for both bulk endpoints.");

    # $self->clear();
    # $self->clear_halt_out();
    # $self->clear_halt_in();
    # $self->clear_feature_endpoint_out();
    # $self->clear_feature_endpoint_in();
}

sub _find_usbtmc_interface {

    # Relevant if device has additional non-TMC interfaces.
    my $self       = shift;
    my $config     = $self->device()->get_active_config_descriptor();
    my @interfaces = @{ $config->{interface} };
    for my $interface (@interfaces) {
        if (   $interface->{bInterfaceClass} == 0xFE
            && $interface->{bInterfaceSubClass} == 3 ) {
            my $number = $interface->{bInterfaceNumber};
            $self->_debug("Found USBTMC interface at number $number");
            return $number;
        }
    }
    croak "Did not find a USBTMC interface. Interfaces: ",
        Dumper \@interfaces;
}

sub _get_endpoint_addresses {
    my $self             = shift;
    my $interface_number = $self->interface_number();

    my $config    = $self->device()->get_active_config_descriptor();
    my $interface = $config->{interface}[$interface_number];
    my @endpoints = @{ $interface->{endpoint} };

    if ( @endpoints != 2 && @endpoints != 3 ) {
        croak "USBTMC interface needs either 2 or 3 endpoints.";
    }

    my ( $bulk_out_address, $bulk_in_address );
    for my $endpoint (@endpoints) {
        my $address   = $endpoint->{bEndpointAddress};
        my $direction = $address & LIBUSB_ENDPOINT_DIR_MASK;
        my $type      = $endpoint->{bmAttributes} & LIBUSB_TRANSFER_TYPE_MASK;
        if ( $type == LIBUSB_TRANSFER_TYPE_BULK ) {
            if ( $direction == LIBUSB_ENDPOINT_OUT ) {
                $self->_debug( "Found bulk-out endpoint with address "
                        . sprintf( "0x%x", $address ) );
                $bulk_out_address = $address;
            }
            elsif ( $direction == LIBUSB_ENDPOINT_IN ) {
                $self->_debug( "Found bulk-in endpoint with address "
                        . sprintf( "0x%x", $address ) );
                $bulk_in_address = $address;
            }
        }
    }

    if ( !$bulk_out_address || !$bulk_in_address ) {
        croak "Did not find all required endpoints.";
    }

    $self->_bulk_out_endpoint($bulk_out_address);
    $self->_bulk_in_endpoint($bulk_in_address);
}

=head2 write  

 $usbtmc->write(data => $data, timeout => $timeout);

Do DEV_DEP_MSG_OUT transfer. So far this only supports USBTMC messages
consisting of a single transfer.

=cut

sub write {
    my $self = shift;
    $self->dev_dep_msg_out(@_);
}

=head2 read

 my $data = $usbtmc->read(length => $read_length, timeout => $timeout);

Do REQUEST_DEV_DEP_MSG_IN and DEV_DEP_MSG_IN transfers.

=cut

sub read {
    my $self = shift;
    my ( $length, $timeout ) = validated_list(
        \@_,
        length => { isa => 'Int' },
        _timeout_arg(),
    );

    my $result = '';

    # Do read requests until EOM flag is set.
    while ($length) {
        $self->request_dev_dep_msg_in(
            length  => $length,
            timeout => $timeout
        );
        my ( $data, $eom )
            = $self->dev_dep_msg_in( length => $length, timeout => $timeout );
        $result .= $data;
        $length -= length($data);
        if ($eom) {
            last;
        }
    }
    return $result;
}

sub dev_dep_msg_out {
    my $self = shift;
    my ( $data, $timeout ) = validated_list(
        \@_,
        data => { isa => 'Str' },
        _timeout_arg(),
    );

    $self->_debug("dev_dep_msg_out with data $data");

    my $header = $self->_dev_dep_msg_out_header( length => length $data );
    my $endpoint = $self->bulk_out_endpoint();

    # Ensure that total number of bytes is multiple of 4.
    $data .= $null_byte x ( ( 4 - ( length $data ) % 4 ) % 4 );
    $data = $header . $data;

    my $transferred = eval {
        $self->handle()->bulk_transfer_write(
            $endpoint, $data,
            $self->_get_timeout_arg($timeout)
        );
    };
    if ($@) {
        $self->_debug(
            "dev_dep_msg_out: write failed. Aborting bulk transfer.");
        $self->abort_bulk_out( timeout => $timeout );
        croak($@);
    }

    my $data_length = length($data);
    if ( $transferred != $data_length ) {
        croak
            "dev_dep_msg_out: data_length = $data_length, transferred = $transferred";
    }
}

sub dev_dep_msg_in {
    my $self = shift;
    my ( $length, $timeout ) = validated_list(
        \@_,
        length => { isa => 'Int' },
        _timeout_arg(),
    );

    $self->_debug("Doing dev_dep_msg_in with length $length");

    my $endpoint = $self->bulk_in_endpoint();
    my $data     = eval {
        $self->handle()->bulk_transfer_read(
            $endpoint, $length + BULK_HEADER_LENGTH
            ,          $self->_get_timeout_arg($timeout)
        );
    };
    if ($@) {
        $self->_debug("dev_dep_msg_in: read failed. Aborting bulk transfer.");
        $self->abort_bulk_in( timeout => $timeout );
        croak($@);
    }

    if ( length $data < BULK_HEADER_LENGTH ) {
        croak "dev_dep_msg_in does not contain header";
    }

    my $header = substr( $data, 0, BULK_HEADER_LENGTH );
    my $msg_id              = unpack( 'C', substr( $header, 0, 1 ) );
    my $transfer_attributes = unpack( 'C', substr( $header, 8, 1 ) );

    if ( $msg_id != MSGID_DEV_DEP_MSG_IN ) {
        croak "dev_dep_msg_in message with wrong message id '$msg_id'";
    }

    my $transfer_size = unpack( 'V', substr( $header, 4, 4 ) );
    if ( $transfer_size == 0 ) {
        croak("dev_dep_msg_in: zero transfer size");
    }

    # Data may contain trailing alignment bytes!
    # strip them by returning only $transfer_size bytes.
    $data = substr( $data, BULK_HEADER_LENGTH, $transfer_size );
    my $eom = $transfer_attributes & 1;
    return ( $data, $eom );
}

sub request_dev_dep_msg_in {
    my $self = shift;
    my ( $length, $timeout ) = validated_list(
        \@_,
        length => { isa => 'Int', default => 1000 },
        _timeout_arg(),
    );

    $self->_debug("Doing request_dev_dep_msg_in with length $length");
    my $header = $self->_request_dev_dep_msg_in_header( length => $length );
    my $endpoint = $self->bulk_out_endpoint();

    # Length of $header is already multiple of 4.
    my $transferred = eval {
        $self->handle()->bulk_transfer_write(
            $endpoint, $header,
            $self->_get_timeout_arg($timeout)
        );
    };
    if ($@) {
        $self->_debug(
            "request_dev_dep_msg_in: write failed. Aborting bulk transfer.");
        $self->abort_bulk_out( timeout => $timeout );
        croak($@);
    }
}

sub _dev_dep_msg_out_header {
    my $self = shift;
    my ($length) = validated_list( \@_, length => { isa => 'Int' } );

    my $header = $self->_bulk_out_header( MSGID => MSGID_DEV_DEP_MSG_OUT );
    $header .= pack( 'V', $length );
    $header .= MESSAGE_FINALIZES_TRANSFER;
    $header .= $null_byte x 3;    # Reserved bytes.
    return $header;
}

sub _request_dev_dep_msg_in_header {
    my $self = shift;
    my ($length) = validated_list( \@_, length => { isa => 'Int' } );
    my $header
        = $self->_bulk_out_header( MSGID => MSGID_REQUEST_DEV_DEP_MSG_IN );

    # Transfer length
    $header .= pack( 'V', $length );

    my $term_char = $self->term_char();
    if ( defined $term_char ) {
        $header .= pack( 'C', 2 );
        $header .= $term_char;
    }
    else {
        $header .= pack( 'C', 0 );
        $header .= $null_byte;
    }
    $header .= $null_byte x 2;    # Reserved. Must be 0x00.

    return $header;
}

sub _bulk_out_header {
    my $self = shift;
    my ($MSGID) = validated_list( \@_, MSGID => { isa => 'Int' } );
    my $bulk_out_header = pack( 'C', $MSGID );
    my ( $btag, $btag_inverse ) = $self->_btags();
    $bulk_out_header .= $btag . $btag_inverse;

    $bulk_out_header .= $null_byte;    # Reserved. Must be 0x00;

    return $bulk_out_header;
}

sub _btags {
    my $self = shift;
    my $btag = $self->btag();
    $btag++;
    if ( $btag == 256 ) {
        $btag = 1;
    }
    $self->_btag($btag);
    my $btag_inverse = ( $btag ^ 0xff );
    return ( pack( 'C', $btag ), pack( 'C', $btag_inverse ) );
}

#
#
# USBTMC requests
#
#

sub abort_bulk_out {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_,
        _timeout_arg()
    );
    my $initiate_status
        = $self->initiate_abort_bulk_out( timeout => $timeout );
    $initiate_status = unpack( 'C', $initiate_status );
    if ( $initiate_status != STATUS_SUCCESS ) {
        carp "INITIATE_ABORT_BULK_OUT failed with status $initiate_status";
        return;
    }

    # Check status
    while (1) {
        my $clear_status
            = $self->check_abort_bulk_out_status( timeout => $timeout );
        my $status = unpack( 'C', substr( $clear_status, 0, 1 ) );
        if ( $status == STATUS_PENDING ) {
            next;
        }
        else {
            if ( $status != STATUS_SUCCESS ) {
                carp(
                    "CHECK_ABORT_BULK_OUT_STATUS failed with status $status");
            }
            $self->clear_feature_endpoint_out( timeout => $timeout );
            return;
        }
    }
}

sub abort_bulk_in {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_,
        _timeout_arg()
    );

    my $initiate_status
        = $self->initiate_abort_bulk_in( timeout => $timeout );
    $initiate_status = unpack( 'C', $initiate_status );
    if ( $initiate_status != STATUS_SUCCESS ) {
        carp "INITIATE_ABORT_BULK_IN failed with status $initiate_status";
        return;
    }

    # Check status
    while (1) {
        my $clear_status
            = $self->check_abort_bulk_in_status( timeout => $timeout );
        my $status        = unpack( 'C', substr( $clear_status, 0, 1 ) );
        my $bmAbortBulkIn = unpack( 'C', substr( $clear_status, 1, 1 ) );
        if ( $status == STATUS_PENDING ) {
            $self->_debug(
                "check_abort_bulk_in_status bmAbortBulkIn = $bmAbortBulkIn\n"
            );

            # If bmAbortBulkIn.D0 = 1, the Host should read from the
            # Bulk-IN endpoint until a short packet is received.
            if ( $bmAbortBulkIn & 1 ) {
                my $endpoint = $self->bulk_in_endpoint();
                my $data     = $self->handle()->bulk_transfer_read(
                    $endpoint, 1000,
                    $self->_get_timeout_arg($timeout)
                );
                $self->_debug(
                    "check_abort_bulk_in_status read bytes: ",
                    length($data)
                );
            }
            next;
        }
        else {
            if ( $status != STATUS_SUCCESS ) {
                carp("CHECK_ABORT_BULK_IN_STATUS failed with status $status");
            }
            return;
        }
    }
}

sub initiate_abort_bulk_out {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_,
        _timeout_arg()
    );

    $self->_debug("initiate abort bulk out");
    my $bmRequestType = 0xa2;
    my $bRequest      = INITIATE_ABORT_BULK_OUT;
    my $wValue        = $self->btag();
    my $wIndex        = $self->bulk_out_endpoint();
    my $wLength       = 2;
    return $self->handle()->control_transfer_read(
        $bmRequestType, $bRequest, $wValue, $wIndex,
        $wLength,       $self->_get_timeout_arg($timeout)
    );
}

sub initiate_abort_bulk_in {
    my $self = shift;
    my ($timeout) = validated_list(
        \@_,
        _timeout_arg()
    );

    $self->_debug("initiate abort bulk in");
    my $bmRequestType = 0xa2;
    my $bRequest      = INITIATE_ABORT_BULK_IN;
    my $wValue        = $self->btag();
    my $wIndex        = $self->bulk_in_endpoint();
    my $wLength       = 2;
    return $self->handle()->control_transfer_read(
        $bmRequestType, $bRequest, $wValue, $wIndex,
        $wLength,       $self->_get_timeout_arg($timeout)
    );
}

sub check_abort_bulk_out_status {
    my $self = shift;
    my ($timeout) = validated_list( \@_, _timeout_arg() );

    $self->_debug("check abort bulk out status");
    my $bmRequestType = 0xa2;
    my $bRequest      = CHECK_ABORT_BULK_OUT_STATUS;
    my $wValue        = 0;
    my $wIndex        = $self->bulk_out_endpoint();
    my $wLength       = 8;
    return $self->handle()->control_transfer_read(
        $bmRequestType, $bRequest, $wValue, $wIndex,
        $wLength,       $self->_get_timeout_arg($timeout)
    );
}

sub check_abort_bulk_in_status {
    my $self = shift;
    my ($timeout) = validated_list( \@_, _timeout_arg() );

    $self->_debug("check abort bulk in status");
    my $bmRequestType = 0xa2;
    my $bRequest      = CHECK_ABORT_BULK_IN_STATUS;
    my $wValue        = 0;
    my $wIndex        = $self->bulk_in_endpoint();
    my $wLength       = 8;
    return $self->handle()->control_transfer_read(
        $bmRequestType, $bRequest, $wValue, $wIndex,
        $wLength,       $self->_get_timeout_arg($timeout)
    );
}

=head2 clear

 $usbtmc->clear(timeout => $timeout);

Do INITIATE_CLEAR / CHECK_CLEAR_STATUS split transaction. On success, send
CLEAR_FEATURE request to clear the Bulk-OUT Halt.

=cut

sub clear {
    my $self = shift;
    my ($timeout) = validated_list( \@_, _timeout_arg() );
    my $initiate_status = $self->initiate_clear( timeout => $timeout );
    $initiate_status = unpack( 'C', $initiate_status );
    if ( $initiate_status != STATUS_SUCCESS ) {
        carp "INITIATE_CLEAR failed with status $initiate_status";
        return;
    }

    # Check clear status
    while (1) {
        my $clear_status = $self->check_clear_status( timeout => $timeout );
        my $status  = unpack( 'C', substr( $clear_status, 0, 1 ) );
        my $bmClear = unpack( 'C', substr( $clear_status, 1, 1 ) );
        if ( $status == STATUS_SUCCESS ) {
            last;
        }
        elsif ( $status == STATUS_PENDING ) {
            $self->_debug(
                "CHECK_CLEAR_STATUS: status pending, bmClear = $bmClear");

            # If bmClear.D0 = 1, the Host should read from the
            # Bulk-IN endpoint until a short packet is received.
            if ( $bmClear & 1 ) {
                my $endpoint = $self->bulk_in_endpoint();
                my $data     = $self->handle()->bulk_transfer_read(
                    $endpoint, 1000,
                    $self->_get_timeout_arg($timeout)
                );
                $self->_debug( " read bytes: ", length($data) );
            }
            next;
        }
        else {
            croak "CHECK_CLEAR_STATUS failed with status $status";
        }
    }
    $self->clear_feature_endpoint_out( timeout => $timeout );
}

sub initiate_clear {
    my $self = shift;
    my ($timeout) = validated_list( \@_, _timeout_arg() );

    $self->_debug("initiate clear");
    my $bmRequestType = 0xa1;
    my $bRequest      = INITIATE_CLEAR;
    my $wValue        = 0;
    my $wIndex        = $self->interface_number();
    my $wLength       = 1;
    return $self->handle()->control_transfer_read(
        $bmRequestType, $bRequest, $wValue, $wIndex,
        $wLength,       $self->_get_timeout_arg($timeout)
    );
}

sub check_clear_status {
    my $self = shift;
    my ($timeout) = validated_list( \@_, _timeout_arg() );

    $self->_debug("check clear status");
    my $bmRequestType = 0xa1;
    my $bRequest      = CHECK_CLEAR_STATUS;
    my $wValue        = 0;
    my $wIndex        = $self->interface_number();
    my $wLength       = 2;
    return $self->handle()->control_transfer_read(
        $bmRequestType, $bRequest, $wValue, $wIndex,
        $wLength,       $self->_get_timeout_arg($timeout)
    );
}

sub clear_feature_endpoint_out {
    my $self = shift;
    my ($timeout) = validated_list( \@_, _timeout_arg() );

    $self->_debug("clear feature endpoint out");
    my $endpoint      = $self->bulk_out_endpoint();
    my $bmRequestType = LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_STANDARD
        | LIBUSB_RECIPIENT_ENDPOINT;
    my $bRequest = LIBUSB_REQUEST_CLEAR_FEATURE;
    my $wValue   = FEATURE_SELECTOR_ENDPOINT_HALT;
    my $wIndex   = $endpoint;
    $self->handle()->control_transfer_write(
        $bmRequestType, $bRequest, $wValue,
        $wIndex,        "",        $self->_get_timeout_arg($timeout)
    );
}

sub clear_feature_endpoint_in {
    my $self = shift;
    my ($timeout) = validated_list( \@_, _timeout_arg() );

    $self->_debug("clear feature endpoint in");
    my $endpoint      = $self->bulk_in_endpoint();
    my $bmRequestType = LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_STANDARD
        | LIBUSB_RECIPIENT_ENDPOINT;
    my $bRequest = LIBUSB_REQUEST_CLEAR_FEATURE;
    my $wValue   = FEATURE_SELECTOR_ENDPOINT_HALT;
    my $wIndex   = $endpoint;
    $self->handle()->control_transfer_write(
        $bmRequestType, $bRequest, $wValue,
        $wIndex,        "",        $self->_get_timeout_arg($timeout)
    );
}

sub clear_halt_out {
    my $self     = shift;
    my $endpoint = $self->bulk_out_endpoint();
    $self->handle()->clear_halt($endpoint);
}

sub clear_halt_in {
    my $self     = shift;
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
    my ($timeout) = validated_list( \@_, _timeout_arg() );

    my $bmRequestType = 0xa1;
    my $bRequest      = 7;
    my $wValue        = 0;
    my $wIndex        = $self->interface_number();
    my $wLength       = 0x18;

    my $handle = $self->handle();
    my $caps   = $handle->control_transfer_read(
        $bmRequestType, $bRequest, $wValue,
        $wIndex,        $wLength,  $self->_get_timeout_arg($timeout)
    );
    if ( length $caps != $wLength ) {
        croak "Incomplete response in get_capabilities.";
    }

    my $status = unpack( 'C', substr( $caps, 0, 1 ) );

    if ( $status != 1 ) {
        croak "GET_CAPABILITIES not successfull. status = $status";
    }

    my $bcdUSBTMC              = unpack( 'v', substr( $caps, 2, 2 ) );
    my $interface_capabilities = unpack( 'C', substr( $caps, 4, 1 ) );
    my $device_capabilites     = unpack( 'C', substr( $caps, 5, 1 ) );

    return {
        bcdUSBTMC              => $bcdUSBTMC,
        listen_only            => $interface_capabilities & 1,
        talk_only              => ( $interface_capabilities >> 1 ) & 1,
        accept_indicator_pulse => ( $interface_capabilities >> 2 ) & 1,
        support_term_char      => $device_capabilites & 1,
    };
}

__PACKAGE__->meta->make_immutable();

1;

