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
use Test::More tests => 6;
use strict;
use warnings;
use AnyEvent;
use UAV::Pilot::Control;
use UAV::Pilot::ControlRover;
use UAV::Pilot::EasyEvent;
use UAV::Pilot::WumpusRover::Control::Event;
use UAV::Pilot::WumpusRover::Driver::Mock;
use UAV::Pilot::WumpusRover::PacketFactory;
use Test::Moose;


my $driver = UAV::Pilot::WumpusRover::Driver::Mock->new({
    host => 'localhost',
    port => 49000,
});
$driver->connect;

my $control = UAV::Pilot::WumpusRover::Control::Event->new({
    driver => $driver,
});
isa_ok( $control => 'UAV::Pilot::WumpusRover::Control::Event' );
isa_ok( $control => 'UAV::Pilot::WumpusRover::Control' );

my $cv = AnyEvent->condvar;
my $event = UAV::Pilot::EasyEvent->new({
    condvar => $cv,
});
$control->init_event_loop( $cv, $event );

my $ack_recv = 0;
my $checksum1_match = 0;
my $checksum2_match = 0;
my $msg_id_match = 0;
$event->add_event( 'ack_recv' => sub {
    my ($sent_packet, $ack_packet) = @_;
    $ack_recv++;
    $checksum1_match++
        if $sent_packet->checksum1 == $ack_packet->checksum_received1;
    $checksum2_match++
        if $sent_packet->checksum2 == $ack_packet->checksum_received2;
    $msg_id_match++
        if $sent_packet->message_id == $ack_packet->message_received_id;
});

my $write_time = $control->CONTROL_UPDATE_TIME;
my $write_duration = $write_time * 2 + ($write_time / 2);
my $test_timer; $test_timer = AnyEvent->timer(
    after => $write_duration,
    cb => sub {
        cmp_ok( $ack_recv, '>', 1, "Ack control packets" );
        cmp_ok( $checksum1_match, '==', $ack_recv, "Checksum1 matched up" );
        cmp_ok( $checksum2_match, '==', $ack_recv, "Checksum2 matched up" );
        cmp_ok( $msg_id_match,    '==', $ack_recv, "Message ID matched up" );
        $cv->send;
        $test_timer;
    },
);
my $send_timer; $send_timer = AnyEvent->timer(
    after => $write_time,
    cb => sub {
        $control->throttle( 100 );
        $control->turn( -50 );
        $send_timer;
    },
);
$cv->recv;
