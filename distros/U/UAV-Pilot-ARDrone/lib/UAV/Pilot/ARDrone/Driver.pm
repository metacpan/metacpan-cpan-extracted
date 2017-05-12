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
package UAV::Pilot::ARDrone::Driver;
$UAV::Pilot::ARDrone::Driver::VERSION = '1.1';
use v5.14;
use Moose;
use namespace::autoclean;
use IO::Socket;
use IO::Socket::INET;
use IO::Socket::Multicast;
use UAV::Pilot::Exceptions;
use UAV::Pilot::NavCollector;
use UAV::Pilot::ARDrone::NavPacket;

with 'UAV::Pilot::Driver';
with 'UAV::Pilot::Logger';

use constant {
    TRUE  => 'TRUE',
    FALSE => 'FALSE',

    ARDRONE_CALIBRATION_DEVICE_MAGNETOMETER => 0,
    ARDRONE_CALIBRATION_DEVICE_NUMBER       => 1,

    ARDRONE_CTRL_GET_CONFIG => 4,

    ARDRONE_MULTICAST_ADDR          => '224.1.1.1',
    ARDRONE_PORT_COMMAND            => 5556,
    ARDRONE_PORT_COMMAND_TYPE       => 'udp',
    ARDRONE_PORT_NAV_DATA           => 5554,
    ARDRONE_PORT_NAV_DATA_TYPE      => 'udp',
    ARDRONE_PORT_VIDEO_P264_V1      => 5555,
    ARDRONE_PORT_VIDEO_P264_V2      => 5555,
    ARDRONE_PORT_VIDEO_P264_V1_TYPE => 'udp',
    ARDRONE_PORT_VIDEO_P264_V2_TYPE => 'tcp',
    ARDRONE_PORT_VIDEO_H264         => 5555,
    ARDRONE_PORT_VIDEO_H264_TYPE    => 'tcp',
    ARDRONE_PORT_CTRL               => 5559,
    ARDRONE_PORT_CTRL_TYPE          => 'tcp',

    ARDRONE_USERBOX_CMD_STOP       => 0,
    ARDRONE_USERBOX_CMD_CANCEL     => 3,
    ARDRONE_USERBOX_CMD_START      => 1,
    ARDRONE_USERBOX_CMD_SCREENSHOT => 2,

    ARDRONE_CONFIG_GENERAL_NUM_VERSION_CONFIG => 'general:num_version_config',
    ARDRONE_CONFIG_GENERAL_NUM_VERSION_MB     => 'general:num_version_mb',
    ARDRONE_CONFIG_GENERAL_NUM_VERSION_SOFT   => 'general:num_version_soft',
    ARDRONE_CONFIG_GENERAL_DRONE_SERIAL       => 'general:drone_serial',
    ARDRONE_CONFIG_GENERAL_SOFT_BUILD_DATE    => 'general:soft_build_date',
    ARDRONE_CONFIG_GENERAL_MOTOR1_SOFT        => 'general:motor1_soft',
    ARDRONE_CONFIG_GENERAL_MOTOR1_HARD        => 'general:motor1_hard',
    ARDRONE_CONFIG_GENERAL_MOTOR1_SUPPLIER    => 'general:motor1_supplier',
    ARDRONE_CONFIG_GENERAL_ARDRONE_NAME       => 'general:ardrone_name',
    ARDRONE_CONFIG_GENERAL_FLYING_TIME        => 'general:flying_time',
    ARDRONE_CONFIG_GENERAL_NAVDATA_DEMO       => 'general:navdata_demo',
    ARDRONE_CONFIG_GENERAL_NAVDATA_OPTIONS    => 'general:navdata_options',
    ARDRONE_CONFIG_GENERAL_COM_WATCHDOG       => 'general:com_watchdog',
    ARDRONE_CONFIG_GENERAL_VIDEO_ENABLE       => 'general:video_enable',
    ARDRONE_CONFIG_GENERAL_VBAT_MIN           => 'general:vbat_min',

    ARDRONE_CONFIG_CONTROL_ACCS_OFFSET             => 'control:accs_offset',
    ARDRONE_CONFIG_CONTROL_ACCS_GAINS              => 'control:accs_gains',
    ARDRONE_CONFIG_CONTROL_GYROS_OFFSET            => 'control:gyros_offset',
    ARDRONE_CONFIG_CONTROL_GYROS_GAINS             => 'control:gyros_gains',
    ARDRONE_CONFIG_CONTROL_GYROS110_OFFSET         => 'control:gyros110_offset',
    ARDRONE_CONFIG_CONTROL_GYROS110_GAINS          => 'control:gyros110_gains',
    ARDRONE_CONFIG_CONTROL_MAGNETO_OFFSET          => 'control:magneto_offset',
    ARDRONE_CONFIG_CONTROL_MAGNETO_RADIUS          => 'control:magneto_radius',
    ARDRONE_CONFIG_CONTROL_GYRO_OFFSET_THR_X       => 'control:gyro_offset_thr_x',
    ARDRONE_CONFIG_CONTROL_PWM_REF_GYROS           => 'control:pwm_ref_gyros',
    ARDRONE_CONFIG_CONTROL_OSCTUN_VALUE            => 'control:osctun_value',
    ARDRONE_CONFIG_CONTROL_OSCTUN_TEST             => 'control:osctun_test',
    ARDRONE_CONFIG_CONTROL_CONTROL_LEVEL           => 'control:control_level',
    ARDRONE_CONFIG_CONTROL_EULER_ANGLE_MAX         => 'control:euler_angle_max',
    ARDRONE_CONFIG_CONTROL_ALTITUDE_MAX            => 'control:altitude_max',
    ARDRONE_CONFIG_CONTROL_ALTITUDE_MIN            => 'control:altitude_min',
    ARDRONE_CONFIG_CONTROL_CONTROL_IPHONE_TILT     => 'control:control_iphone_tilt',
    ARDRONE_CONFIG_CONTROL_CONTROL_VZ_MAX          => 'control:control_vz_max',
    ARDRONE_CONFIG_CONTROL_CONTROL_YAW             => 'control:control_yaw',
    ARDRONE_CONFIG_CONTROL_OUTDOOR                 => 'control:outdoor',
    ARDRONE_CONFIG_CONTROL_FLIGHT_WITHOUT_SHELL    => 'control:flight_without_shell',
    ARDRONE_CONFIG_CONTROL_AUTONOMOUS_FLIGHT       => 'control:autonomous_flight',
    ARDRONE_CONFIG_CONTROL_MANUAL_TRIM             => 'control:manual_trim',
    ARDRONE_CONFIG_CONTROL_INDOOR_EULER_ANGLE_MAX  => 'control:indoor_euler_angle_max',
    ARDRONE_CONFIG_CONTROL_INDOOR_CONTROL_VZ_MAX   => 'control:indoor_control_vz_max',
    ARDRONE_CONFIG_CONTROL_INDOOR_CONTROL_YAW      => 'control:indoor_control_yaw',
    ARDRONE_CONFIG_CONTROL_OUTDOOR_EULER_ANGLE_MAX => 'control:outdoor_euler_angle_max',
    ARDRONE_CONFIG_CONTROL_OUTDOOR_CONTROL_VZ_MAX  => 'control:outdoor_control_vz_max',
    ARDRONE_CONFIG_CONTROL_OUTDOOR_CONTROL_YAW     => 'control:outdoor_control_yaw',
    ARDRONE_CONFIG_CONTROL_FLYING_MODE             => 'control:flying_mode',
    ARDRONE_CONFIG_CONTROL_HOVERING_RANGE          => 'control:hovering_range',
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM             => 'control:flight_anim',

    ARDRONE_CONFIG_NETWORK_SSID_SINGLE_PLAYER => 'network:ssid_single_player',
    ARDRONE_CONFIG_NETWORK_WIFI_MODE          => 'network:wifi_mode',
    ARDRONE_CONFIG_NETWORK_WIFI_MODE_AP       => 0,
    ARDRONE_CONFIG_NETWORK_WIFI_MODE_JOIN     => 1,
    ARDRONE_CONFIG_NETWORK_WIFI_MODE_STATION  => 2,
    ARDRONE_CONFIG_NETWORK_OWNER_MAC          => 'network:owner_mac',

    ARDRONE_CONFIG_PIC_ULTRASOUND_FREQ     => 'pic:ultrasound_freq',
    ARDRONE_CONFIG_PIC_ULTRASOUND_WATCHDOG => 'pic:ultrasound_watchdog',
    ARDRONE_CONFIG_PIC_PIC_VERSION         => 'pic:pic_version',

    ARDRONE_CONFIG_VIDEO_CAMIF_FPS            => 'video:camif_fps',
    ARDRONE_CONFIG_VIDEO_CODEC_FPS            => 'video:codec_fps',
    ARDRONE_CONFIG_VIDEO_CAMIF_BUFFERS        => 'video:camif_buffers',
    ARDRONE_CONFIG_VIDEO_NUM_TRACKERS         => 'video:num_trackers',
    ARDRONE_CONFIG_VIDEO_VIDEO_CODEC          => 'video:codec',
    ARDRONE_CONFIG_VIDEO_VIDEO_SLICES         => 'video:video_slices',
    ARDRONE_CONFIG_VIDEO_VIDEO_LIVE_SOCKET    => 'video:video_live_socket',
    ARDRONE_CONFIG_VIDEO_VIDEO_STORAGE_SPACE  => 'video:video_storage_space',
    ARDRONE_CONFIG_VIDEO_BITRATE              => 'video:bitrate',
    ARDRONE_CONFIG_VIDEO_MAX_BITRATE          => 'video:max_bitrate',
    ARDRONE_CONFIG_VIDEO_BITRATE_CONTROL_MODE => 'video:bitrate_control_mode',
    ARDRONE_CONFIG_VIDEO_BITRATE_STORAGE      => 'video:bitrate_storage',
    ARDRONE_CONFIG_VIDEO_VIDEO_CHANNEL        => 'video:video_channel',
    ARDRONE_CONFIG_VIDEO_VIDEO_ON_USB         => 'video:video_on_usb',
    ARDRONE_CONFIG_VIDEO_VIDEO_FILE_INDEX     => 'video:video_file_index',

    ARDRONE_CONFIG_LEDS_LEDS_ANIM => 'leds:leds_anim',

    ARDRONE_CONFIG_DETECT_ENEMY_COLORS              => 'detect:enemy_colors',
    ARDRONE_CONFIG_DETECT_GROUNDSTRIPE_COLORS       => 'detect:groundstripe_colors',
    ARDRONE_CONFIG_DETECT_ENEMY_WITHOUT_SHELL       => 'detect:enemy_without_shell',
    ARDRONE_CONFIG_DETECT_TYPE                      => 'detect:detect_type',
    ARDRONE_CONFIG_DETECT_DETECTIONS_SELECT_H       => 'detect:detections_select_h',
    ARDRONE_CONFIG_DETECT_DETECTIONS_SELECT_V_HSYNC => 'detect:detections_select_v_hsync',
    ARDRONE_CONFIG_DETECT_DETECTIONS_SELECT_V       => 'detect:detections_select_v',

    ARDRONE_CONFIG_USERBOX_USERBOX_CMD => 'userbox:userbox_cmd',

    ARDRONE_CONFIG_GPS_LATITUDE  => 'gps:latitude',
    ARDRONE_CONFIG_GPS_LONGITUDE => 'gps:longitude',
    ARDRONE_CONFIG_GPS_ALTITUDE  => 'gps:altitude',

    ARDRONE_CONFIG_CUSTOM_APPLICATION_ID   => 'custom:application_id',
    ARDRONE_CONFIG_CUSTOM_APPLICATION_DESC => 'custom:application_desc',
    ARDRONE_CONFIG_CUSTOM_PROFILE_ID       => 'custom:profile_id',
    ARDRONE_CONFIG_CUSTOM_PROFILE_DESC     => 'custom:profile_desc',
    ARDRONE_CONFIG_CUSTOM_SESSION_ID       => 'custom:session_id',
    ARDRONE_CONFIG_CUSTOM_SESSION_DESC     => 'custom:session_desc',

    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_M30_DEG             => 0,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_30_DEG              => 1,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_M30_DEG           => 2,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_30_DEG            => 3,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_200DEG  => 4,,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_M200DEG => 5,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND              => 6,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_GODOWN       => 7,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_SHAKE               => 8,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_DANCE               => 9,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_DANCE               => 10,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_DANCE             => 11,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_VZ_DANCE                => 12,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_WAVE                    => 13,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_THETA_MIXED         => 14,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_DOUBLE_PHI_THETA_MIXED  => 15,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_AHEAD              => 16,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_BEHIND             => 17,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_LEFT               => 18,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_RIGHT              => 19,

    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_M30_DEG_MAYDAY             => 1000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_30_DEG_MAYDAY              => 1000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_M30_DEG_MAYDAY           => 1000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_30_DEG_MAYDAY            => 1000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_200DEG_MAYDAY  => 1000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_M200DEG_MAYDAY => 1000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_MAYDAY              => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_GODOWN_MAYDAY       => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_SHAKE_MAYDAY               => 2000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_DANCE_MAYDAY               => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_DANCE_MAYDAY               => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_DANCE_MAYDAY             => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_VZ_DANCE_MAYDAY                => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_WAVE_MAYDAY                    => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_THETA_MIXED_MAYDAY         => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_DOUBLE_PHI_THETA_MIXED_MAYDAY  => 5000,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_AHEAD_MAYDAY              => 15,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_BEHIND_MAYDAY             => 15,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_LEFT_MAYDAY               => 15,
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_RIGHT_MAYDAY              => 15,

    ARDRONE_CONFIG_LED_ANIMATION_BLINK_GREEN_RED              => 0,
    ARDRONE_CONFIG_LED_ANIMATION_BLINK_GREEN                  => 1,
    ARDRONE_CONFIG_LED_ANIMATION_BLINK_RED                    => 2,
    ARDRONE_CONFIG_LED_ANIMATION_BLINK_ORANGE                 => 3,
    ARDRONE_CONFIG_LED_ANIMATION_SNAKE_GREEN_RED              => 4,
    ARDRONE_CONFIG_LED_ANIMATION_FIRE                         => 5,
    ARDRONE_CONFIG_LED_ANIMATION_STANDARD                     => 6,
    ARDRONE_CONFIG_LED_ANIMATION_RED                          => 7,
    ARDRONE_CONFIG_LED_ANIMATION_GREEN                        => 8,
    ARDRONE_CONFIG_LED_ANIMATION_RED_SNAKE                    => 9,
    ARDRONE_CONFIG_LED_ANIMATION_BLANK                        => 10,
    ARDRONE_CONFIG_LED_ANIMATION_RIGHT_MISSILE                => 11,
    ARDRONE_CONFIG_LED_ANIMATION_LEFT_MISSILE                 => 12,
    ARDRONE_CONFIG_LED_ANIMATION_DOUBLE_MISSILE               => 13,
    ARDRONE_CONFIG_LED_ANIMATION_FRONT_LEFT_GREEN_OTHERS_RED  => 14,
    ARDRONE_CONFIG_LED_ANIMATION_FRONT_RIGHT_GREEN_OTHERS_RED => 15,
    ARDRONE_CONFIG_LED_ANIMATION_REAR_RIGHT_GREEN_OTHERS_RED  => 16,
    ARDRONE_CONFIG_LED_ANIMATION_REAR_LEFT_GREEN_OTHERS_RED   => 17,
    ARDRONE_CONFIG_LED_ANIMATION_LEFT_GREEN_RIGHT_RED         => 18,
    ARDRONE_CONFIG_LED_ANIMATION_LEFT_RED_RIGHT_GREEN         => 19,
    ARDRONE_CONFIG_LED_ANIMATION_BLINK_STANDARD               => 20,

    ARDRONE_CONFIG_VIDEO_CHANNEL_ZAP_CHANNEL_HORI => 0,
    ARDRONE_CONFIG_VIDEO_CHANNEL_ZAP_CHANNEL_VERT => 1,

    ARDRONE_CONFIG_VIDEO_CODEC_MP4_360P           => 0x80,
    ARDRONE_CONFIG_VIDEO_CODEC_H264_360P          => 0x81,
    ARDRONE_CONFIG_VIDEO_CODEC_MP4_360P_H264_720P => 0x82,
    ARDRONE_CONFIG_VIDEO_CODEC_H264_720P          => 0x83,
    ARDRONE_CONFIG_VIDEO_CODEC_MP4_360P_H264_360P => 0x88,

    ARDRONE_CONFIG_VIDEO_MAX_FPS => 30,
    ARDRONE_CONFIG_VIDEO_MIN_FPS => 1,

    ARDRONE_CONFIG_VIDEO_VBC_MODE_DYNAMIC => 1,


    NAVDATA_INIT_MULTICAST => 'foo',
    NAVDATA_INIT_UNICAST   => pack( 'c*', 0x01, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ),

};


