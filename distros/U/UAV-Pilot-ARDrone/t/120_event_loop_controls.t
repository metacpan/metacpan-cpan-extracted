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
use Test::More;
use v5.14;
use AnyEvent;
use UAV::Pilot::ARDrone::Driver::Mock;
use UAV::Pilot::ARDrone::Control::Event;
use UAV::Pilot::EasyEvent;
use Test::Moose;

eval "use UAV::Pilot::SDL::Joystick";
if( $@ ) {
    plan skip_all => "UAV::Pilot::SDL not installed";
}
else {
    plan tests => 8;
}

my $ardrone = UAV::Pilot::ARDrone::Driver::Mock->new({
    host => 'localhost',
});
$ardrone->connect;
my $dev = UAV::Pilot::ARDrone::Control::Event->new({
    driver => $ardrone,
});


cmp_ok( $dev->_convert_sdl_input( 0 ),      '==', 0.0,  "Convert SDL input 0" );
cmp_ok( $dev->_convert_sdl_input( 32768 ),  '==', 1.0,  "Convert SDL input 2**15" );
cmp_ok( $dev->_convert_sdl_input( -32767 ), '==', -0.999969482421875,
    "Convert SDL input -(2**15 + 1)" );
cmp_ok( $dev->_convert_sdl_input( 16384 ),  '==', 0.5,  "Convert SDL input 16384" );
cmp_ok( $dev->_convert_sdl_input( -32768 ), '==', -1.0, "Convert overflow input" );


my $cv = AnyEvent->condvar;
my $event = UAV::Pilot::EasyEvent->new({
    condvar => $cv,
});
$dev->init_event_loop( $cv, $event );

$dev->pitch( -0.8 );
my $found = 0;
my @saved_cmds = $ardrone->saved_commands;
foreach (@saved_cmds) {
    $found = 1 if /\AAT\*PCMD=\d+,\d+,\d+,-1085485875/;
}
ok(! $found, "Pitch command not yet sent" );

my $control_timer; $control_timer = AnyEvent->timer(
    after => 3,
    cb    => sub {
        my @saved_cmds = $ardrone->saved_commands;

        my $found = 0;
        foreach (@saved_cmds) {
            $found = 1 if /\AAT\*PCMD=\d+,\d+,\d+,-1085485875/;
        }
        ok( $found, "Pitch command sent" );

        $dev->hover;
    },
);
my $hover_timer; $hover_timer = AnyEvent->timer(
    after => 4,
    cb    => sub {
        my @saved_cmds = $ardrone->saved_commands;

        my $found = 0;
        foreach (@saved_cmds) {
            $found = 1 if /\AAT\*PCMD=/;
        }
        ok(! $found, "Hover mode, no movement command sent" );

        $cv->send( "end program" );
    },
);

$cv->recv;
