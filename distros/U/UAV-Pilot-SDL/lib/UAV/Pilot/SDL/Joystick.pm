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
package UAV::Pilot::SDL::Joystick;
use v5.14;
use Moose;
use namespace::autoclean;
use File::HomeDir;
use YAML ();
use SDL;
use SDL::Joystick;

my $IS_SDL_INIT_DONE = 0;

use constant MAX_AXIS_INT      => 32768;
use constant MIN_AXIS_INT      => -32768;
use constant EVENT_NAME        => 'uav_pilot_sdl_joystick';
use constant DEFAULT_CONF_FILE => 'sdl_joystick.yml';
use constant DEFAULT_CONF      => {
    joystick_num        => 0,
    roll_axis           => 0,
    pitch_axis          => 1,
    yaw_axis            => 2,
    throttle_axis       => 3,
    takeoff_btn         => 0,
    roll_correction     => 1,
    pitch_correction    => 1,
    yaw_correction      => 1,
    throttle_correction => -1,
    btn_action_map      => {
        0 => 'takeoff_land',
        1 => 'flip_left',
        2 => 'flip_right',
    },
};
use constant BUTTON_ACTIONS => {
    # "takeoff_land" is handled as a special case, since we need to toggle between them
    #
    # 'action_name' => '$control->method_name',
    emergency   => 'emergency',
    wave        => 'wave',
    flip_ahead  => 'flip_ahead',
    flip_behind => 'flip_behind',
    flip_left   => 'flip_left',
    flip_right  => 'flip_right',
};


with 'UAV::Pilot::EventHandler';
with 'UAV::Pilot::Logger';

has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);
has 'joystick_num' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'roll_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'pitch_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);
has 'yaw_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 2,
);
has 'throttle_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 3,
);
has 'roll_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);
has 'pitch_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);
has 'yaw_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);
has 'throttle_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => -1,
);
has 'takeoff_btn' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0, 
);
has 'is_in_air' => (
    traits  => ['Bool'],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    handles => {
        toggle_is_in_air => 'toggle',
        set_is_in_air    => 'set',
        unset_is_in_air  => 'unset',
    },
);
has 'joystick' => (
    is  => 'ro',
    isa => 'SDL::Joystick',
);
has 'events' => (
    is  => 'ro',
    isa => 'UAV::Pilot::EasyEvent',
);
has '_prev_takeoff_btn_status' => (
    is  => 'rw',
    isa => 'Bool',
);
has 'btn_action_map' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub {{}},
);
has '_btn_prev_state' => (
    is      => 'rw',
    isa     => 'HashRef[Bool]',
    default => sub {{}},
);


sub BUILDARGS
{
    my ($self, $args) = @_;
    $self->_one_time_init;

    my $new_args = $self->_process_args( $args );

    my $joystick = SDL::Joystick->new( $new_args->{joystick_num} );
    die "Could not open joystick $$new_args{joystick_num}\n" unless $joystick;
    $new_args->{joystick} = $joystick;

    return $new_args;
}


sub process_events
{
    my ($self) = @_;
    SDL::Joystick::update();
    my $joystick = $self->joystick;
    my @buttons = map {
        $joystick->get_button( $_ )
    } (0 .. $joystick->num_buttons - 1);

    $self->_logger->info( 'Sending joystick event' );
    $self->events->send_event( $self->EVENT_NAME, {
        joystick_num => $self->joystick_num,
        roll => $joystick->get_axis( $self->roll_axis )
            * $self->roll_correction,
        pitch => $joystick->get_axis( $self->pitch_axis )
            * $self->pitch_correction,
        yaw => $joystick->get_axis( $self->yaw_axis )
            * $self->yaw_correction,
        throttle => $joystick->get_axis( $self->throttle_axis )
            * $self->throttle_correction,
        buttons => \@buttons,
    });

    return 1;
}

sub close
{
    my ($self) = @_;
    #$self->joystick->close;
    return 1;
}


