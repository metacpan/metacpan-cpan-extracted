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
use Test::More tests => 9;
use strict;
use warnings;
use UAV::Pilot::Control;
use UAV::Pilot::ControlRover;
use UAV::Pilot::WumpusRover::Control;
use UAV::Pilot::WumpusRover::Driver::Mock;
use Test::Moose;


my $driver = UAV::Pilot::WumpusRover::Driver::Mock->new({
    host => 'localhost',
    port => 49000,
});
$driver->connect;

my $control = UAV::Pilot::WumpusRover::Control->new({
    driver => $driver,
});
isa_ok( $control => 'UAV::Pilot::WumpusRover::Control' );
does_ok( $control => 'UAV::Pilot::Control' );
does_ok( $control => 'UAV::Pilot::ControlRover' );


$control->throttle( 150 );
$control->send_move_packet;
my $throttle_packet = $driver->last_sent_packet;
isa_ok( $throttle_packet => 'UAV::Pilot::WumpusRover::Packet::RadioOutputs' );
cmp_ok( $throttle_packet->ch1_out, '==', 150, "Throttle setting sent" );
cmp_ok( $throttle_packet->ch2_out, '==', 0, "Not turning" );

$control->turn( -100 );
$control->send_move_packet;
my $turn_packet = $driver->last_sent_packet;
isa_ok( $turn_packet => 'UAV::Pilot::WumpusRover::Packet::RadioOutputs' );
cmp_ok( $turn_packet->ch1_out, '==', 150, "Still setting throttle" );
cmp_ok( $turn_packet->ch2_out, '==', -100, "And now turning to the left, too" );
