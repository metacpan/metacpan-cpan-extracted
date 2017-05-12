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
package UAV::Pilot::ARDrone::Control;
$UAV::Pilot::ARDrone::Control::VERSION = '1.1';
use v5.14;
use Moose;
use namespace::autoclean;
use DateTime;
use String::CRC32 ();
use UAV::Pilot::EasyEvent;
use UAV::Pilot::NavCollector::AckEvents;


with 'UAV::Pilot::ControlHelicopter';

use constant NAV_EVENT_READ_TIME => 1 / 60;


has 'video' => (
    is  => 'rw',
    isa => 'Maybe[UAV::Pilot::ARDrone::Video]',
);
has 'session_id' => (
    is     => 'ro',
    isa    => 'Maybe[Str]',
    writer => '_set_session_id',
);
has 'app_id' => (
    is     => 'ro',
    isa    => 'Maybe[Str]',
    writer => '_set_app_id',
);
has 'user_id' => (
    is     => 'ro',
    isa    => 'Maybe[Str]',
    writer => '_set_user_id',
);
has '_did_set_multiconfig' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has 'in_air' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    writer  => '_set_in_air',
);

with 'UAV::Pilot::Logger';


sub BUILD
{
    my ($self) = @_;

    if( defined $self->user_id && defined $self->app_id ) {
        $self->set_multiconfig( $self->user_id, $self->app_id,
            $self->session_id );
    }

    return 1;
}


sub takeoff
{
    my ($self) = @_;
    $self->driver->at_ref( 1, 0 );
    $self->_set_in_air( 1 );
    return 1;
}

sub land
{
    my ($self) = @_;
    $self->driver->at_ref( 0, 0 );
    $self->_set_in_air( 0 );
    return 1;
}

sub pitch
{
    my ($self, $pitch) = @_;
    $self->driver->at_pcmd( 1, 0, 0, $pitch, 0, 0 );
}

sub roll
{
    my ($self, $roll) = @_;
    $self->driver->at_pcmd( 1, 0, $roll, 0, 0, 0 );
}

sub yaw
{
    my ($self, $yaw) = @_;
    $self->driver->at_pcmd( 1, 0, 0, 0, 0, $yaw );
}

sub vert_speed
{
    my ($self, $speed) = @_;
    $self->driver->at_pcmd( 1, 0, 0, 0, $speed, 0 );
}

sub calibrate
{
    my ($self) = @_;
    $self->driver->at_calib( $self->driver->ARDRONE_CALIBRATION_DEVICE_MAGNETOMETER );
}

sub emergency
{
    my ($self) = @_;
    $self->driver->at_ref( 0, 1 );
    $self->video->emergency_restart if defined $self->video;
    return 1;
}

sub reset_watchdog
{
    my ($self) = @_;
    $self->driver->at_comwdg();
    return 1;
}

sub hover
{
    my ($self) = @_;
    return 1;
}

{
    my $send = 'UAV::Pilot::ARDrone::Driver';
    my @FLIGHT_ANIMS = (
        {
            name   => 'phi_m30',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_M30_DEG,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_M30_DEG_MAYDAY,
        },
        {
            name   => 'phi_30',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_30_DEG,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_30_DEG_MAYDAY,
        },
        {
            name   => 'theta_m30',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_M30_DEG,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_M30_DEG_MAYDAY,
        },
        {
            name   => 'theta_30',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_30_DEG,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_30_DEG_MAYDAY,
        },
        {
            name   => 'theta_20deg_yaw_200',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_200DEG,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_200DEG_MAYDAY,
        },
        {
            name   => 'theta_20deg_yaw_m200',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_M200DEG,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_M200DEG_MAYDAY,
        },
        {
            name   => 'turnaround',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_MAYDAY,
        },
        {
            name   => 'turnaround_godown',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_GODOWN,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_GODOWN_MAYDAY,
        },
        {
            name   => 'yaw_shake',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_SHAKE,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_SHAKE_MAYDAY,
        },
        {
            name   => 'yaw_dance',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_DANCE,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_DANCE_MAYDAY,
        },
        {
            name   => 'phi_dance',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_DANCE,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_DANCE_MAYDAY,
        },
        {
            name   => 'theta_dance',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_DANCE,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_DANCE_MAYDAY,
        },
        {
            name   => 'vz_dance',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_VZ_DANCE,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_VZ_DANCE_MAYDAY,
        },
        {
            name   => 'wave',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_WAVE,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_WAVE_MAYDAY,
        },
        {
            name   => 'phi_theta_mixed',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_THETA_MIXED,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_THETA_MIXED_MAYDAY,
        },
        {
            name   => 'double_phi_theta_mixed',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_DOUBLE_PHI_THETA_MIXED,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_DOUBLE_PHI_THETA_MIXED_MAYDAY,
        },
        {
            name   => 'flip_ahead',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_AHEAD,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_AHEAD_MAYDAY,
        },
        {
            name   => 'flip_behind',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_BEHIND,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_BEHIND_MAYDAY,
        },
        {
            name   => 'flip_left',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_LEFT,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_LEFT_MAYDAY,
        },
        {
            name   => 'flip_right',
            anim   => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_RIGHT,
            mayday => $send->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_RIGHT_MAYDAY,
        },
    );
    foreach my $def (@FLIGHT_ANIMS) {
        my $name   = $def->{name};
        my $anim   = $def->{anim};
        my $mayday = $def->{mayday};

        no strict 'refs';
        *$name = sub {
            my ($self) = @_;
            $self->send_config(
                $self->driver->ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM,
                sprintf( '%d,%d', $anim, $mayday ),
            );
        };
    }
}