sub _process_args
{
    my ($self, $args) = @_;
    my $conf_path = defined $args->{conf_path}
        ? $args->{conf_path}
        : do {
            my $conf_dir = UAV::Pilot->default_config_dir;
            my $conf_path = File::Spec->catfile( $conf_dir, $self->DEFAULT_CONF_FILE );
            YAML::DumpFile( $conf_path, $self->DEFAULT_CONF ) unless -e $conf_path;
            $conf_path;
        };
    UAV::Pilot::FileNotFoundException->throw({
        file  => $conf_path,
        error => "Could not find file $conf_path",
    }) unless -e $conf_path;
    my $conf_args = YAML::LoadFile( $conf_path );

    # Get the takeoff_land button special case
    # TODO fetch these with key 'btn_action_map_$TYPE', where 
    # '$TYPE' is the name of the UAV (e.g. WumpusRover or ARDrone)
    # TODO handle toggle buttons
    foreach my $key (keys %{ $conf_args->{btn_action_map} }) {
        my $value = $conf_args->{btn_action_map}{$key};
        if( $value eq 'takeoff_land' ) {
            $conf_args->{takeoff_btn} = $key;
            delete $conf_args->{btn_action_map}{$key};
            last;
        }
    }

    my %new_args = (
        %$conf_args,
        condvar      => $args->{condvar},
        events       => $args->{events},
    );
    return \%new_args;
}

# Currently unused
sub _process_action_buttons
{
    my ($self, $joystick, $dev) = @_;

    foreach my $btn (keys %{ $self->btn_action_map }) {
        my $cur_state = $joystick->get_button( $btn );
        # Only perform the action after we let off the button
        if( $self->_btn_prev_state->{$btn} && ($cur_state == 0) ) {
            my $action = $self->btn_action_map->{$btn};
            next unless exists $self->BUTTON_ACTIONS->{$action};
            my $method = $self->BUTTON_ACTIONS->{$action};
            $dev->$method;
        }

        $self->_btn_prev_state->{$btn} = $cur_state;
    }

    return 1;
}


sub _one_time_init
{
    return 1 if $IS_SDL_INIT_DONE;

    SDL::init_sub_system( SDL_INIT_JOYSTICK );

    $IS_SDL_INIT_DONE = 1;
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

    UAV::Pilot::SDL::Joystick

=head1 SYNOPSIS

    my $condvar = AnyEvent->condvar;
    my $event = UAV::Pilot::Events->new({
        condvar => $condvar,
    });
    my $easy_event = UAV::Pilot::EasyEvent->new({
        condvar => $condvar,
    });
    my $sdl_events = UAV::Pilot::SDL::Events->new({
        condvar => $condvar,
    });
    $events->register( $sdl_events );
    
    my $control = UAV::Pilot::Controller::ARDrone->new( ... );
    my $joy = UAV::Pilot::SDL::Joystick->new({
        condvar    => $condvar,
        events     => $events,
        conf_path  => '/path/to/config.yml', # optional
    });
    $events->register( $joy );

    # Capture joystick movements in EasyEvent
    $events->add_event( UAV::Pilot::SDL::Joystick->EVENT_NAME, sub {
        my ($args) = @_;
        my $joystick_num = $args->{joystick_num};
        my $roll         = $args->{roll};
        my $pitch        = $args->{pitch};
        my $yaw          = $args->{yaw};
        my $throttle     = $args->{throttle};
        my @buttons      = @{ $args->{buttons} };
        ...
    });

=head1 DESCRIPTION

Handles joystick control for SDL joysticks.  This does the role 
C<UAV::Pilot::EventHandler>, so it can be passed to 
C<<UAV::Pilot::Events->register()>>.  It's recommended to also add the 
C<UAV::Pilot::SDL::Events> handler to the events object, as that will 
take care of the C<SDL_QUIT> events.  Without that, there's no way to stop 
the process other than C<kill -9>.

Joystick configuration will be loaded from a C<YAML> config file.  You can find the 
path with C<<UAV::Pilot->default_config_dir()>>.  If the file does not exist, it will 
be created automatically.

Joystick movements are sent over EasyEvent.  The event name is specified in 
the C<EVENT_NAME> constant in this package.  See the SYNOPSIS for the 
argument list.

=head1 CONFIGURATION FILE

The config file is in C<YAML> format.  It contains the following keys:

=head2 joystick_num

The SDL joystick number to use

=head2 pitch_axis

Axis number of joystick to use for pitch.

=head2 roll_axis

Axis number of joystick to use for roll.

=head2 yaw_axis

Axis number of joystick to use for yaw.

=head2 throttle_axis

Axis number of joystick to use for throttle.

=head2 btn_action_map

This is a mapping of button numbers to some kind of action, such as takeoff/land or flip.  
The format is "btn_num: action".  Actions are:

=over 4

=item * takeoff_land

=item * emergency

=item * wave

=item * flip_ahead

=item * flip_behind

=item * flip_left

=item * flip_right

=back

=head2 Axis Corrections

These can be used to cut the inputs by a percentage.  All should be numbers between 1.0 and 
-1.0, with negative numbers reversing the axis.

=head3 roll_correction

=head3 pitch_correcton

=head3 yaw_correction

=head3 throttle_correction

=cut
