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
use Test::More tests => 4;
use v5.14;
use AnyEvent;
use UAV::Pilot::WumpusRover::Driver::Mock;
use UAV::Pilot::WumpusRover::Control::Event;
use UAV::Pilot::EasyEvent;
# TODO relies on SDL
use UAV::Pilot::SDL::Joystick;


my $wumpus = UAV::Pilot::WumpusRover::Driver::Mock->new({
});
$wumpus->connect;
my $dev = UAV::Pilot::WumpusRover::Control::Event->new({
    driver       => $wumpus,
    joystick_num => 0,

});

my $cv = AnyEvent->condvar;
my $event = UAV::Pilot::EasyEvent->new({
    condvar => $cv,
});
$dev->init_event_loop( $cv, $event );

$event->send_event( UAV::Pilot::SDL::Joystick->EVENT_NAME, {
    joystick_num => 0,
    roll         => UAV::Pilot::SDL::Joystick->MAX_AXIS_INT,
    pitch        => 0,
    yaw          => 0,
    throttle     => UAV::Pilot::SDL::Joystick->MAX_AXIS_INT,
    buttons      => [ 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, ],
});
cmp_ok( $dev->turn,     '==', 90, "Set turn from joystick" );
cmp_ok( $dev->throttle, '==', 100, "Set throttle from joystick" );

$event->send_event( UAV::Pilot::SDL::Joystick->EVENT_NAME, {
    joystick_num => 1,
    roll         => 0,
    pitch        => 0,
    yaw          => 0,
    throttle     => 0,
    buttons      => [ 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, ],
});
cmp_ok( $dev->throttle, '==', 100, "Only picks up events from joystick 0" );

$event->send_event( UAV::Pilot::SDL::Joystick->EVENT_NAME, {
    joystick_num => 0,
    roll         => UAV::Pilot::SDL::Joystick->MIN_AXIS_INT,
    pitch        => 0,
    yaw          => 0,
    throttle     => UAV::Pilot::SDL::Joystick->MAX_AXIS_INT,
    buttons      => [ 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, ],
});
cmp_ok( $dev->turn, '==', -90, "Set turn from joystick" );