{
    my $send = 'UAV::Pilot::ARDrone::Driver';

    my @LED_ANIMS = (
        {
            name => 'led_blink_green_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_BLINK_GREEN_RED,
        },
        {
            name => 'led_blink_green',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_BLINK_GREEN,
        },
        {
            name => 'led_blink_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_BLINK_RED,
        },
        {
            name => 'led_blink_orange',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_BLINK_ORANGE,
        },
        {
            name => 'led_snake_green_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_SNAKE_GREEN_RED,
        },
        {
            name => 'led_fire',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_FIRE,
        },
        {
            name => 'led_standard',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_STANDARD,
        },
        {
            name => 'led_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_RED,
        },
        {
            name => 'led_green',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_GREEN,
        },
        {
            name => 'led_red_snake',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_RED_SNAKE,
        },
        {
            name => 'led_blank',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_BLANK,
        },
        {
            name => 'led_right_missile',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_RIGHT_MISSILE,
        },
        {
            name => 'led_left_missile',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_LEFT_MISSILE,
        },
        {
            name => 'led_double_missile',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_DOUBLE_MISSILE,
        },
        {
            name => 'led_front_left_green_others_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_FRONT_LEFT_GREEN_OTHERS_RED,
        },
        {
            name => 'led_front_right_green_others_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_FRONT_RIGHT_GREEN_OTHERS_RED,
        },
        {
            name => 'led_rear_left_green_others_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_REAR_LEFT_GREEN_OTHERS_RED,
        },
        {
            name => 'led_rear_right_green_others_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_REAR_RIGHT_GREEN_OTHERS_RED,
        },
        {
            name => 'led_left_green_right_red',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_LEFT_GREEN_RIGHT_RED,
        },
        {
            name => 'led_left_red_right_green',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_LEFT_RED_RIGHT_GREEN,
        },
        {
            name => 'led_blink_standard',
            anim => $send->ARDRONE_CONFIG_LED_ANIMATION_BLINK_STANDARD,
        },
    );
    foreach my $def (@LED_ANIMS) {
        my $name = $def->{name};
        my $anim = $def->{anim};

        no strict 'refs';
        *$name = sub {
            my ($self, $freq, $duration) = @_;
            $self->send_config(
                $self->driver->ARDRONE_CONFIG_LEDS_LEDS_ANIM,
                sprintf( '%d,%d,%d',
                    $anim,
                    $self->driver->float_convert( $freq ),
                    $duration,
                ),
            );
        };
    }
}

sub start_userbox_nav_data
{
    my ($self) = @_;
    $self->send_config(
        $self->driver->ARDRONE_CONFIG_USERBOX_USERBOX_CMD,
        $self->driver->ARDRONE_USERBOX_CMD_START,
    );
    return 1;
}

sub stop_userbox_nav_data
{
    my ($self) = @_;
    $self->send_config(
        $self->driver->ARDRONE_CONFIG_USERBOX_USERBOX_CMD,
        $self->driver->ARDRONE_USERBOX_CMD_STOP,
    );
    return 1;
}

sub cancel_userbox_nav_data
{
    my ($self) = @_;
    $self->send_config(
        $self->driver->ARDRONE_CONFIG_USERBOX_USERBOX_CMD,
        $self->driver->ARDRONE_USERBOX_CMD_CANCEL,
    );
    return 1;
}

