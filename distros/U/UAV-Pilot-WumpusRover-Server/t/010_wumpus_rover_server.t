use Test::More tests => 28;
use strict;
use warnings;
use UAV::Pilot::WumpusRover::PacketFactory;
use UAV::Pilot::WumpusRover::Server::Backend;
use UAV::Pilot::WumpusRover::Server::Backend::Mock;
use UAV::Pilot::WumpusRover::Server::Mock;
use Test::Moose;


my $backend = UAV::Pilot::WumpusRover::Server::Backend::Mock->new;
my $server = UAV::Pilot::WumpusRover::Server::Mock->new({
    listen_port => 65534,
    backend     => $backend,
});
isa_ok( $server => 'UAV::Pilot::WumpusRover::Server' );
does_ok( $server => 'UAV::Pilot::Server' );


my $mapped_value = $server->_map_value( 0, 100, 0, 10, 50 );
cmp_ok( $mapped_value, '==', 5, "Mapping input and output values" );


ok(! $backend->started, "Not started yet" );
my $too_soon = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RadioTrims' );
$too_soon->ch1_trim( 50 );
$too_soon->ch2_trim( 100 );
$too_soon->make_checksum_clean;
$server->process_packet( $too_soon );

my $undef_packet = $server->last_packet_out;
ok(! defined $undef_packet, "No Ack packet, because we didn't start yet" );

my $startup_request = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RequestStartupMessage' );
$startup_request->system_type( 1 );
$startup_request->system_id( 2 );
$startup_request->make_checksum_clean;
$server->process_packet( $startup_request );

my $ack_packet = $server->last_packet_out;
isa_ok( $ack_packet => 'UAV::Pilot::WumpusRover::Packet::Ack' );
cmp_ok( $ack_packet->message_received_id, '==', $startup_request->message_id,
    "Message ID received set on ACK packet" );
cmp_ok( $ack_packet->checksum_received1, '==', $startup_request->checksum1,
    "Checksum1 received set on ACK packet" );
cmp_ok( $ack_packet->checksum_received2, '==', $startup_request->checksum2,
    "Checksum2 received set on ACK packet" );
ok( $backend->started, "Started" );


my $radio_trims = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RadioTrims' );
$radio_trims->ch1_trim( 50 );
$radio_trims->ch2_trim( 100 );
$radio_trims->make_checksum_clean;
$server->process_packet( $radio_trims );
my $trim_ack = $server->last_packet_out;
cmp_ok( $trim_ack->message_received_id, '==', $radio_trims->message_id,
    "Radio Trim packet ACK" );
cmp_ok( $backend->ch1_trim, '==', 50, "Channel1 trim set on backend" );
cmp_ok( $backend->ch2_trim, '==', 100, "Channel2 trim set on backend" );


my $radio_max = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RadioMaxes' );
$radio_max->ch1_max( 100 );
$radio_max->ch2_max( 180 );
$radio_max->make_checksum_clean;
$server->process_packet( $radio_max );
my $max_ack = $server->last_packet_out;
cmp_ok( $max_ack->message_received_id, '==', $radio_max->message_id,
    "Radio Max packet ACK" );
cmp_ok( $server->ch1_max, '==', 100, "Channel1 max set on server" );
cmp_ok( $server->ch2_max, '==', 180, "Channel2 max set on server" );


my $radio_min = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RadioMins' );
$radio_min->ch1_min( 0 );
$radio_min->ch2_min( 0 );
$radio_min->make_checksum_clean;
$server->process_packet( $radio_min );
my $min_ack = $server->last_packet_out;
cmp_ok( $min_ack->message_received_id, '==', $radio_min->message_id,
    "Radio Min packet ACK" );
cmp_ok( $server->ch1_min, '==', 0, "Channel1 min set on server" );
cmp_ok( $server->ch2_min, '==', 0, "Channel2 min set on server" );


my $radio_out = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RadioOutputs' );
$radio_out->ch1_out( 0 );
$radio_out->ch2_out( 0 );
$radio_out->make_checksum_clean;
$server->process_packet( $radio_out );
my $out_ack = $server->last_packet_out;
cmp_ok( $out_ack->message_received_id, '==', $radio_out->message_id,
    "Radio Out packet ACK" );
cmp_ok( $backend->ch1_out, '==', 0, "Channel1 out set on backend" );
cmp_ok( $backend->ch2_out, '==', 0, "Channel2 out set on backend" );

$radio_out = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RadioOutputs' );
$radio_out->ch1_out( 100 );
$radio_out->ch2_out( 90 );
$radio_out->make_checksum_clean;
$server->process_packet( $radio_out );
$out_ack = $server->last_packet_out;
cmp_ok( $out_ack->message_received_id, '==', $radio_out->message_id,
    "Radio Out packet ACK" );
cmp_ok( $backend->ch1_out, '==', 100, "Channel1 out set on backend" );
cmp_ok( $backend->ch2_out, '==', 50, "Channel2 out set on backend" );

$radio_out = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'RadioOutputs' );
$radio_out->ch1_out( 50 );
$radio_out->ch2_out( 180 );
$radio_out->make_checksum_clean;
$server->process_packet( $radio_out );
$out_ack = $server->last_packet_out;
cmp_ok( $out_ack->message_received_id, '==', $radio_out->message_id,
    "Radio Out packet ACK" );
cmp_ok( $backend->ch1_out, '==',  50, "Channel1 out set on backend" );
cmp_ok( $backend->ch2_out, '==', 100, "Channel2 out set on backend" );
