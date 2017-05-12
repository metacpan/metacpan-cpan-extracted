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
use Test::More tests => 2;
use AnyEvent;
use UAV::Pilot::ARDrone::Driver::Mock;
use UAV::Pilot::ARDrone::Control;
use UAV::Pilot::EasyEvent;


package MockDriver;
use Moose;

extends 'UAV::Pilot::ARDrone::Driver::Mock';

has 'num_read_nav' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub read_nav_packet
{
    my ($self) = @_;
    $self->num_read_nav( $self->num_read_nav + 1 );
    return $self->SUPER::read_nav_packet(
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
}


package main;

my $driver = MockDriver->new;
my $control = UAV::Pilot::ARDrone::Control->new({
    driver => $driver,
});

my $cv = AnyEvent->condvar;
my $event = UAV::Pilot::EasyEvent->new({
    condvar => $cv,
});
$control->setup_read_nav_event( $event );


my $toggle = 0;
$event->add_event( 'nav_ack_toggle' => sub {
    $toggle++;
});

my $read_time = $control->NAV_EVENT_READ_TIME;
my $read_duration = $read_time * 2 + ($read_time / 2);
my $timer; $timer = AnyEvent->timer(
    after    => $read_duration,
    cb => sub {
        cmp_ok( $driver->num_read_nav, '==', 2, "Read nav events" );
        cmp_ok( $toggle, '==', 1, "Toggle event" );
        $cv->send;
        $timer;
    },
);
$cv->recv;