sub take_picture
{
    my ($self, $delay, $num_pics, $date) = @_;
    $date = DateTime->now->strftime( '%Y%m%d_%H%M%S' )
        if ! defined $date;
    $self->send_config(
        $self->driver->ARDRONE_CONFIG_USERBOX_USERBOX_CMD,
        sprintf( '%d,%d,%d,%s', 
            $self->driver->ARDRONE_USERBOX_CMD_SCREENSHOT,
            $delay,
            $num_pics,
            $date,
        ),
    );
    return 1;
}

sub set_multiconfig
{
    my ($self, $user_id, $app_id, $session_id) = @_;
    $session_id //= $self->_generate_session_id;
    my $driver = $self->driver;

    $self->_logger->info( "Setting multiconfig keys.  App ID [$app_id],"
        . "User ID [$user_id], Session ID [$session_id]" );

    $driver->at_config_ids( $session_id, $user_id, $app_id );
    $driver->at_config(
        $driver->ARDRONE_CONFIG_CUSTOM_SESSION_ID, $session_id );
    sleep 1;

    $driver->at_config_ids( $session_id, $user_id, $app_id );
    $driver->at_config( $driver->ARDRONE_CONFIG_CUSTOM_PROFILE_ID, $user_id );
    sleep 1;

    $driver->at_config_ids( $session_id, $user_id, $app_id );
    $driver->at_config(
        $driver->ARDRONE_CONFIG_CUSTOM_APPLICATION_ID, $app_id );
    sleep 1;

    $self->_set_session_id( $session_id );
    $self->_set_app_id( $app_id );
    $self->_set_user_id( $user_id );
    $self->_did_set_multiconfig( 1 );

    return 1;
}

sub send_config
{
    my ($self, $name, $value) = @_;
    my $driver = $self->driver;
    $driver->at_config_ids( $self->session_id, $self->user_id, $self->app_id )
        if $self->_did_set_multiconfig;
    $driver->at_config( $name, $value );
    return 1;
}

sub record_usb
{
    my ($self) = @_;
    $self->send_config(
        $self->driver->ARDRONE_CONFIG_VIDEO_VIDEO_ON_USB,
        'TRUE',
    );
    return 1;
}

sub setup_read_nav_event
{
    my ($self, $event) = @_;

    my $ack = UAV::Pilot::NavCollector::AckEvents->new({
        easy_event => $event,
    });
    $self->driver->add_nav_collector( $ack );

    my $w; $w = AnyEvent->timer(
        after    => $self->NAV_EVENT_READ_TIME,
        interval => $self->NAV_EVENT_READ_TIME,
        cb => sub {
            my $driver = $self->driver;
            $driver->read_nav_packet;
            $w;
        },
    );
    return 1;
}


