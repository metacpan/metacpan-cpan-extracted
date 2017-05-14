# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::ArdupilotProtocol::Packet;
use v5.14;
use Moose::Role;


use constant _USE_DEFAULT_BUILDARGS          => 1;
use constant _PACKET_QUEUE_MAP_KEY_SEPERATOR => '|';


has 'preamble' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0x3444,
);
has 'version' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0x00,
);
has 'checksum1' => (
    is     => 'ro',
    isa    => 'Int',
    writer => '_set_checksum1',
);
has 'checksum2' => (
    is     => 'ro',
    isa    => 'Int',
    writer => '_set_checksum2',
);
has '_is_checksum_clean' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
requires 'payload_length';
requires 'message_id';
requires 'payload_fields';
requires 'payload_fields_length';

with 'UAV::Pilot::Logger';


before 'BUILDARGS' => sub {
    my ($class, $args) = @_;
    return $args if delete $args->{fresh};
    return $args unless $class->_USE_DEFAULT_BUILDARGS;

    my $payload = delete $args->{payload};
    my @payload = @$payload;

    my %payload_fields_length = %{ $class->payload_fields_length };
    foreach my $field (@{ $class->payload_fields }) {
        $class->_logger->warn(
            "No entry for '$field' in $class->payload_fields_length"
        ) unless exists $payload_fields_length{$field};
        my $length = $payload_fields_length{$field} // 1;

        my $value = 0;
        foreach (1 .. $length) {
            $value <<= 8;
            $value |= shift @payload;
        }

        $args->{$field} = $value;
    }

    return $args;
};


sub write
{
    my ($self, $fh) = @_;
    $self->make_checksum_clean;

    my $packet = $self->make_byte_vector;
    $fh->print( $packet );

    return 1;
}

sub make_byte_vector
{
    my ($self) = @_;
    my $packet = pack 'n C*',
        $self->preamble,
        $self->payload_length,
        $self->message_id,
        $self->version,
        $self->get_ordered_payload_value_bytes,
        $self->checksum1,
        $self->checksum2;
    return $packet;
}

sub get_ordered_payload_values
{
    my ($self) = @_;
    return map $self->$_, @{ $self->payload_fields };
}

sub get_ordered_payload_value_bytes
{
    my ($self) = @_;
    my @bytes;
    my %payload_fields_length = %{ $self->payload_fields_length };

    foreach my $field (@{ $self->payload_fields }) {
        $self->_logger->warn(
            "No entry for '$field' in $self->payload_fields_length"
        ) unless exists $payload_fields_length{$field};
        my $length = $payload_fields_length{$field} // 1;

        my $raw_value = $self->$field;
        my @raw_bytes;
        foreach (1 .. $length) {
            if( defined $raw_value) {
                my $value = $raw_value & 0xFF;
                push @raw_bytes, $value;
                $raw_value >>= 8;
            }
            else {
                push @raw_bytes, 0;
            }
        }

        push @bytes, reverse @raw_bytes;
    }

    return @bytes;
}

sub _calc_checksum
{
    my ($self) = @_;
    my @data = (
        $self->payload_length,
        $self->message_id,
        $self->version,
        $self->get_ordered_payload_value_bytes,
    );

    my ($check1, $check2) = UAV::Pilot->checksum_fletcher8( @data );
    $self->_set_checksum1( $check1 );
    $self->_set_checksum2( $check2 );
    return 1;
}

sub make_checksum_clean
{
    my ($self) = @_;
    return 1 if $self->_is_checksum_clean;
    $self->_calc_checksum;
    $self->_is_checksum_clean( 1 );
    return 1;
}

sub make_packet_queue_map_key
{
    my ($self) = @_;
    # NOTE: any changes here must be reflected in
    # Packet::Ack::make_ack_packet_queue_key()
    my $key = join( $self->_PACKET_QUEUE_MAP_KEY_SEPERATOR,
        $self->message_id,
        $self->checksum1,
        $self->checksum2,
    );
    return $key;
}


sub _make_checksum_unclean
{
    my ($self) = @_;
    $self->_is_checksum_clean( 0 );
    return 1;
}


1;
__END__

=head1 NAME

  UAV::Pilot::ArdupilotProtocol::Packet

=head1 DESCRIPTION

Role for ArdupilotProtocol packets.  These are based on the ArduPilot protocol 
packets, as described here:

L<http://code.google.com/p/ardupilot-mega/wiki/Protocol>

No attempts have yet been made to test this against an existing ArduPilot 
implmentation, but it should be close.

Do not create Packets directly.  Instead, use
C<UAV::Pilot::ArdupilotProtocol::PacketFactory>.

Does the C<UAV::Pilot::Logger> role.

=head1 METHODS

=head2 write

    write( $fh )

Writes the packet to the given filehandle.

=head2 make_checksum_clean

Recalculates the checksum based on current field values.

=head2 make_byte_vector

Returns the packet fields in a single scalar full of bytes.

=head2 get_ordered_payload_vales

Returns the packet field values in the order they appear in C<payload_fields()>.

=head2 get_ordered_payload_value_bytes

Returns a byte array of all the packet fields in the order they appear in 
C<payload_fields()>.

=head1 make_packet_queue_map_key

Creates a unique key for this packet.

=head1 ATTRIBUTES

=head2 preamble

Fixed bytes that start every packet

=head2 version

Protocol version

=head2 checksum1

First checksum byte

=head2 checksum2

Second checksum byte

=head1 REQUIRED METHODS/ATTRIBUTES

=head2 message_id

ID for this type of message

=head2 payload_fields

Arrayref.  A list of field names in the order they appear in the packet.

=head2 payload_length

Hashref.  Keys match to an entry in C<payload_fields>.  Values are the length 
in bytes of that field.

=cut
