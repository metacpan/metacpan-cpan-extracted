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
use Test::More tests => 3;
use v5.14;
use UAV::Pilot::Events;
use UAV::Pilot::EventHandler;
use AnyEvent;

package __Mock::EventHandler;
use Moose;

has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);

sub process_events
{
    my ($self) = @_;
    $self->condvar->send( 'Event hit' );
    return 1;
}


package __Mock::Bad;
# Package intentionally left blank



package main;

my $condvar = AnyEvent->condvar;
my $events = UAV::Pilot::Events->new({
    condvar => $condvar,
});
isa_ok( $events => 'UAV::Pilot::Events' );


eval {
    $events->register( __Mock::Bad->new );
};
if( $@ ) {
    pass( 'Did not pass correct object with role EventHandler' );
}
else {
    fail( 'Should have caught error' );
}


my $handler = __Mock::EventHandler->new({
    condvar => $condvar,
});
UAV::Pilot::EventHandler->meta->apply( $handler );
$events->register( $handler );

$events->init_event_loop;
my $got_str = $condvar->recv;
cmp_ok( $got_str, 'eq', 'Event hit', "Event loop ran" );
