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
package UAV::Pilot::WumpusRover::Driver;
use v5.14;
use Moose;
use namespace::autoclean;
use UAV::Pilot::WumpusRover;
use UAV::Pilot::WumpusRover::PacketFactory;
use Tie::IxHash;

use constant MAX_PACKET_QUEUE_LENGTH => 20;


has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => UAV::Pilot::WumpusRover::DEFAULT_PORT,
);
has 'host' => (
    is  => 'ro',
    isa => 'Str',
);
has '_socket' => (
    is  => 'rw',
    isa => 'IO::Socket::INET',
);
has '_ack_callback' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {} },
    writer  => 'set_ack_callback',
);
has '_packet_queue' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        my %tie = ();
        tie %tie, 'Tie::IxHash';
        \%tie;
    },
);

with 'UAV::Pilot::Driver';
with 'UAV::Pilot::Logger';


sub connect
{
    my ($self) = @_;
    my $logger = $self->_logger;

    $logger->info( 'Connecting . . . ' );
    $self->_init_connection;

    my $startup_request = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
        'RequestStartupMessage' );
    # TODO find out what Ardupilot wants for these params
    $startup_request->system_type( 0x00 );
    $startup_request->system_id( 0x00 );
    $logger->info( 'Sending RequestStartupMessage packet' );
    $self->_send_packet( $startup_request );

    return 1;
}


sub send_radio_output_packet
{
    my ($self, @channels) = @_;
    my $radio_packet = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
        'RadioOutputs' );

    foreach my $i (1..8) {
        my $value = $channels[$i-1] // 0;
        my $packet_field = 'ch' . $i . '_out';
        $radio_packet->$packet_field( $value );
    }

    $self->_send_packet( $radio_packet );
    return 1;
}


sub _init_connection
{
    my ($self) = @_;
    my $logger = $self->_logger;

    $logger->info( 'Open UDP socket to ' . $self->host . ':' . $self->port );
    my $socket = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerHost => $self->host,
        PeerPort => $self->port,
    ) or UAV::Pilot::IOException->throw({
        error => 'Could not open socket: ' . $!,
    });
    $logger->info( 'Done opening socket' );

    $self->_socket( $socket );
    return 1;
}

sub _packet_queue_size
{
    my ($self) = @_;
    return scalar keys %{ $self->_packet_queue };
}

sub _send_packet
{
    my ($self, $packet) = @_;
    $packet->make_checksum_clean;
    $packet->write( $self->_socket );
    $self->_add_to_packet_queue( $packet );
    return 1;
}

sub _process_ack
{
    my ($self, $ack) = @_;

    my $key = $ack->make_ack_packet_queue_key;
    $self->_logger->info( "Processing ack packet with key [$key]" );

    my $orig_packet = delete $self->_packet_queue->{$key};
    if( defined $orig_packet ) {
        $self->_ack_callback->( $orig_packet, $ack )
    }
    else {
        $self->_logger->warn( "Received Ack packet for key $key, but couldn't"
            . " find a matching packet" );
    }

    return 1;
}

sub _add_to_packet_queue
{
    my ($self, $packet) = @_;

    my $key = $packet->make_packet_queue_map_key;
    $self->_logger->info( "Adding packet to queue for key $key" );

    $self->_reduce_queue_length_to_max;
    $self->_packet_queue->{$key} = $packet;

    return 1;
}

sub _reduce_queue_length_to_max
{
    my ($self) = @_;

    my @keys = keys $self->_packet_queue;
    my $packets_removed = 0;
    while( scalar(@keys) >= $self->MAX_PACKET_QUEUE_LENGTH ) {
        my $next_key = shift @keys;
        $self->_logger->warn( "Queue too large, removing packet $next_key" );

        delete $self->_packet_queue->{$next_key};
        $packets_removed++;
    }

    return $packets_removed;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::WumpusRover::Driver

=head1 SYNOPSIS

    use UAV::Pilot::WumpusRover::Driver;
    
    my $driver = UAV::Pilot::WumpusRover::Driver->new({
        host => '10.0.0.10',
    });
    $driver->connect;

    $driver->send_radio_output_packet( 90, 100 );

=head1 DESCRIPTION

Driver for the WumpusRover.  Does the C<UAV::Pilot::Driver> role.

This is not intended to be used directly.  See 
C<UAV::Pilot::WumpusRover::Control::Event> for the best way to control the 
WumpusRover from client code.

=cut