sub _generate_session_id
{
    my ($self) = @_;
    my $id     = String::CRC32::crc32( int rand 2**16 );
    my $hex_id = sprintf '%x', $id;
    return $hex_id;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::Control

=head1 SYNOPSIS

    my $driver = UAV::Pilot::ARDrone::Driver->new( ... );
    $driver->connect;
    my $dev = UAV::Pilot::ARDrone::Control->new({
        driver => $driver,
    });
    
    $dev->takeoff;
    $dev->pitch( 0.5 );
    $dev->wave;
    $dev->flip_left;
    $dev->land;

=head1 DESCRIPTION

L<UAV::Pilot::ControlHelicopter> implementation for the Parrot AR.Drone.

=head1 METHODS

=head2 new

B<NOTE>: It's highly recommended that you initialize the subclass 
C<UAV::Pilot::ARDrone::Control::Event> instead of this one.

    new({
        driver => $driver,
        video  => $video_driver,
    });

Constructor.  As with C<UAV::Pilot::Control>, the C<driver> option is a mandatory 
parameter with the value being a C<UAV::Pilot::Driver::ARDrone> object.

The optional C<video> parameter is a C<UAV::Pilot::Driver::ARDrone::Video> object.  When 
the emergency mode is toggled on the ARDrone, the video stream needs to be restarted.  
Placing the object here will call C<emergency_restart()> on the video object for you.

=head2 takeoff

Takeoff.

=head2 land

Land.

=head2 pitch

    pitch( 0.5 )

Pitch (front-to-back movement).  Takes a floating point number between -1.0 and 1.0.  On 
the AR.Drone, negative numbers pitch the nose down and fly forward.

=head2 roll

    roll( -1.0 )

Roll (left-to-right movement).  Takes a floating point number between -1.0 and 1.0.  On 
the AR.Drone, negative numbers go left.

=head2 yaw

    yaw( -0.25 )

Yaw (spin).  Takes a floating point number between -1.0 and 1.0.  On the AR.Drone, 
negative numbers spin left.

=head2 vert_speed

    vert_speed( 0.7 )

Change the vertical speed.  Takes a floating point number between -1.0 and 1.0.  On the 
AR.Drone, negative numbers make it go down.

=head2 calibrate

Calibrates the magnetometer.  This must be done while in flight.  The drone will spin 
around (yaw movement) while it does this.

=head2 emergency

Toggles the emergency state.  If your UAV goes out of control, call this to immediately 
shut it off.  When in the emergency state, it will not be responsive to further commands.  
Call this again to bring it out of this state.

=head2 reset_watchdog

Sends a command to reset the watchdog process.  You need to send some command at least 
every 2 seconds, or else the AR.Drone thinks the connection was lost.  If you don't have 
anything else to send, send this one.

If you run C<start_event_loop()>, the reset will happen for you.

=head2 hover

Stops the UAV and hovers in place.

=head2 start_userbox_nav_data

Starts saving navigation data on the UAV itself.  The file will be in the directory:

    /boxes/flight_YYYYMMDD_hhmmss

You can FTP into the AR.Drone to retrieve this.

=head2 stop_userbox_nav_data

Stops logging navigation data on the UAV.

=head2 cancel_userbox_nav_data

Stops logging navigation data on the UAV B<AND> deletes the log directory.

=head2 take_picture

    take_picture( $delay, $num_pics )

Saves a picture in JPG format to:

    /boxes/flight_YYYYMMDD_hhmmss/picture_YYYYMMDD_hhmmss.jpg

You can FTP into the AR.Drone to retrieve this.

=head2 record_usb

Start recording the video stream to a USB stick attached to the AR.Drone's internal USB 
port.  The stick must have at least 100MB free.

=head2 setup_read_nav_event

  setup_read_nav_event( $event );

Pass a C<UAV::Pilot::EasyEvent> object.  Sets up a 
C<UAV::Pilot::NavCollector::AckEvents> and starts an event timer for reading 
nav packets.

=head2 set_multiconfig

  set_multiconfig( $user_id, $app_id, $session_id )

B<NOTE>: This doesn't yet seem to work right.  You can set the keys, but 
the UAV won't respond to config commands after that.  It should just be a 
matter of sending C<AT*CONFIG_IDS> before each C<AT*CONFIG>, which is what 
C<send_config()> will do for you.  But it doesn't work.  Still debugging . . . 

Pass a unique user, app, and session ID.  The best way to generate these is 
to take a string identifying your user and app and run it through a CRC32.  
The C<$session_id> is optional; if passed, it should be unique to this 
particular run.

In the AR.Drone, "multiconfig" is a way to set configurations that are unique 
to the user, app, or session.  For backwards compatibility with old apps, 
the AR.Drone only lets you set some keys when using multiconfig.  See the 
AR.Drone SDK docs for details.

=head2 send_config

  send_config( $name, $value )

Send a config name/value.  If you used C<set_multiconfig()>, this will send 
the necessary commands before the config setting.

=head1 FLIGHT ANIMATION METHODS

The Parrot AR.Drone comes preprogrammed with a bunch of "flight animations" (complicated 
achrebatic manuevers).  You can call the methods below to run them.  Note that some of 
these need a generous amount of horizontal and vertical space, so be sure to be in a 
wide open area for testing.

I find "wave" and "flip_behind" are particularly good ways to impress house guests :)

    phi_m30_deg
    phi_30_deg
    theta_m30_deg
    theta_30_deg
    theta_20deg_yaw_200deg
    theta_20deg_yaw_m200deg
    turnaround
    turnaround_godown
    yaw_shake
    yaw_dance
    phi_dance
    theta_dance
    vz_dance
    wave
    phi_theta_mixed
    double_phi_theta_mixed
    flip_ahead
    flip_behind
    flip_left
    flip_right

=head1 LED ANIMATION METHODS

The LEDs on the Parrot AR.Drone can be directly controlled using these animation methods.  
They all take two parameters: the frequency (in Hz) as a floating point number, and 
the duration.

    led_blink_green_red
    led_blink_green
    led_blink_red
    led_blink_orange
    led_snake_green_red
    led_fire
    led_standard
    led_red
    led_green
    led_red_snake
    led_blank
    led_right_missile
    led_left_missile
    led_double_missile
    led_front_left_green_others_red
    led_front_right_green_others_red
    led_rear_right_green_others_red
    led_rear_left_green_others_red
    led_left_green_right_red
    led_left_red_right_green
    led_blink_standard

=cut
