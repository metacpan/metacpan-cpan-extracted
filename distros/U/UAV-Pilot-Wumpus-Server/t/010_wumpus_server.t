use Test::More tests => 22;
use strict;
use warnings;
use UAV::Pilot::Wumpus::PacketFactory;
use UAV::Pilot::Wumpus::Server::Backend;
use UAV::Pilot::Wumpus::Server::Backend::Mock;
use UAV::Pilot::Wumpus::Server::Mock;
use Test::Moose;


my $packet_count = 0;
my $backend = UAV::Pilot::Wumpus::Server::Backend::Mock->new;
my $server = UAV::Pilot::Wumpus::Server::Mock->new({
    listen_port => 65534,
    backend     => $backend,
});
isa_ok( $server => 'UAV::Pilot::Wumpus::Server' );
does_ok( $server => 'UAV::Pilot::Server' );


my $mapped_value = $server->_map_value( 0, 100, 0, 10, 50 );
cmp_ok( $mapped_value, '==', 5, "Mapping input and output values" );


ok(! $backend->started, "Not started yet" );
my $too_soon = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'RadioOutputs' );
$too_soon->ch1_out( 50 );
$too_soon->ch2_out( 100 );
$too_soon->make_checksum_clean;
$too_soon->set_packet_count( $packet_count++ );
$server->process_packet( $too_soon );

my $undef_packet = $server->last_packet_out;
ok(! defined $undef_packet, "No Ack packet, because we didn't start yet" );

my $startup_request = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'StartupRequest' );
$startup_request->set_packet_count( $packet_count++ );
$startup_request->make_checksum_clean;
$server->process_packet( $startup_request );

my $ack_packet = $server->last_packet_out;
isa_ok( $ack_packet => 'UAV::Pilot::Wumpus::Packet::Ack' );
cmp_ok( $ack_packet->checksum_received, '==', $startup_request->checksum,
    "Checksum1 received set on ACK packet" );
ok( $backend->started, "Started" );


my $radio_min_max = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'RadioMinMax' );
$radio_min_max->ch1_max( 100 );
$radio_min_max->ch2_max( 180 );
$radio_min_max->set_packet_count( $packet_count++ );
$radio_min_max->make_checksum_clean;
$server->process_packet( $radio_min_max );
my $min_max_ack = $server->last_packet_out;
cmp_ok( $min_max_ack->checksum_received, '==', $radio_min_max->checksum,
    "Radio Min Max packet ACK" );
cmp_ok( $server->ch1_max, '==', 100, "Channel1 max set on server" );
cmp_ok( $server->ch2_max, '==', 180, "Channel2 max set on server" );


my $radio_out = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'RadioOutputs' );
$radio_out->ch1_out( 0 );
$radio_out->ch2_out( 0 );
$radio_out->set_packet_count( $packet_count++ );
$radio_out->make_checksum_clean;
$server->process_packet( $radio_out );
my $out_ack = $server->last_packet_out;
cmp_ok( $out_ack->checksum_received, '==', $radio_out->checksum,
    "Radio Out packet ACK" );
cmp_ok( $backend->ch1_out, '==', 0, "Channel1 out set on backend" );
cmp_ok( $backend->ch2_out, '==', 0, "Channel2 out set on backend" );

$radio_out = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'RadioOutputs' );
$radio_out->ch1_out( 100 );
$radio_out->ch2_out( 90 );
$radio_out->set_packet_count( $packet_count++ );
$radio_out->make_checksum_clean;
$server->process_packet( $radio_out );
$out_ack = $server->last_packet_out;
cmp_ok( $out_ack->checksum_received, '==', $radio_out->checksum,
    "Radio Out packet ACK" );
cmp_ok( $backend->ch1_out, '==', 100, "Channel1 out set on backend" );
cmp_ok( $backend->ch2_out, '==', 50, "Channel2 out set on backend" );

$radio_out = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'RadioOutputs' );
$radio_out->ch1_out( 50 );
$radio_out->ch2_out( 180 );
$radio_out->set_packet_count( $packet_count++ );
$radio_out->make_checksum_clean;
$server->process_packet( $radio_out );
$out_ack = $server->last_packet_out;
cmp_ok( $out_ack->checksum_received, '==', $radio_out->checksum,
    "Radio Out packet ACK" );
cmp_ok( $backend->ch1_out, '==',  50, "Channel1 out set on backend" );
cmp_ok( $backend->ch2_out, '==', 100, "Channel2 out set on backend" );

$radio_out = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'RadioOutputs' );
$radio_out->ch1_out( 55 );
$radio_out->set_packet_count( $packet_count - 1);
$radio_out->make_checksum_clean;
$server->process_packet( $radio_out );
$out_ack = $server->last_packet_out;
cmp_ok( $backend->ch1_out, '==',  50, "Did not process packet with count too low" );

my $startup_request2 = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'StartupRequest' );
$startup_request2->set_packet_count( 1 );
$startup_request2->make_checksum_clean;
$server->process_packet( $startup_request2 );
cmp_ok( $server->max_seen_packet_count, '==', 1,
    "StartupRequest packet reset packet count" );