has 'port' => (
    is      => 'rw',
    isa     => 'Int',
    default => 5556,
);

has 'host' => (
    is  => 'rw',
    isa => 'Str',
);
has 'iface' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'wlan0',
);
has 'seq' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    writer  => '__set_seq',
);
has 'nav_collectors' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[UAV::Pilot::NavCollector]',
    default => sub {[]},
    handles => {
        add_nav_collector => 'push',
    },
);
has 'do_multicast_navdata' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has '_socket' => (
    is => 'rw',
);
has '_nav_socket' => (
    is  => 'rw',
    isa => 'IO::Socket',
);
has 'last_nav_packet' => (
    is     => 'ro',
    isa    => 'Maybe[UAV::Pilot::ARDrone::NavPacket]',
    writer => '_set_last_nav_packet',
);
has '_is_multi_cmd_mode' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has '_multi_cmds' => (
    traits => ['Array'],
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    handles => {
        '_add_multi_cmd'    => 'push',
        '_clear_multi_cmds' => 'clear',
    },
);


sub connect
{
    my ($self) = @_;
    my $socket = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerPort => $self->port,
        PeerAddr => $self->host,
    ) or UAV::Pilot::IOException->throw(
        error => 'Could not open socket: ' . $!,
    );
    $self->_socket( $socket );

    $self->_init_nav_data;
    $self->_init_drone;
    return 1;
}

