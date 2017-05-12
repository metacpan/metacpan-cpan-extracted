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
package UAV::Pilot::ARDrone::Control::Event;
$UAV::Pilot::ARDrone::Control::Event::VERSION = '1.1';
use v5.14;
use Moose;
use namespace::autoclean;
use AnyEvent;

eval "use UAV::Pilot::SDL::Joystick";
my $CAN_LOAD_JOYSTICK = $@ ? 0 : 1;
eval "use UAV::Pilot::SDL::NavFeeder";
my $CAN_LOAD_NAV_FEEDER = $@ ? 0 : 1;


extends 'UAV::Pilot::ARDrone::Control';

# The AR.Drone SDK manual says sending commands every 30ms is needed for smooth control
use constant CONTROL_TIMING_INTERVAL => 30 / 1000;

has 'cur_pitch' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    writer  => 'pitch',
);
has 'cur_roll' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    writer  => 'roll',
);
has 'cur_yaw' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    writer  => 'yaw',
);
has 'cur_vert_speed' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    writer  => 'vert_speed',
);
has 'joystick_num' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'joystick_takeoff_btn' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'joystick_takeoff_btn_last_state' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    writer  => '_set_joystick_takeoff_btn_last_state',
);
has 'do_init_joystick' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { $CAN_LOAD_JOYSTICK },
);

with 'UAV::Pilot::SDL::NavFeeder' if $CAN_LOAD_NAV_FEEDER;
with 'UAV::Pilot::Logger';



sub BUILD
{
    my ($self) = @_;

    if( $self->do_init_joystick && !$CAN_LOAD_JOYSTICK ) {
        die "Can't init joystick, because UAV::Pilot::SDL is not installed\n";
    }

    return 1;
}


sub init_event_loop
{
    my ($self, $cv, $event) = @_;
    $self->hover;

    my $control_timer; $control_timer = AnyEvent->timer(
        after    => 0.1,
        interval => $self->CONTROL_TIMING_INTERVAL,
        cb => sub {
            if( $self->cur_roll
                || $self->cur_pitch
                || $self->cur_vert_speed
                || $self->cur_yaw
            ) {
                $self->driver->at_pcmd( 1, 0,
                    $self->cur_roll,
                    $self->cur_pitch,
                    $self->cur_vert_speed,
                    $self->cur_yaw,
                );
            }

            $control_timer;
        },
    );
    my $comwatch_timer; $comwatch_timer = AnyEvent->timer(
        after    => 1,
        interval => 1.5,
        cb => sub {
            $self->reset_watchdog;
            $comwatch_timer;
        },
    );

    if( $self->do_init_joystick ) {
        $self->_logger->info( "Catching joystick events" );
        $event->add_event( UAV::Pilot::SDL::Joystick->EVENT_NAME, sub {
            my (@args) = @_;
            return $self->_process_sdl_input( @args );
        });
    }
    else {
        $self->_logger->info( "Not catching joystick events"
            . " (possible: $CAN_LOAD_JOYSTICK)" );
    }

    return 1;
}

sub hover
{
    my ($self) = @_;
    $self->$_( 0 ) for qw{
        pitch
        roll
        yaw
        vert_speed
    };
    return 1;
}

sub _process_sdl_input
{
    my ($self, $args) = @_;
    return 0 if $args->{joystick_num} != $self->joystick_num;
    my $takeoff_btn_cur_state = $args->{buttons}->[$self->joystick_takeoff_btn];

    $self->roll(       $self->_convert_sdl_input( $args->{roll}     ) );
    $self->pitch(      $self->_convert_sdl_input( $args->{pitch}    ) );
    $self->yaw(        $self->_convert_sdl_input( $args->{yaw}      ) );
    $self->vert_speed( $self->_convert_sdl_input( $args->{throttle} ) );

    # Toggle takeoff btn
    if(
        (! $takeoff_btn_cur_state) &&
        ($self->joystick_takeoff_btn_last_state)
    ) {
        if( $self->in_air ) {
            $self->land;
        }
        else {
            $self->takeoff;
        }
    }
    $self->_set_joystick_takeoff_btn_last_state( $takeoff_btn_cur_state );

    return 1;
}

sub _convert_sdl_input
{
    my ($self, $num) = @_;
    my $float = $num / UAV::Pilot::SDL::Joystick->MAX_AXIS_INT;
    $float = 1.0 if $float > 1.0;
    $float = -1.0 if $float < -1.0;
    return $float;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::Control::Event

=head1 SYNOPSIS

    my $cv = AnyEvent->condvar;
    my $event = UAV::Pilot::EasyEvent->new({
        condvar => $cv,
    });
    
    my $driver = UAV::Pilot::Driver::ARDrone->new( ... );
    $driver->connect;
    my $dev = UAV::Pilot::Control::ARDrone::Event->new({
        driver               => $driver,
        joystick_num         => 0,
        joystick_takeoff_btn => 3,
    });
    $uav->init_event_loop( $cv, $event );

    $dev->pitch( -0.8 );
    $cv->recv; # Will now pitch forward until you kill the process

=head1 DESCRIPTION

AnyEvent-based version of C<UAV::Pilot::Control::ARDrone>.  With the normal module, you 
need to send movement commands yourself every 30ms to maintain smooth control.  By using 
an event loop, this module handles the timing for you.

=head1 METHODS

=head2 init_event_loop

    init_event_loop( $cv, $event )

Sets up the event loop.  Takes C<$cv> (an C<AnyEvent::Condvar>) and C<$event> 
(a C<UAV::Pilot::EasyEvent>).

Will listen for joystick events.

=head2 hover

Stops all movement.

=cut
