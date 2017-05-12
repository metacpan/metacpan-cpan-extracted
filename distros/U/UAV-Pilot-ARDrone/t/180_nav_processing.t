# Copyright (c) 2015  Timm Murray
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
use Test::More tests => 6;
use v5.14;
use warnings;
use AnyEvent;
use UAV::Pilot::ARDrone::Driver::Mock;
use UAV::Pilot::EasyEvent;
use UAV::Pilot::NavCollector;
use UAV::Pilot::NavCollector::AckEvents;
use UAV::Pilot::ARDrone::NavPacket;

package MockNavCollector;
use Moose;

with 'UAV::Pilot::NavCollector';

has 'cb' => (
    is  => 'ro',
    isa => 'CodeRef',
);

sub got_new_nav_packet
{
    my ($self, $nav_packet) = @_;
    $self->cb->( $nav_packet );
    return 1;
}



package main;

my $condvar = AnyEvent->condvar;
my $easy_events = UAV::Pilot::EasyEvent->new({
    condvar => $condvar,
});

my @packet_data_ack_on = (
    # These are in little-endian order
    '88776655',   # Header
    'ffffffff',   # Drone state
    '336f0000',   # Sequence number
    '01000000',   # Vision flag
    # No options on this packet besides checksum
    'ffff',       # Checksum ID
    '0800',       # Checksum size
    'c1030000',   # Checksum data (will be wrong)
);
my @packet_data_ack_off = (
    # These are in little-endian order
    '88776655',   # Header
    '00000000',   # Drone state
    '336f0000',   # Sequence number
    '01000000',   # Vision flag
    # No options on this packet besides checksum
    'ffff',       # Checksum ID
    '0800',       # Checksum size
    'c1030000',   # Checksum data (will be wrong)
);
my $packet_ack_on = UAV::Pilot::ARDrone::NavPacket->new({
    packet => make_packet( join( '', @packet_data_ack_on )),
});
my $packet_ack_off = UAV::Pilot::ARDrone::NavPacket->new({
    packet => make_packet( join( '', @packet_data_ack_off )),
});
ok( $packet_ack_on->state_control_received, "Ack received on packet" );
ok(! $packet_ack_off->state_control_received, "Ack not received on packet" );


my $mock_driver = UAV::Pilot::ARDrone::Driver::Mock->new;

my ($nav_status_on_test, $nav_status_off_test, $nav_status_toggle_test,
    $nav_collector_test) = (0, 0, 0, 0);
my $nav_collector = MockNavCollector->new({
    cb => sub {
        $nav_collector_test++;
    },
});
my $ack_events = UAV::Pilot::NavCollector::AckEvents->new({
    easy_event => $easy_events,
});
$mock_driver->add_nav_collector( $_ ) for $nav_collector, $ack_events;

$easy_events->add_event( 'nav_ack_on' => sub {
    $nav_status_on_test++;
});
$easy_events->add_event( 'nav_ack_off' => sub {
    $nav_status_off_test++;
});
$easy_events->add_event( 'nav_ack_toggle' => sub {
    $nav_status_toggle_test++;
});


$easy_events->add_timer({
    duration       => 100,
    duration_units => $easy_events->UNITS_MILLISECOND,
    cb => sub {
        $mock_driver->read_nav_packet( @packet_data_ack_off );
    },
})->add_timer({
    duration       => 100,
    duration_units => $easy_events->UNITS_MILLISECOND,
    cb => sub {
        $mock_driver->read_nav_packet( @packet_data_ack_on );
    },
})->add_timer({
    duration       => 100,
    duration_units => $easy_events->UNITS_MILLISECOND,
    cb => sub {
        $mock_driver->read_nav_packet( @packet_data_ack_on );
    },
})
->add_timer({
    duration       => 100,
    duration_units => $easy_events->UNITS_MILLISECOND,
    cb => sub {
        $mock_driver->read_nav_packet( @packet_data_ack_off );
        $condvar->send;
    },
});
$easy_events->add_timer({
    duration       => 1000,
    duration_units => $easy_events->UNITS_MILLISECOND,
    cb => sub {
        diag "Gave up waiting";
        $condvar->send;
    },
});
$easy_events->init_event_loop;
$condvar->recv;

cmp_ok( $nav_status_on_test,     '==', 2, "Nav status on"          );
cmp_ok( $nav_status_off_test,    '==', 2, "Nav status off"         );
cmp_ok( $nav_status_toggle_test, '==', 2, "Nav status toggled"     );
cmp_ok( $nav_collector_test,     '==', 4, "Nav collector callback" );


sub make_packet
{
    my ($hex_str) = @_;
    pack 'H*', $hex_str;
}
