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
package UAV::Pilot::ARDrone::NavPacket;
$UAV::Pilot::ARDrone::NavPacket::VERSION = '1.1';
use v5.14;
use Moose;
use namespace::autoclean;

use UAV::Pilot::Exceptions;

use constant { # Values used as Option IDs
    NAVDATA_DEMO           => 0,
    NAVDATA_TIME           => 1,
    NAVDATA_RAW_MEASURES   => 2,
    NAVDATA_PHYS_MEASURES  => 3,
    NAVDATA_GYROS_OFFSETS  => 4,
    NAVDATA_EULER_ANGLES   => 5,
    NAVDATA_REFERNCES      => 6,
    NAVDATA_TRIMS          => 7,
    NAVDATA_RC_REFERENCES  => 8,
    NAVDATA_PWM            => 9,
    NAVDATA_ALTITUDE       => 10,
    NAVDATA_VISION_RAW     => 11,
    NAVDATA_VISION_OF      => 12,
    NAVDATA_VISION         => 13,
    NAVDATA_VISION_PERF    => 14,
    NAVDATA_TRACKERS_SEND  => 15,
    NAVDATA_VISION_DETECT  => 16,
    NAVDATA_WATCHDOG       => 17,
    NAVDATA_ADC_DATA_FRAME => 18,
    NAVDATA_VIDEO_STREAM   => 19,
    NAVDATA_CKS            => 0xffff,
};
use constant { # Bits for the drone state field
    NAVDATA_STATE_FLYING                        => 0,
    NAVDATA_STATE_VIDEO_ENABLED                 => 1,
    NAVDATA_STATE_VISION_ENABLED                => 2,
    NAVDATA_STATE_CONTROL_ALGORITHM             => 3,
    NAVDATA_STATE_ALTITUDE_CONTROL_ACTIVE       => 4,
    NAVDATA_STATE_USER_FEEDBACK_ON              => 5,
    NAVDATA_STATE_CONTROL_RECEIVED              => 6,
    NAVDATA_STATE_TRIM_RECEIVED                 => 7,
    NAVDATA_STATE_TRIM_RUNNING                  => 8,
    NAVDATA_STATE_TRIM_SUCCEEDED                => 9,
    NAVDATA_STATE_NAV_DATA_DEMO_ONLY            => 10,
    NAVDATA_STATE_NAV_DATA_BOOTSTRAP            => 11,
    NAVDATA_STATE_MOTORS_DOWN                   => 12,
    # 13 unknown (reserved for future use?)
    NAVDATA_STATE_GYROMETERS_DOWN               => 14,
    NAVDATA_STATE_BATTERY_TOO_LOW               => 15,
    NAVDATA_STATE_BATTERY_TOO_HIGH              => 16,
    NAVDATA_STATE_TIMER_ELAPSED                 => 17,
    NAVDATA_STATE_NOT_ENOUGH_POWER              => 18,
    NAVDATA_STATE_ANGELS_OUT_OF_RANGE           => 19,
    NAVDATA_STATE_TOO_MUCH_WIND                 => 20,
    NAVDATA_STATE_ULTRASONIC_SENSOR_DEAF        => 21,
    NAVDATA_STATE_CUTOUT_SYSTEM_DETECTED        => 22,
    NAVDATA_STATE_PIC_VERSION_OK                => 23,
    NAVDATA_STATE_AT_CODED_THREAD_ON            => 24,
    NAVDATA_STATE_NAV_DATA_THREAD_ON            => 25,
    NAVDATA_STATE_VIDEO_THREAD_ON               => 26,
    NAVDATA_STATE_ACQUISITION_THREAD_ON         => 27,
    NAVDATA_STATE_CONTROL_WATCHDOG_DELAYED      => 28,
    NAVDATA_STATE_ADC_WATCHDOG_DELAYED          => 29,
    NAVDATA_STATE_COMMUNICATION_PROBLEM_OCURRED => 30,
    NAVDATA_STATE_EMERGENCY                     => 31,
};
use constant EXPECT_HEADER_MAGIC_NUM => 0x55667788;

with 'UAV::Pilot::Logger';

