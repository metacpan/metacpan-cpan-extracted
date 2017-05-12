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
package UAV::Pilot::WumpusRover::Control::Event;
use v5.14;
use Moose;
use namespace::autoclean;
# TODO relies on SDL
use UAV::Pilot::SDL::Joystick;

use constant CONTROL_UPDATE_TIME => 1 / 60;

extends 'UAV::Pilot::WumpusRover::Control';

has '_packet_queue' => (
    is      => 'ro',
    isa     => 'ArrayRef[UAV::Pilot::WumpusRover::Packet]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        _add_to_packet_queue => 'push',
    },
);
has 'joystick_num' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);


sub init_event_loop
{
    my ($self, $cv, $event) = @_;
    my $logger = $self->_logger;

    $logger->info( "Starting packet send event" );
    my $event_timer; $event_timer = AnyEvent->timer(
        after    => 0.01,
        interval => $self->CONTROL_UPDATE_TIME,
        cb       => sub {
            $logger->info( "Event firing off packet send event" );
            $self->send_move_packet;
            $event_timer;
        },
    );

    $logger->info( "Starting ack callback event" );
    $self->driver->set_ack_callback( sub {
        my ($orig_packet, $ack_packet) = @_;
        $event->send_event( 'ack_recv', $orig_packet, $ack_packet );
    });

    $event->add_event( UAV::Pilot::SDL::Joystick->EVENT_NAME, sub {
        my (@args) = @_;
        $logger->info( 'Received joystick event' );
        return $self->_process_sdl_input( @args );
    });

    $logger->info( "Done setting events" );
    return 1;
}

sub _process_sdl_input
{
    my ($self, $args) = @_;
    return 0 if $args->{joystick_num} != $self->joystick_num;

    my $turn = sprintf( '%.0f', $self->_map_values(
        UAV::Pilot::SDL::Joystick->MIN_AXIS_INT,
        UAV::Pilot::SDL::Joystick->MAX_AXIS_INT,
        -90, 90,
        $args->{roll},
    ) );
    my $throttle = sprintf( '%.0f', $self->_map_values(
        UAV::Pilot::SDL::Joystick->MIN_AXIS_INT,
        UAV::Pilot::SDL::Joystick->MAX_AXIS_INT,
        0, 100,
        $args->{throttle},
    ) );

    $self->turn( $turn );
    $self->throttle( $throttle );

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

    UAV::Pilot::WumpusRoverControl::Event

=head1 SYNOPSIS

    my $cv = AnyEvent->condvar;
    my $event = UAV::Pilot::EasyEvent->new({
        condvar => $cv,
    });
    
    my $driver = UAV::Pilot::WumpusRover::Driver->new({
        host => $hostname,
    });
    $driver->connect;
    
    my $control = UAV::Pilot::WumpusRover::Control::Event->new({
        driver       => $driver,
        joystick_num => 0,
    });
    $control->init_event_loop( $cv, $event );

    $cv->recv;

=head1 DESCRIPTION

An event-driven version of the WumpusRover Control.

=head1 METHODS

=head2 init_event_loop

    init_event_loop( $cv, $event );

Sets up the event loop.  Takes C<$cv> (an C<AnyEvent::Condvar>) and C<$event> 
(a C<UAV::Pilot::EasyEvent>).

Will listen for joystick events.

=cut