sub at_ref
{
    my ($self, $takeoff, $emergency) = @_;

    # According to the ARDrone developer docs, bits 18, 20, 22, 24, and 28 should be 
    # init'd to one, and all others to zero.  Bit 9 is takeoff, 8 is emergency shutoff.
    my $cmd_number = (1 << 18) 
        | (1 << 20)
        | (1 << 22)
        | (1 << 24)
        | (1 << 28)
        | ($takeoff << 9)
        | ($emergency << 8);

    my $cmd = 'AT*REF=' . $self->_next_seq . ',' . $cmd_number . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_pcmd
{
    my ($self, $do_progressive, $do_combined_yaw,
        $roll, $pitch, $vert_speed, $yaw) = @_;

    if( ($roll > 1) || ($roll < -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Roll should be between 1.0 and -1.0',
        );
    }
    if( ($pitch > 1) || ($pitch < -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Pitch should be between 1.0 and -1.0',
        );       
    }
    if( ($vert_speed > 1) || ($vert_speed < -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Vertical speed should be between 1.0 and -1.0',
        );       
    }
    if( ($yaw > 1) || ($yaw < -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Yaw should be between 1.0 and -1.0',
        );       
    }

    # According to docs *always* set Progressive bit to 1, or else drone enters 
    # hover mode.  Set Absolute bit to 1 for absolute control.
    my $cmd_number = (1 << 0)
        | ($do_combined_yaw << 1)
        | (!$do_progressive << 2);

    my $cmd = 'AT*PCMD='
        . join( ',', 
            $self->_next_seq,
            $cmd_number,
            $self->float_convert( $roll ),
            $self->float_convert( $pitch ),
            $self->float_convert( $vert_speed ),
            $self->float_convert( $yaw ),
        )
        . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_pcmd_mag
{
    my ($self, $do_progressive, $do_combined_yaw,
        $roll, $pitch, $vert_speed, $angular_speed,
        $magneto, $magneto_accuracy) = @_;

    if( ($roll >= 1) || ($roll <= -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Roll should be between 1.0 and -1.0',
        );
    }
    if( ($pitch >= 1) || ($pitch <= -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Pitch should be between 1.0 and -1.0',
        );       
    }
    if( ($vert_speed >= 1) || ($vert_speed <= -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Vertical speed should be between 1.0 and -1.0',
        );       
    }
    if( ($angular_speed >= 1) || ($angular_speed <= -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Angular speed should be between 1.0 and -1.0',
        );       
    }
    if( ($magneto >= 1) || ($magneto <= -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Magneto should be between 1.0 and -1.0',
        );       
    }
    if( ($magneto_accuracy >= 1) || ($magneto_accuracy <= -1) ) {
        UAV::Pilot::NumberOutOfRangeException->throw(
            error => 'Magneto accuracy should be between 1.0 and -1.0',
        );       
    }

    my $cmd_number = ($do_progressive << 0)
        | ($do_combined_yaw << 1);

    my $cmd = 'AT*PCMD_MAG='
        . join( ',', 
            $self->_next_seq,
            $cmd_number,
            $self->float_convert( $roll ),
            $self->float_convert( $pitch ),
            $self->float_convert( $vert_speed ),
            $self->float_convert( $angular_speed ),
            $self->float_convert( $magneto  ),
            $self->float_convert( $magneto_accuracy ),
        )
        . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_ftrim
{
    my ($self) = @_;

    my $cmd = 'AT*FTRIM=' . $self->_next_seq . ",\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_calib
{
    my ($self, $device) = @_;

    my $cmd = 'AT*CALIB=' . $self->_next_seq . ",$device" . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_config
{
    my ($self, $name, $value) = @_;

    my $cmd = 'AT*CONFIG=' . $self->_next_seq
        . ',' . qq{"$name"}
        . ',' . qq{"$value"}
        . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_config_ids
{
    my ($self, $session_id, $user_id, $app_id) = @_;

    my $cmd = 'AT*CONFIG_IDS=' . $self->_next_seq . ','
        . join( ',',
            $session_id,
            $user_id,
            $app_id,
        )
        . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_comwdg
{
    my ($self) = @_;

    my $cmd = 'AT*COMWDG=' . $self->_next_seq . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

sub at_ctrl
{
    my ($self, $val) = @_;

    my $cmd = 'AT*CTRL=' . $self->_next_seq . ",$val" . "\r";
    $self->_send_cmd( $cmd );

    return 1;
}

# Takes an IEEE-754 float and converts its exact bits in memory to a signed 32-bit integer.
# Yes, the ARDrone dev docs actually say to put floats across the wire in this format.
sub float_convert
{
    my ($self, $float) = @_;
    my $int = unpack( "l", pack( "f", $float ) );
    return $int;
}

sub read_nav_packet
{
    my ($self) = @_;

    my $ret = 1;
    my $buf = '';
    my $in = $self->_nav_socket->recv( $buf, 4096 );

    if( $in ) {
        my $nav_packet = UAV::Pilot::ARDrone::NavPacket->new({
            packet => $buf,
        });
        $self->_set_last_nav_packet( $nav_packet );
    }
    else {
        $ret = 0;
    }

    return $ret;
}

sub multi_cmds
{
    my ($self, $sub) = @_;
    $self->_is_multi_cmd_mode( 1 );

    eval { $sub->($self) };
    # Wait to check if something went wrong so we can cleanup first

    $self->_is_multi_cmd_mode( 0 );
    my @multi = @{ $self->_multi_cmds };
    $self->_send_cmd( join( '', @multi ) );
    $self->_clear_multi_cmds;

    die $@ if $@;
    return 1;
}


sub _send_cmd
{
    my ($self, $cmd) = @_;
    if( $self->_is_multi_cmd_mode ) {
        $self->_add_multi_cmd( $cmd );
    }
    else {
        $self->_socket->send( $cmd );
    }
    return 1;
}

sub _next_seq
{
    my ($self) = @_;
    my $next_seq = $self->seq + 1;
    $self->__set_seq( $next_seq );
    return $next_seq;
}

sub _init_drone
{
    my ($self) = @_;
    $self->at_ftrim;
    return 1;
}

sub _init_nav_data
{
    my ($self) = @_;
    my $logger = $self->_logger;

    my $nav_sock = $self->do_multicast_navdata
        ? $self->_init_nav_sock_multicast
        : $self->_init_nav_sock_unicast;

    $logger->info( "Nav data connected, setting parameters" );

    # Set UAV to demo nav data mode, which sends most of the data we care about
    $self->at_config(
        $self->ARDRONE_CONFIG_GENERAL_NAVDATA_DEMO,
        $self->TRUE,
    );

    $logger->debug( "Nav data set to demo mode" );

    $logger->debug( "Waiting to receive first nav packet . . . " );
    # Receive first status packet from UAV
    my $buf = '';
    my $in = $nav_sock->recv( $buf, 1024 );
    $logger->debug( "Received first nav packet" );

    $logger->debug( "Setting nav data connection to non-blocking" );
    if(! defined $nav_sock->blocking( 0 ) ) {
        UAV::Pilot::IOException->throw({
            error => "Could not set nav socket to non-blocking IO: $!",
        });
    }
    $logger->debug( "Nav data connection set to non-blocking" );

    $logger->debug( "Parsing first nav packet" );
    $self->_nav_socket( $nav_sock );
    $logger->debug( "First nav packet parsed" );

    $logger->info( "Nav data init finished" );
    return 1;
}

sub _init_nav_sock_multicast
{
    my ($self) = @_;
    my $host = $self->host;
    my $multicast_addr = $self->ARDRONE_MULTICAST_ADDR;
    my $port           = $self->ARDRONE_PORT_NAV_DATA;
    my $socket_type    = $self->ARDRONE_PORT_NAV_DATA_TYPE;
    my $iface          = $self->iface;
    my $logger         = $self->_logger;

    $logger->info( "Init nav data connection; iface [$iface], host [$host], "
        . " multicast address [$multicast_addr], port [$port]" );

    my $nav_sock = IO::Socket::Multicast->new(
        Proto     => $socket_type,
        PeerPort  => $port,
        PeerAddr  => $host,
        LocalAddr => $multicast_addr,
        LocalPort => $port,
        ReuseAddr => 1,
    ) or die "Could not open socket: $!\n";
    $nav_sock->mcast_add( $multicast_addr, $iface )
        or die "Could not subscribe to '$multicast_addr': $!\n";
    $nav_sock->send( $self->NAVDATA_INIT_MULTICAST );

    return $nav_sock;
}

sub _init_nav_sock_unicast
{
    my ($self) = @_;
    my $host = $self->host;
    my $port        = $self->ARDRONE_PORT_NAV_DATA;
    my $socket_type = $self->ARDRONE_PORT_NAV_DATA_TYPE;
    my $logger      = $self->_logger;

    $logger->info( "Init nav data connection; host [$host]"
        . ", unicast, port [$port]" );

    my $nav_sock = IO::Socket::INET->new(
        Proto     => $socket_type,
        PeerPort  => $port,
        PeerAddr  => $host,
        LocalPort => $port,
        ReuseAddr => 1,
    ) or die "Could not open socket: $!\n";
    $nav_sock->send( $self->NAVDATA_INIT_UNICAST );

    return $nav_sock;
}


after '_set_last_nav_packet' => sub {
    my ($self, $nav_packet) = @_;
    $self->_logger->info( "Received nav packet" );
    #$self->_logger->debug( "Raw Output: " . $nav_packet->to_hex_string );
    #$self->_logger->debug( "Parsed Output: " . $nav_packet->to_string );
    $_->got_new_nav_packet( $nav_packet ) for @{ $self->nav_collectors };
    return 1;
};


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::Driver

=head1 SYNOPSIS

    my $sender = UAV::Pilot::ARDrone::Driver->new({
        host => '192.168.1.1',
    });
    $sender->connect;
    
    $sender->at_ref( 1, 0 ); # Takeoff
    $sender->at_pcmd( 1, 1, 1.0, 0, 0, 0 ); # Progressive movement, roll
    $sender->at_ref( 0, 0 ); # Land

=head1 DESCRIPTION

Low-level interface for controlling the Parrot AR.Drone.  If you want to write an external 
program or library controlling this UAV, look at L<UAV::Pilot::Control::ARDrone> instead.

=head1 ATTRIBUTES

=head2 host

=head2 port

=head2 seq

=head2 do_multicast_navdata

If true, navdata will use a multicast IP connection.  Mac OSX seems to be 
tricky to use with multicast.  Default is false.

=head1 METHODS

=head2 connect

Initiate the connection to the UAV.

=head2 at_ref

    at_ref( $takeoff, $emergency );

Controls takeoff/landing, and also the emergency toggle.  If the AR.Drone shows all 
red lights and won't respond to commands, send this with the emergency flag to reset it.  
This can also toggle emergency mode on in case the UAV flys out of control.

=head2 at_pcmd

    at_pcmd( $do_progressive, $do_combined_yaw,
        $roll, $pitch, $vert_speed, $yaw );

Controls the roll/pitch/vertical speed/yaw.  Sending this once will make the AR.Drone 
go briefly in that direction and then return to normal.  For constant motion, the 
AR.Drone developer documents suggest sending the command every 30ms.

The roll/pitch/vert_speed/yaw parameters are numbers between -1.0 and 1.0.  Note that 
they will be treated as single-precision (16 bit) floats, as per the developer docs.

=head2 at_pcmd_mag

    at_pcmd_mag( $do_progressive, $do_combined_yaw,
        $roll, $pitch, $vert_speed, $angular_speed,
        $magneto, $magneto_accuracy );

Same as C<at_pcmd>, but with additional argument for setting the current magneto heading.

For C<$magneto> an angle of 0 means facing north, positive value is facing east, and 
negative is facing west.  1 and -1 are the same orientation.

The C<$magneto_accuracy> sets the maximum deviation of where the magnetic heading differs 
from geomagnetic heading in degrees.  Negative values indicate an invalid heading.

=head2 at_ftrim

Tells the AR.Drone that it's lying horizontally.  It must be called after each startup.  
I<This command MUST NOT be sent when the drone is flying>.

This is automatically called by C<connect()>.

=head2 at_calib

    at_calib( $device )

Calibrates the magnetometer.  This command I<MUST> be sent when the AR.Drone is flying.

The C<$device> parameter should be one of the C<ARDRONE_CALIBRATION_DEVICE_*> constants.

This will cause the AR.Drone to spin around.

=head2 at_config

    at_config( $name, $value );

Set a config option.  See the list of config constants.

=head2 at_config_ids

    at_config_ids( $session_id, $user_id, $app_id );

When using multiconfiguration, send this before every C<at_config()> call.

=head2 at_comwdg

Reset the communication watchdog.

=head2 at_ctrl

A useful but rather under-documented command for initing things like navigation data.

=head2 add_nav_collector

  add_nav_collector( $nav_collector )

Add an object that does the C<UAV::Pilot::NavCollector> role.  It will be 
passed a fresh nav packet each time it comes in.

=head2 multi_cmds

    $driver->multi_cmds( sub {
        $driver->at_config_ids( 1234, 5678, 9012 );
        $driver->at_config( 'foo' => 1 );
        $driver->at_config( 'bar' => 2 );
    });

Sends multiple commands in a single packet.

=head2 float_convert

    float_convert( 2.0 )

Takes a 32-bit, single-precision floating point number.  The binary form is then 
directly converted into an integer.  For example, 0.5 converts into 1056964608.

The protocol requires floating point numbers to be transferred this way in some cases.  
The API will take care of most of these cases for you, but there are some configuration 
settings that you'll have to convert yourself (like LED animations).

=head2 read_nav_packet

Fetch and parse the latest nav packet off the nav socket.  Returns true if there was a new 
nav packet to read, false otherwise.  You can get the last available nav packet by calling 
C<last_nav_packet()>.

This is a non-blocking IO operation.

=head1 CONSTANTS

=head2 Calibration Devices

    ARDRONE_CALIBRATION_DEVICE_MAGNETOMETER
    ARDRONE_CALIBRATION_DEVICE_NUMBER

=head2 Ctrl Commands

    ARDRONE_CTRL_GET_CONFIG

=head2 Networking Ports

    ARDRONE_PORT_COMMAND
    ARDRONE_PORT_COMMAND_TYPE
    ARDRONE_PORT_NAV_DATA
    ARDRONE_PORT_NAV_DATA_TYPE
    ARDRONE_PORT_VIDEO_P264_V1
    ARDRONE_PORT_VIDEO_P264_V2
    ARDRONE_PORT_VIDEO_P264_V1_TYPE
    ARDRONE_PORT_VIDEO_P264_V2_TYPE
    ARDRONE_PORT_VIDEO_H264
    ARDRONE_PORT_VIDEO_H264_TYPE
    ARDRONE_PORT_CTRL
    ARDRONE_PORT_CTRL_TYPE

=head2 Configuration

=head3 General

    ARDRONE_CONFIG_GENERAL_NUM_VERSION_CONFIG
    ARDRONE_CONFIG_GENERAL_NUM_VERSION_MB
    ARDRONE_CONFIG_GENERAL_NUM_VERSION_SOFT
    ARDRONE_CONFIG_GENERAL_DRONE_SERIAL
    ARDRONE_CONFIG_GENERAL_SOFT_BUILD_DATE
    ARDRONE_CONFIG_GENERAL_MOTOR1_SOFT
    ARDRONE_CONFIG_GENERAL_MOTOR1_HARD
    ARDRONE_CONFIG_GENERAL_MOTOR1_SUPPLIER
    ARDRONE_CONFIG_GENERAL_ARDRONE_NAME
    ARDRONE_CONFIG_GENERAL_FLYING_TIME
    ARDRONE_CONFIG_GENERAL_NAVDATA_DEMO
    ARDRONE_CONFIG_GENERAL_NAVDATA_OPTIONS
    ARDRONE_CONFIG_GENERAL_COM_WATCHDOG
    ARDRONE_CONFIG_GENERAL_VIDEO_ENABLE
    ARDRONE_CONFIG_GENERAL_VBAT_MIN

=head3 Control

    ARDRONE_CONFIG_CONTROL_ACCS_OFFSET             => 'control:accs_offset',
    ARDRONE_CONFIG_CONTROL_ACCS_GAINS              => 'control:accs_gains',
    ARDRONE_CONFIG_CONTROL_GYROS_OFFSET            => 'control:gyros_offset',
    ARDRONE_CONFIG_CONTROL_GYROS_GAINS             => 'control:gyros_gains',
    ARDRONE_CONFIG_CONTROL_GYROS110_OFFSET         => 'control:gyros110_offset',
    ARDRONE_CONFIG_CONTROL_GYROS110_GAINS          => 'control:gyros110_gains',
    ARDRONE_CONFIG_CONTROL_MAGNETO_OFFSET          => 'control:magneto_offset',
    ARDRONE_CONFIG_CONTROL_MAGNETO_RADIUS          => 'control:magneto_radius',
    ARDRONE_CONFIG_CONTROL_GYRO_OFFSET_THR_X       => 'control:gyro_offset_thr_x',
    ARDRONE_CONFIG_CONTROL_PWM_REF_GYROS           => 'control:pwm_ref_gyros',
    ARDRONE_CONFIG_CONTROL_OSCTUN_VALUE            => 'control:osctun_value',
    ARDRONE_CONFIG_CONTROL_OSCTUN_TEST             => 'control:osctun_test',
    ARDRONE_CONFIG_CONTROL_CONTROL_LEVEL           => 'control:control_level',
    ARDRONE_CONFIG_CONTROL_EULER_ANGLE_MAX         => 'control:euler_angle_max',
    ARDRONE_CONFIG_CONTROL_ALTITUDE_MAX            => 'control:altitude_max',
    ARDRONE_CONFIG_CONTROL_ALTITUDE_MIN            => 'control:altitude_min',
    ARDRONE_CONFIG_CONTROL_CONTROL_IPHONE_TILT     => 'control:control_iphone_tilt',
    ARDRONE_CONFIG_CONTROL_CONTROL_VZ_MAX          => 'control:control_vz_max',
    ARDRONE_CONFIG_CONTROL_CONTROL_YAW             => 'control:control_yaw',
    ARDRONE_CONFIG_CONTROL_OUTDOOR                 => 'control:outdoor',
    ARDRONE_CONFIG_CONTROL_FLIGHT_WITHOUT_SHELL    => 'control:flight_without_shell',
    ARDRONE_CONFIG_CONTROL_AUTONOMOUS_FLIGHT       => 'control:autonomous_flight',
    ARDRONE_CONFIG_CONTROL_MANUAL_TRIM             => 'control:manual_trim',
    ARDRONE_CONFIG_CONTROL_INDOOR_EULER_ANGLE_MAX  => 'control:indoor_euler_angle_max',
    ARDRONE_CONFIG_CONTROL_INDOOR_CONTROL_VZ_MAX   => 'control:indoor_control_vz_max',
    ARDRONE_CONFIG_CONTROL_INDOOR_CONTROL_YAW      => 'control:indoor_control_yaw',
    ARDRONE_CONFIG_CONTROL_OUTDOOR_EULER_ANGLE_MAX => 'control:outdoor_euler_angle_max',
    ARDRONE_CONFIG_CONTROL_OUTDOOR_CONTROL_VZ_MAX  => 'control:outdoor_control_vz_max',
    ARDRONE_CONFIG_CONTROL_OUTDOOR_CONTROL_YAW     => 'control:outdoor_control_yaw',
    ARDRONE_CONFIG_CONTROL_FLYING_MODE             => 'control:flying_mode',
    ARDRONE_CONFIG_CONTROL_HOVERING_RANGE          => 'control:hovering_range',
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM             => 'control:flight_anim',

=head3 Networking

    ARDRONE_CONFIG_NETWORK_SSID_SINGLE_PLAYER
    ARDRONE_CONFIG_NETWORK_WIFI_MODE
    ARDRONE_CONFIG_NETWORK_WIFI_MODE_AP
    ARDRONE_CONFIG_NETWORK_WIFI_MODE_JOIN
    ARDRONE_CONFIG_NETWORK_WIFI_MODE_STATION
    ARDRONE_CONFIG_NETWORK_OWNER_MAC

=head3 PIC

    ARDRONE_CONFIG_PIC_ULTRASOUND_FREQ
    ARDRONE_CONFIG_PIC_ULTRASOUND_WATCHDOG
    ARDRONE_CONFIG_PIC_PIC_VERSION

=head3 Video

    ARDRONE_CONFIG_VIDEO_CAMIF_FPS
    ARDRONE_CONFIG_VIDEO_CODEC_FPS
    ARDRONE_CONFIG_VIDEO_CAMIF_BUFFERS
    ARDRONE_CONFIG_VIDEO_NUM_TRACKERS
    ARDRONE_CONFIG_VIDEO_CODEC
    ARDRONE_CONFIG_VIDEO_VIDEO_SLICES
    ARDRONE_CONFIG_VIDEO_VIDEO_LIVE_SOCKET
    ARDRONE_CONFIG_VIDEO_VIDEO_STORAGE_SPACE
    ARDRONE_CONFIG_VIDEO_BITRATE
    ARDRONE_CONFIG_VIDEO_MAX_BITRATE
    ARDRONE_CONFIG_VIDEO_BITRATE_CONTROL_MODE
    ARDRONE_CONFIG_VIDEO_BITRATE_STORAGE
    ARDRONE_CONFIG_VIDEO_VIDEO_CHANNEL
    ARDRONE_CONFIG_VIDEO_VIDEO_ON_USB
    ARDRONE_CONFIG_VIDEO_VIDEO_FILE_INDEX

=head3 LEDS

    ARDRONE_CONFIG_LEDS_LEDS_ANIM

=head3 Detect

    ARDRONE_CONFIG_DETECT_ENEMY_COLORS
    ARDRONE_CONFIG_DETECT_GROUNDSTRIPE_COLORS
    ARDRONE_CONFIG_DETECT_ENEMY_WITHOUT_SHELL
    ARDRONE_CONFIG_DETECT_TYPE
    ARDRONE_CONFIG_DETECT_DETECTIONS_SELECT_H
    ARDRONE_CONFIG_DETECT_DETECTIONS_SELECT_V_HSYNC
    ARDRONE_CONFIG_DETECT_DETECTIONS_SELECT_V

=head3 Userbox

    ARDRONE_CONFIG_USERBOX_USERBOX_CMD

=head3 GPS

    ARDRONE_CONFIG_GPS_LATITUDE
    ARDRONE_CONFIG_GPS_LONGITUDE
    ARDRONE_CONFIG_GPS_ALTITUDE

=head3 Custom

    ARDRONE_CONFIG_CUSTOM_APPLICATION_ID
    ARDRONE_CONFIG_CUSTOM_APPLICATION_DESC
    ARDRONE_CONFIG_CUSTOM_PROFILE_ID
    ARDRONE_CONFIG_CUSTOM_PROFILE_DESC
    ARDRONE_CONFIG_CUSTOM_SESSION_ID
    ARDRONE_CONFIG_CUSTOM_SESSION_DESC

=head3 Flight Animation

    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_M30_DEG
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_30_DEG
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_M30_DEG
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_30_DEG
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_200DEG
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_M200DEG
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_GODOWN
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_SHAKE
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_DANCE
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_DANCE
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_DANCE
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_VZ_DANCE
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_WAVE
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_THETA_MIXED
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_DOUBLE_PHI_THETA_MIXED
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_AHEAD
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_BEHIND
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_LEFT
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_RIGHT

    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_M30_DEG_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_30_DEG_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_M30_DEG_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_30_DEG_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_200DEG_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_20DEG_YAW_M200DEG_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_TURNAROUND_GODOWN_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_SHAKE_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_YAW_DANCE_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_DANCE_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_THETA_DANCE_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_VZ_DANCE_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_WAVE_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_PHI_THETA_MIXED_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_DOUBLE_PHI_THETA_MIXED_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_AHEAD_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_BEHIND_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_LEFT_MAYDAY
    ARDRONE_CONFIG_CONTROL_FLIGHT_ANIM_FLIP_RIGHT_MAYDAY

=cut
