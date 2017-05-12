package ZWave::Protocol;
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Device::SerialPort;
use Moo;

our $VERSION = "0.04";

has device           => ( is => 'rw', default => sub { "/dev/ttyUSB0" } );
has error            => ( is => 'rw' );
has port             => ( is => 'rw' );
has read_timeout_ms  => ( is => 'rw', default => sub { "200" } );
has ack_timeout_ms   => ( is => 'rw', default => sub { "5000" } );

sub connect {
    my( $self ) = @_;

    my $port = Device::SerialPort->new( $self->device, 1 );

    if( !defined $port ) {
        ERROR "Can't connect to ", $self->device;
        return undef;
    }

    $port->baudrate( 115200 );
    $port->databits( 8 );
    $port->parity( "none" );
    $port->stopbits( 1 );
    $port->handshake( "none" );
    $port->dtr_active( 1 );

    $port->error_msg( 1 );
    $port->user_msg( 0 );

    $port->write_settings or
        die "Failed to initialize USB port " . $self->device . ": $@";

    $self->port( $port );

    return 1;
}

sub checksum {
    my( $self, @bytes ) = @_;

    my $checksum = 0xFF;

      # x-or all elements but the first one
    for my $byte ( splice @bytes, 1, @bytes - 1 ) {
        $checksum ^= $byte;
    }

    return $checksum;
}

sub packet_dump {
    my( $self, $packet ) = @_;

    my @bytes = unpack "C*", $packet;

    return $self->bytes_dump( @bytes );
}

sub bytes_dump {
    my( $self, @bytes ) = @_;

    my $string = "";

    for my $byte ( @bytes ) {
        if( length $string ) {
            $string .= " ";
        }
        $string .= sprintf "%02x", $byte;
    }

    return "[ $string ]";
}

sub request_packet {
    my( $self, @payload ) = @_;

    my $length = @payload + 1;

    my @bytes    = ( 0x1, $length, @payload );
    my $checksum = $self->checksum( @bytes );

    DEBUG "Checksum of ", $self->bytes_dump( @bytes ), " is ", 
        $self->bytes_dump( $checksum );

    push @bytes, $checksum;

    return pack "C*", @bytes;
}

sub payload_send {
    my( $self, @payload ) = @_;

    my $request = $self->request_packet( @payload );

    DEBUG "Sending request: ", $self->packet_dump( $request );

    if( !$self->port->write( $request ) ) {
        $self->error( "Failed to send payload " . 
            $self->bytes_dump( @payload ) . ": $@" );
        return undef;
    }

    return 1;
}

sub ack_recv {
    my( $self ) = @_;

    DEBUG "Waiting for ACK";

    my $packet = $self->packet_recv( );
    my @bytes = unpack "C*", $packet;

    DEBUG "ACK bytes: ", $self->bytes_dump( @bytes );

    if( @bytes == 0 ) {
        INFO "Received nothing";
        return 0;
    }

    if( defined $bytes[ 0 ] and $bytes[ 0 ] == 6 ) {
        INFO "Received ACK";
        $self->ack_send();
        return 1;
    }

    INFO "Received non-ACK";

    return undef;
}

sub ack_send {
    my( $self, $node_id ) = @_;

    INFO "Sending ACK";
    $self->port->write( pack( "C", 6 ) );

    return 1;
}

sub payload_transmit {
    my( $self, @payload ) = @_;

    if( !$self->payload_send( @payload ) ) {
        return undef;
    }

    if( !$self->ack_recv() ) {
        $self->error( "Failed to receive ack for sent payload @payload: $@" );
        return undef;
    }

    return 1;
}

sub error_process {
    my( $self, $string ) = @_;

    local $Log::Log4perl::caller_depth =
        $Log::Log4perl::caller_depth + 1;

    ERROR $string;
    $self->error( $string );

    return 1;
}

sub packet_recv {
    my( $self ) = @_;

    $self->port->read_const_time( $self->read_timeout_ms );

      # read one byte at a time until there's no more
    my $sofar = "";
    while( 1 ) {
	my( $count, $bytes ) = $self->port->read( 1 );
        DEBUG "Read $count bytes: ", $self->packet_dump( $bytes );
	$sofar .= $bytes;
        if( !$count ) {
            last;
        }
    }

    DEBUG "Read packet: ", $self->packet_dump( $sofar );

    return $sofar;
}

sub payload_recv {
    my( $self ) = @_;

    my @bytes = unpack "C*", $self->packet_recv;

    my( $type, $len, @rest ) = @bytes;

    my $checksum = pop @rest;

    if( $checksum != $self->checksum( $len, @rest ) ) {
        $self->error_process( "Received package with invalid checksum: " .
            $self->bytes_dump( @bytes ) . " (checksum should be " .
            $self->bytes_dump( $checksum ) . ")" );
        return undef;
    }

    DEBUG "Received payload: ", $self->bytes_dump( @rest );

    return @rest;
}

1;

__END__

=head1 NAME

ZWave::Protocol - Protocol helpers for Z-Wave communication

=head1 SYNOPSIS

    use ZWave::Protocol;
    my $zw = ZWave::Protocol->new( device => "/dev/ttyUSB0" );

    $zw->connect();

    my $node_id = 3;
    my $state   = 255; # "on"

    $zw->payload_transmit( 0x13, $node_id, 
                   0x03, 0x20, 0x01, $state, 0x05 );

=head1 DESCRIPTION

ZWave::Protocol helps with the low-level details of the Z-Wave protocol, and
offers support for packing packets with length headers and checksums, as well
as connecting, sending, and receiving to the Z-Wave controller plugged into the
USB port.

=head1 METHODS

=over 4

=item C<new( device => "/dev/ttyUSB0" )>

Constructor, takes the device path to the plugged in Z-Wave controller.

=item C<connect()>

Initialize a connection with the Z-Wave controller plugged into the USB port.

=item C<payload_transmit( $payload_byte1, $payload_byte2, ... )>

A combination of C<send()> and C<recv_ack()>.

=item C<payload_send( $payload_byte1, $payload_byte2, ... )>

Wrap the given payload bytes into a package and send the result over to
the USB port.

=item C<payload_recv()>

Wait for a payload packet to arrive and receive it.

=item C<ack_recv()>

Wait for an ACK to arrive from the recipient of the previous C<send()>.

=item C<ack_send()>

Send an ACK back to acknowledge receiving a packet.

=item C<request_packet( $payload_byte1, $payload_byte2, ... )>

Packs a sequence of payload bytes into a request packet, by adding a request
header, packet length, and a trailing checksum. For example, 

                0x00, 0x13, 0x03, 0x03, 0x20, 0x01, 0x00, 0x05

becomes

    0x01, 0x09, 0x00, 0x13, 0x03, 0x03, 0x20, 0x01, 0x00, 0x05, 0xc1

with C<0x01> being the packet header, C<0x09> being the packet length,
and C<0xc1> being the checksum, which is calculated over all bytes
except the first one (see the ZWave protocol spec for details).

=item C<checksum( $byte1, $byte2, ... )>

Calculate the Z-Wave checksum required at the end of a package.

=back

=head2 ERROR HANDLING

If one of the methods above returns a non-true value, the underlying
error can be obtained by calling

    print $zwave->error();

Additional insight can be obtained by bumping up the Log4perl level
to $DEBUG in the C<CWave::Protocol> or root categories.

=head2 TODO List

=over 4

=item Retries

=back

=head1 LEGALESE

Copyright 2015 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2015, Mike Schilli <m@perlmeister.com>