has 'header' => (
    is  => 'ro',
    isa => 'Int',
);
has 'drone_state' => (
    is  => 'ro',
    isa => 'Int',
);
has 'sequence_num' => (
    is  => 'ro',
    isa => 'Int',
);
has 'vision_flag' => (
    is  => 'ro',
    isa => 'Int',
);
has 'state_flying' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_video_enabled' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_vision_enabled' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_control_algorithm' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_altitude_control_active' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_user_feedback_on' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_control_received' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_trim_received' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_trim_running' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_trim_succeeded' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_nav_data_demo_only' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_nav_data_bootstrap' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_motors_down' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_gyrometers_down' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_battery_too_low' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_battery_too_high' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_timer_elapsed' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_not_enough_power' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_angles_out_of_range' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_too_much_wind' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_ultrasonic_sensor_deaf' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_cutout_system_detected' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_pic_version_ok' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_at_codec_thread_on' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_nav_data_thread_on' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_video_thread_on' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_acquisition_thread_on' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_control_watchdog_delayed' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_adc_watchdog_delayed' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_communication_problem_occured' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'state_emergency' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'checksum' => (
    is  => 'ro',
    isa => 'Int',
);
has 'control_state' => (
    is  => 'ro',
    isa => 'Maybe[Int]',
);
has 'battery_voltage_percentage' => (
    is  => 'ro',
    isa => 'Maybe[Int]',
);
has 'pitch' => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);
has 'roll' => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);
has 'yaw' => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);
has 'altitude' => (
    is  => 'ro',
    isa => 'Maybe[Int]',
);
has 'velocity_x' => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);
has 'velocity_y' => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);
has 'velocity_z' => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);
has 'video_frame_index' => (
    is  => 'ro',
    isa => 'Maybe[Int]',
);
has 'camera_detection_type' => (
    is  => 'ro',
    isa => 'Int',
);
has 'packet_bytes' => (
    is  => 'ro',
    isa => 'ArrayRef[Int]',
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $packet = $args->{packet};

    my @packet_bytes = unpack "C*", $packet;
    my $header      = $class->_convert_endian_32bit( @packet_bytes[0..3]  );
    my $state       = $class->_convert_endian_32bit( @packet_bytes[4..7]  );
    my $seq         = $class->_convert_endian_32bit( @packet_bytes[8..11]  );
    my $vision_flag = $class->_convert_endian_32bit( @packet_bytes[12..15] );
    UAV::Pilot::NavPacketException::BadHeader->throw(
        error      => "Header '$header' did not match " . $class->EXPECT_HEADER_MAGIC_NUM,
        got_header => $header,
    ) if $class->EXPECT_HEADER_MAGIC_NUM != $header;

    my @option_bytes = @packet_bytes[16..$#packet_bytes];

    my %new_args = (
        header       => $header,
        drone_state  => $state,
        sequence_num => $seq,
        vision_flag  => $vision_flag,
        packet_bytes => \@packet_bytes,
        %{ $class->_parse_state( $state ) },
        %{ $class->_parse_options( @option_bytes ) },
    );
    return \%new_args;
}


sub to_string
{
    my ($self) = @_;
    my @strs = ();

    push @strs => "Battery: "  . $self->battery_voltage_percentage . '%';
    push @strs => "Pitch: "    . $self->pitch;
    push @strs => "Roll: "     . $self->roll;
    push @strs => "Yaw: "      . $self->yaw;
    push @strs => "Altitude: " . $self->altitude;

    return join ', ', @strs;
}

sub to_hex_string
{
    my ($self) = @_;
    my @packet_bytes = @{ $self->packet_bytes };
    return sprintf( ('%02x' x @packet_bytes), @packet_bytes );
}


sub _parse_state
{
    my ($class, $state) = @_;
    return {
        state_flying                        => ($state & 1),
        state_video_enabled                 => (($state >> 1) & 1),
        state_vision_enabled                => (($state >> 2) & 1),
        state_control_algorithm             => (($state >> 3) & 1),
        state_altitude_control_active       => (($state >> 4) & 1),
        state_user_feedback_on              => (($state >> 5) & 1),
        state_control_received              => (($state >> 6) & 1),
        state_trim_received                 => (($state >> 7) & 1),
        state_trim_running                  => (($state >> 8) & 1),
        state_trim_succeeded                => (($state >> 9) & 1),
        state_nav_data_demo_only            => (($state >> 10) & 1),
        state_nav_data_bootstrap            => (($state >> 11) & 1),
        state_motors_down                   => (($state >> 12) & 1),
        state_gyrometers_down               => (($state >> 13) & 1),
        state_battery_too_low               => (($state >> 14) & 1),
        state_battery_too_high              => (($state >> 15) & 1),
        state_timer_elapsed                 => (($state >> 16) & 1),
        state_not_enough_power              => (($state >> 17) & 1),
        # 18 unknown (reserved for future use?)
        state_angles_out_of_range           => (($state >> 19) & 1),
        state_too_much_wind                 => (($state >> 20) & 1),
        state_ultrasonic_sensor_deaf        => (($state >> 21) & 1),
        state_cutout_system_detected        => (($state >> 22) & 1),
        state_pic_version_ok                => (($state >> 23) & 1),
        state_at_codec_thread_on            => (($state >> 24) & 1),
        state_nav_data_thread_on            => (($state >> 25) & 1),
        state_video_thread_on               => (($state >> 26) & 1),
        state_acquisition_thread_on         => (($state >> 27) & 1),
        state_control_watchdog_delayed      => (($state >> 28) & 1),
        state_adc_watchdog_delayed          => (($state >> 29) & 1),
        state_communication_problem_occured => (($state >> 30) & 1),
        state_emergency                     => (($state >> 31) & 1),
    };
}

sub _parse_options
{
    my ($class, @bytes) = @_;
    my %args;

    while( @bytes ) {
        my $id = $class->_convert_endian_16bit( shift(@bytes), shift(@bytes) );
        my $size = $class->_convert_endian_16bit( shift(@bytes), shift(@bytes) );

        my @data = splice @bytes, 0, $size;

        %args = (
            %args,
            %{ $class->_parse_option( $id, @data ) },
        );
    }

    return \%args;
}

sub _parse_option
{
    my ($self, $id, @bytes) = @_;
    my $ret = 
        $self->NAVDATA_CKS  == $id ? $self->_parse_option_checksum( @bytes ) :
        $self->NAVDATA_DEMO == $id ? $self->_parse_option_demo( @bytes )     :
        {};
    return $ret;
}

sub _parse_option_checksum
{
    my ($self, @data) = @_;
    @data = reverse @data;

    my $data = 0;
    foreach (@data) {
        $data <<= 8;
        $data |= $_;
    }

    return { checksum => $data };
}

sub _parse_option_demo
{
    my ($self, @data) = @_;
    return {} unless scalar(@data) >= 64;
    my %args;

    $args{control_state}              = $self->_convert_endian_32bit( @data[0..3]   );
    $args{battery_voltage_percentage} = $self->_convert_endian_32bit( @data[4..7]   );
    $args{pitch}                      = $self->_to_float_32bit_endian( @data[8..11]  );
    $args{roll}                       = $self->_to_float_32bit_endian( @data[12..15] );
    $args{yaw}                        = $self->_to_float_32bit_endian( @data[16..19] );
    $args{altitude}                   = $self->_convert_endian_32bit( @data[20..23] );
    $args{velocity_x}                 = $self->_convert_endian_32bit( @data[24..27] );
    $args{velocity_y}                 = $self->_convert_endian_32bit( @data[28..31] );
    $args{velocity_z}                 = $self->_convert_endian_32bit( @data[32..35] );
    $args{video_frame_index}          = $self->_convert_endian_32bit( @data[36..39] );
    # Bytes 40 - 47 are for deprecated parameters
    $args{camera_detection_type}      = $self->_convert_endian_32bit( @data[48..51] );
    # Bytes 52 - 63 are for deprecated parameters

    # Check for NaN on floats, converting to zero and issuing a warning
    foreach my $field (qw{ pitch roll yaw velocity_x velocity_y velocity_z }) {
        if( $args{$field} =~ /\A -? nan \z/ix ) {
            $self->_logger->warn( "Field '$field' was set to NaN"
                . ', converting to zero' );
            $args{$field} = 0;
        }
    }

    return \%args;
}

sub _convert_endian_32bit
{
    my ($class, @bytes) = @_;
    my $val = $bytes[0]
        | ($bytes[1] << 8)
        | ($bytes[2] << 16)
        | ($bytes[3] << 24);
    return $val;
}

sub _convert_endian_16bit
{
    my ($class, @bytes) = @_;
    my $val = $bytes[0] | ($bytes[1] << 8);
    return $val;
}

sub _to_float_32bit
{
    my ($self, @bytes) = @_;
    my $val = $bytes[3]
        | ($bytes[2] << 8)
        | ($bytes[1] << 16)
        | ($bytes[0] << 24);
    my $float = unpack( "f", pack( "l", $val ) );
    return $float;
}

sub _to_float_32bit_endian
{
    my ($self, @bytes) = @_;
    my $val = $bytes[0]
        | ($bytes[1] << 8)
        | ($bytes[2] << 16)
        | ($bytes[3] << 24);
    my $float = unpack( "f", pack( "l", $val ) );
    return $float;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::NavPacket

=head1 SYNOPSIS

  my $nav = UAV::Pilot::ARDrone::NavPacket->new({
      packet => '...',
  });
  say "Roll: " . $nav->roll;
  say "Pitch: " . $nav->pitch;
  say "Yaw: " . $nav->yaw;

=head1 DESCRIPTION

Parses nav packets from the Parrot AR.Drone.  Specifically handles packets with the 
option for demo data, which provides basic roll/pitch/yaw/altitude, among a few other 
things.

Other nav packet types will be parsed in the future.

=cut
