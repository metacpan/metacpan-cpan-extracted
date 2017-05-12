package Video::Xine::Stream;
{
  $Video::Xine::Stream::VERSION = '0.26';
}

use strict;
use warnings;

use Video::Xine;
use DateTime;
use Carp;

use base 'Exporter';

our @EXPORT_OK = qw/
  XINE_STATUS_IDLE
  XINE_STATUS_STOP
  XINE_STATUS_PLAY
  XINE_STATUS_QUIT

  XINE_PARAM_SPEED
  XINE_PARAM_AV_OFFSET
  XINE_PARAM_AUDIO_CHANNEL_LOGICAL
  XINE_PARAM_SPU_CHANNEL
  XINE_PARAM_VIDEO_CHANNEL
  XINE_PARAM_AUDIO_VOLUME
  XINE_PARAM_AUDIO_MUTE
  XINE_PARAM_AUDIO_COMPR_LEVEL
  XINE_PARAM_AUDIO_AMP_LEVEL
  XINE_PARAM_AUDIO_REPORT_LEVEL
  XINE_PARAM_VERBOSITY
  XINE_PARAM_SPU_OFFSET
  XINE_PARAM_IGNORE_VIDEO
  XINE_PARAM_IGNORE_AUDIO
  XINE_PARAM_IGNORE_SPU
  XINE_PARAM_BROADCASTER_PORT
  XINE_PARAM_METRONOM_PREBUFFER
  XINE_PARAM_EQ_30HZ
  XINE_PARAM_EQ_60HZ
  XINE_PARAM_EQ_125HZ
  XINE_PARAM_EQ_250HZ
  XINE_PARAM_EQ_500HZ
  XINE_PARAM_EQ_1000HZ
  XINE_PARAM_EQ_2000HZ
  XINE_PARAM_EQ_4000HZ
  XINE_PARAM_EQ_8000HZ
  XINE_PARAM_EQ_16000HZ
  XINE_PARAM_AUDIO_CLOSE_DEVICE
  XINE_PARAM_AUDIO_AMP_MUTE
  XINE_PARAM_FINE_SPEED

  XINE_SPEED_PAUSE
  XINE_SPEED_SLOW_4
  XINE_SPEED_SLOW_2
  XINE_SPEED_NORMAL
  XINE_SPEED_FAST_2
  XINE_SPEED_FAST_4

  XINE_STREAM_INFO_BITRATE
  XINE_STREAM_INFO_SEEKABLE
  XINE_STREAM_INFO_VIDEO_WIDTH
  XINE_STREAM_INFO_VIDEO_HEIGHT
  XINE_STREAM_INFO_VIDEO_RATIO
  XINE_STREAM_INFO_VIDEO_CHANNELS
  XINE_STREAM_INFO_VIDEO_STREAMS
  XINE_STREAM_INFO_VIDEO_BITRATE
  XINE_STREAM_INFO_VIDEO_FOURCC
  XINE_STREAM_INFO_VIDEO_HANDLED
  XINE_STREAM_INFO_FRAME_DURATION
  XINE_STREAM_INFO_AUDIO_CHANNELS
  XINE_STREAM_INFO_AUDIO_BITS
  XINE_STREAM_INFO_AUDIO_SAMPLERATE
  XINE_STREAM_INFO_AUDIO_BITRATE
  XINE_STREAM_INFO_AUDIO_FOURCC
  XINE_STREAM_INFO_AUDIO_HANDLED
  XINE_STREAM_INFO_HAS_CHAPTERS
  XINE_STREAM_INFO_HAS_VIDEO
  XINE_STREAM_INFO_HAS_AUDIO
  XINE_STREAM_INFO_IGNORE_VIDEO
  XINE_STREAM_INFO_IGNORE_AUDIO
  XINE_STREAM_INFO_IGNORE_SPU
  XINE_STREAM_INFO_VIDEO_HAS_STILL
  XINE_STREAM_INFO_MAX_AUDIO_CHANNEL
  XINE_STREAM_INFO_MAX_SPU_CHANNEL
  XINE_STREAM_INFO_AUDIO_MODE
  XINE_STREAM_INFO_SKIPPED_FRAMES
  XINE_STREAM_INFO_DISCARDED_FRAMES
  XINE_STREAM_INFO_VIDEO_AFD
  XINE_STREAM_INFO_DVD_TITLE_NUMBER
  XINE_STREAM_INFO_DVD_TITLE_COUNT
  XINE_STREAM_INFO_DVD_CHAPTER_NUMBER
  XINE_STREAM_INFO_DVD_CHAPTER_COUNT
  XINE_STREAM_INFO_DVD_ANGLE_NUMBER
  XINE_STREAM_INFO_DVD_ANGLE_COUNT

  XINE_META_INFO_TITLE
  XINE_META_INFO_COMMENT
  XINE_META_INFO_ARTIST
  XINE_META_INFO_GENRE
  XINE_META_INFO_ALBUM
  XINE_META_INFO_YEAR
  XINE_META_INFO_VIDEOCODEC
  XINE_META_INFO_AUDIOCODEC
  XINE_META_INFO_SYSTEMLAYER
  XINE_META_INFO_INPUT_PLUGIN
  XINE_META_INFO_CDINDEX_DISCID
  XINE_META_INFO_TRACK_NUMBER

  XINE_MASTER_SLAVE_PLAY
  XINE_MASTER_SLAVE_STOP
  XINE_MASTER_SLAVE_SPEED
/;

# xine_get_stream_info
use constant {
    XINE_STREAM_INFO_BITRATE            => 0,
    XINE_STREAM_INFO_SEEKABLE           => 1,
    XINE_STREAM_INFO_VIDEO_WIDTH        => 2,
    XINE_STREAM_INFO_VIDEO_HEIGHT       => 3,
    XINE_STREAM_INFO_VIDEO_RATIO        => 4,
    XINE_STREAM_INFO_VIDEO_CHANNELS     => 5,
    XINE_STREAM_INFO_VIDEO_STREAMS      => 6,
    XINE_STREAM_INFO_VIDEO_BITRATE      => 7,
    XINE_STREAM_INFO_VIDEO_FOURCC       => 8,
    XINE_STREAM_INFO_VIDEO_HANDLED      => 9,
    XINE_STREAM_INFO_FRAME_DURATION     => 10,
    XINE_STREAM_INFO_AUDIO_CHANNELS     => 11,
    XINE_STREAM_INFO_AUDIO_BITS         => 12,
    XINE_STREAM_INFO_AUDIO_SAMPLERATE   => 13,
    XINE_STREAM_INFO_AUDIO_BITRATE      => 14,
    XINE_STREAM_INFO_AUDIO_FOURCC       => 15,
    XINE_STREAM_INFO_AUDIO_HANDLED      => 16,
    XINE_STREAM_INFO_HAS_CHAPTERS       => 17,
    XINE_STREAM_INFO_HAS_VIDEO          => 18,
    XINE_STREAM_INFO_HAS_AUDIO          => 19,
    XINE_STREAM_INFO_IGNORE_VIDEO       => 20,
    XINE_STREAM_INFO_IGNORE_AUDIO       => 21,
    XINE_STREAM_INFO_IGNORE_SPU         => 22,
    XINE_STREAM_INFO_VIDEO_HAS_STILL    => 23,
    XINE_STREAM_INFO_MAX_AUDIO_CHANNEL  => 24,
    XINE_STREAM_INFO_MAX_SPU_CHANNEL    => 25,
    XINE_STREAM_INFO_AUDIO_MODE         => 26,
    XINE_STREAM_INFO_SKIPPED_FRAMES     => 27,
    XINE_STREAM_INFO_DISCARDED_FRAMES   => 28,
    XINE_STREAM_INFO_VIDEO_AFD          => 29,
    XINE_STREAM_INFO_DVD_TITLE_NUMBER   => 30,
    XINE_STREAM_INFO_DVD_TITLE_COUNT    => 31,
    XINE_STREAM_INFO_DVD_CHAPTER_NUMBER => 32,
    XINE_STREAM_INFO_DVD_CHAPTER_COUNT  => 33,
    XINE_STREAM_INFO_DVD_ANGLE_NUMBER   => 34,
    XINE_STREAM_INFO_DVD_ANGLE_COUNT    => 35
};

# xine_get_meta_info
use constant {
   XINE_META_INFO_TITLE => 0,
   XINE_META_INFO_COMMENT => 1,
   XINE_META_INFO_ARTIST => 2,
   XINE_META_INFO_GENRE => 3,
   XINE_META_INFO_ALBUM => 4,
   XINE_META_INFO_YEAR => 5,
   XINE_META_INFO_VIDEOCODEC => 6,
   XINE_META_INFO_AUDIOCODEC => 7,
   XINE_META_INFO_SYSTEMLAYER => 8,
   XINE_META_INFO_INPUT_PLUGIN => 9,
   XINE_META_INFO_CDINDEX_DISCID => 10,
   XINE_META_INFO_TRACK_NUMBER => 11
};

our %EXPORT_TAGS = (
    status_constants => [
        qw/
          XINE_STATUS_IDLE
          XINE_STATUS_STOP
          XINE_STATUS_PLAY
          XINE_STATUS_QUIT
          /
    ],
    param_constants => [
        qw/
          XINE_PARAM_SPEED
          XINE_PARAM_AV_OFFSET
          XINE_PARAM_AUDIO_CHANNEL_LOGICAL
          XINE_PARAM_SPU_CHANNEL
          XINE_PARAM_VIDEO_CHANNEL
          XINE_PARAM_AUDIO_VOLUME
          XINE_PARAM_AUDIO_MUTE
          XINE_PARAM_AUDIO_COMPR_LEVEL
          XINE_PARAM_AUDIO_AMP_LEVEL
          XINE_PARAM_AUDIO_REPORT_LEVEL
          XINE_PARAM_VERBOSITY
          XINE_PARAM_SPU_OFFSET
          XINE_PARAM_IGNORE_VIDEO
          XINE_PARAM_IGNORE_AUDIO
          XINE_PARAM_IGNORE_SPU
          XINE_PARAM_BROADCASTER_PORT
          XINE_PARAM_METRONOM_PREBUFFER
          XINE_PARAM_EQ_30HZ
          XINE_PARAM_EQ_60HZ
          XINE_PARAM_EQ_125HZ
          XINE_PARAM_EQ_250HZ
          XINE_PARAM_EQ_500HZ
          XINE_PARAM_EQ_1000HZ
          XINE_PARAM_EQ_2000HZ
          XINE_PARAM_EQ_4000HZ
          XINE_PARAM_EQ_8000HZ
          XINE_PARAM_EQ_16000HZ
          XINE_PARAM_AUDIO_CLOSE_DEVICE
          XINE_PARAM_AUDIO_AMP_MUTE
          XINE_PARAM_FINE_SPEED
          /
    ],
    meta_constants => [
      qw/
          XINE_META_INFO_TITLE
          XINE_META_INFO_COMMENT
          XINE_META_INFO_ARTIST
          XINE_META_INFO_GENRE
          XINE_META_INFO_ALBUM
          XINE_META_INFO_YEAR
          XINE_META_INFO_VIDEOCODEC
          XINE_META_INFO_AUDIOCODEC
          XINE_META_INFO_SYSTEMLAYER
          XINE_META_INFO_INPUT_PLUGIN
          XINE_META_INFO_CDINDEX_DISCID
          XINE_META_INFO_TRACK_NUMBER
      /
    ],
    info_constants => [
        qw/
          XINE_STREAM_INFO_BITRATE
          XINE_STREAM_INFO_SEEKABLE
          XINE_STREAM_INFO_VIDEO_WIDTH
          XINE_STREAM_INFO_VIDEO_HEIGHT
          XINE_STREAM_INFO_VIDEO_RATIO
          XINE_STREAM_INFO_VIDEO_CHANNELS
          XINE_STREAM_INFO_VIDEO_STREAMS
          XINE_STREAM_INFO_VIDEO_BITRATE
          XINE_STREAM_INFO_VIDEO_FOURCC
          XINE_STREAM_INFO_VIDEO_HANDLED
          XINE_STREAM_INFO_FRAME_DURATION
          XINE_STREAM_INFO_AUDIO_CHANNELS
          XINE_STREAM_INFO_AUDIO_BITS
          XINE_STREAM_INFO_AUDIO_SAMPLERATE
          XINE_STREAM_INFO_AUDIO_BITRATE
          XINE_STREAM_INFO_AUDIO_FOURCC
          XINE_STREAM_INFO_AUDIO_HANDLED
          XINE_STREAM_INFO_HAS_CHAPTERS
          XINE_STREAM_INFO_HAS_VIDEO
          XINE_STREAM_INFO_HAS_AUDIO
          XINE_STREAM_INFO_IGNORE_VIDEO
          XINE_STREAM_INFO_IGNORE_AUDIO
          XINE_STREAM_INFO_IGNORE_SPU
          XINE_STREAM_INFO_VIDEO_HAS_STILL
          XINE_STREAM_INFO_MAX_AUDIO_CHANNEL
          XINE_STREAM_INFO_MAX_SPU_CHANNEL
          XINE_STREAM_INFO_AUDIO_MODE
          XINE_STREAM_INFO_SKIPPED_FRAMES
          XINE_STREAM_INFO_DISCARDED_FRAMES
          XINE_STREAM_INFO_VIDEO_AFD
          XINE_STREAM_INFO_DVD_TITLE_NUMBER
          XINE_STREAM_INFO_DVD_TITLE_COUNT
          XINE_STREAM_INFO_DVD_CHAPTER_NUMBER
          XINE_STREAM_INFO_DVD_CHAPTER_COUNT
          XINE_STREAM_INFO_DVD_ANGLE_NUMBER
          XINE_STREAM_INFO_DVD_ANGLE_COUNT
          /
    ],
    speed_constants => [
        qw/
          XINE_SPEED_PAUSE
          XINE_SPEED_SLOW_4
          XINE_SPEED_SLOW_2
          XINE_SPEED_NORMAL
          XINE_SPEED_FAST_2
          XINE_SPEED_FAST_4
          /
    ],
    master_slave_constants => [
    	qw/
		  XINE_MASTER_SLAVE_PLAY
		  XINE_MASTER_SLAVE_STOP
		  XINE_MASTER_SLAVE_SPEED
    	/
    ]
);

use constant {
    XINE_STATUS_IDLE => 0,
    XINE_STATUS_STOP => 1,
    XINE_STATUS_PLAY => 2,
    XINE_STATUS_QUIT => 3,
};

use constant {
    XINE_PARAM_SPEED                 => 1,
    XINE_PARAM_AV_OFFSET             => 2,
    XINE_PARAM_AUDIO_CHANNEL_LOGICAL => 3,
    XINE_PARAM_SPU_CHANNEL           => 4,
    XINE_PARAM_VIDEO_CHANNEL         => 5,
    XINE_PARAM_AUDIO_VOLUME          => 6,
    XINE_PARAM_AUDIO_MUTE            => 7,
    XINE_PARAM_AUDIO_COMPR_LEVEL     => 8,
    XINE_PARAM_AUDIO_AMP_LEVEL       => 9,
    XINE_PARAM_AUDIO_REPORT_LEVEL    => 10,
    XINE_PARAM_VERBOSITY             => 11,
    XINE_PARAM_SPU_OFFSET            => 12,
    XINE_PARAM_IGNORE_VIDEO          => 13,
    XINE_PARAM_IGNORE_AUDIO          => 14,
    XINE_PARAM_IGNORE_SPU            => 15,
    XINE_PARAM_BROADCASTER_PORT      => 16,
    XINE_PARAM_METRONOM_PREBUFFER    => 17,
    XINE_PARAM_EQ_30HZ               => 18,
    XINE_PARAM_EQ_60HZ               => 19,
    XINE_PARAM_EQ_125HZ              => 20,
    XINE_PARAM_EQ_250HZ              => 21,
    XINE_PARAM_EQ_500HZ              => 22,
    XINE_PARAM_EQ_1000HZ             => 23,
    XINE_PARAM_EQ_2000HZ             => 24,
    XINE_PARAM_EQ_4000HZ             => 25,
    XINE_PARAM_EQ_8000HZ             => 26,
    XINE_PARAM_EQ_16000HZ            => 27,
    XINE_PARAM_AUDIO_CLOSE_DEVICE    => 28,
    XINE_PARAM_AUDIO_AMP_MUTE        => 29,
    XINE_PARAM_FINE_SPEED            => 30
};

use constant {
    XINE_SPEED_PAUSE  => 0,
    XINE_SPEED_SLOW_4 => 1,
    XINE_SPEED_SLOW_2 => 2,
    XINE_SPEED_NORMAL => 4,
    XINE_SPEED_FAST_2 => 8,
    XINE_SPEED_FAST_4 => 16,
};

use constant {
	XINE_MASTER_SLAVE_PLAY  => (1<<0),
	XINE_MASTER_SLAVE_STOP  => (1<<1),
	XINE_MASTER_SLAVE_SPEED => (1<<2)
};

sub new {
    my $type = shift;
    my ( $xine, $audio_port, $video_port ) = @_;
    
    my $xine_ptr;
    
    if ( ref $xine eq 'Video::Xine' ) {
    	$xine_ptr = $xine->{'xine'};
    }
    else {
    	$xine_ptr = $xine;
    }

    my $self = {};
    $self->{'xine'}       = $xine_ptr;
    $self->{'audio_port'} = $audio_port or croak "Audio port required";
    $self->{'video_port'} = $video_port or croak "Video port required";

	my $stream =
      xine_stream_new( $xine, $audio_port->{'driver'},
        $video_port->{'driver'} );
    
    if (! defined $stream) {
    	croak "Xine stream error: " . xine_get_error($xine);
    }
    
    $self->{'stream'} = $stream;

    bless $self, $type;

    return $self;

}

sub master_slave {
	my $self = shift;
	my ( $slave, $affinity ) = @_;
	
	return xine_stream_master_slave($self->{'stream'}, $slave, $affinity);
}

sub get_video_port {
    $_[0]->{'video_port'};
}

sub get_audio_port {
    my $self = shift;
    return $self->{'audio_port'};
}

sub open {
    my $self = shift;
    my ($mrl) = @_;

    xine_open( $self->{'stream'}, $mrl )
      or return;

}

sub play {
    my $self = shift;
    my ( $start_pos, $start_time ) = @_;

    xine_play( $self->{'stream'}, $start_pos, $start_time )
      or return;
}

##
## Stops the stream.
##
sub stop {
    my $self = shift;

    xine_stop( $self->{'stream'} );
}

##
## Close the stream. Stream is available for reuse.
##
sub close {
    my $self = shift;

    xine_close( $self->{'stream'} );
}

##
## Eject, if possible
##
sub eject {
	my $self = shift;
	
	return xine_eject( $self->{'stream'} );
}

sub get_pos_length {
    my $self = shift;
    my ( $pos_stream, $pos_time, $length_time ) = ( 0, 0, 0 );

    xine_get_pos_length( $self->{'stream'}, $pos_stream, $pos_time,
        $length_time )
      or return;

    return ( $pos_stream, $pos_time, $length_time );
}

sub get_duration {
    my $self = shift;

    my (undef, undef, $msec_dur) = $self->get_pos_length();

    my $secs = int($msec_dur / 1000);

    my $millis = $msec_dur % 1000;

    return DateTime::Duration->new( seconds => $secs, nanoseconds => ($millis * 1000) );
}

sub get_status {
    my $self = shift;
    return xine_get_status( $self->{'stream'} );
}

sub get_error {
    my $self = shift;
    return xine_get_error( $self->{'stream'} );
}

sub set_param {
    my $self = shift;
    my ( $param, $value ) = @_;
    return xine_set_param( $self->{'stream'}, $param, $value );
}

sub get_param {
    my $self = shift;
    my ($param) = @_;
    return xine_get_param( $self->{'stream'}, $param );
}

sub get_info {
    my $self = shift;
    my ($info) = @_;

    return xine_get_stream_info( $self->{'stream'}, $info );
}

sub get_meta_info {
    my $self = shift;
    my ($info) = @_;

    return xine_get_meta_info( $self->{'stream'}, $info);

}

sub osd_new {
    my $self = shift;
    my (%in) = @_;

    return Video::Xine::OSD->new( $self, %in );
}

sub DESTROY {
    my $self = shift;
    xine_dispose( $self->{'stream'} );
}

1;

__END__

=head1 NAME

Video::Xine::Stream - Audio-video stream for Xine

=head1 SYNOPSIS

  use Video::Xine;
  use Video::Xine::Stream;

  my $stream = Video::Xine::Stream->new($xine, $audio, $video);

  $stream->open('file://foo/bar');

=head1 METHODS

These are methods which can be used on the Video::Xine::Stream class
and object.

=head3 new()

  new($xine, $audio_port, $video_port)

Creates a new Stream object. The C<$audio_port> and C<$video_port> options
are optional and default to automatically-selected drivers.

=head3 get_video_port()

 Returns the video port, also known as the video driver.

=head3 master_slave()

  $stream->master_slave( $slave_stream, $affection )

Sets up a master-slave relationship with $slave_stream. You can import the constants
for C<$affection> with the ':master_slave_constants' tag. They are XINE_MASTER_SLAVE_PLAY,
XINE_MASTER_SLAVE_STOP, and XINE_MASTER_SLAVE_SPEED.

=head3 open()

 $stream->open($mrl)

Opens the stream to an MRL, which is a URL-like construction used by
Xine to locate media files. See the xine documentation for details.

=head3 play()

 $stream->play($start_pos, $start_time)

Starts playing the stream at a specific position or specific time. Both C<$start_pos> and C<$start_time> are optional and default to 0.

=head3 stop()

 $stream->stop()

Stops the stream.

=head3 close()

 $stream->close()

Close the stream. You can re-use the same stream again and again.

=head3 eject()

  $stream->eject()
  
Eject the stream, if possible. Returns 1 if OK, 0 if error.

=head3 get_pos_length()

  ($pos_pct, $pos_time, $length_millis) = $stream->get_pos_length();

Gets position / length information. C<$pos_pct> is a value between 1
and 65535 indicating how far we've proceeded through the
stream. C<$pos_time> gives how far we've proceeded through the stream
in milliseconds, and C<$length_millis> gives the total length of the
stream in milliseconds.

=head3 get_status()

Returns the play status of the stream. It will return one of the
following constants, which are exported in the tag
':status_constants':

=head4 STREAM CONSTANTS

=over 4

=item *

XINE_STATUS_IDLE

The stream is idle.

=item *

XINE_STATUS_STOP

Indicates that the stream is stopped.

=item *

XINE_STATUS_PLAY

Indicates that the stream is playing.

=item *

XINE_STATUS_QUIT

=back


=head3 set_param()

  $s->set_param($param, $value)

Sets a parameter on the stream. C<$param> should be a xine parameter
constant. See L<"PARAMETER CONSTANTS"> for a list of available
parameter constants.

=head3 get_param()

  my $param = $s->get_param($param)

Returns a parameter from the stream. C<$param> should be a xine
parameter constant.

=head3 get_info()

  my $info = $s->get_info($info_const)

Returns information about the stream, such as its bit rate, audio
channels, width, or height. C<$info_const> should be a xine info constant.

=head3 get_meta_info()

  my $meta_info = $stream->get_meta_info($meta_info_const)

Returns meta-information about the stream, such as its title.
C<$meta_info_const> should be a xine meta info constant; see META CONSTANTS below for details.

=head2 PARAM CONSTANTS

These constants are exported with the C<:param_constants> tag.

=over

=item *

XINE_PARAM_SPEED

=item *

XINE_PARAM_AV_OFFSET

=item *

XINE_PARAM_AUDIO_CHANNEL_LOGICAL

=item *

XINE_PARAM_SPU_CHANNEL

=item *

XINE_PARAM_VIDEO_CHANNEL

=item *

XINE_PARAM_AUDIO_VOLUME

=item *

XINE_PARAM_AUDIO_MUTE

=item *

XINE_PARAM_AUDIO_COMPR_LEVEL

=item *

XINE_PARAM_AUDIO_AMP_LEVEL

=item *

XINE_PARAM_AUDIO_REPORT_LEVEL

=item *

XINE_PARAM_VERBOSITY

=item *

XINE_PARAM_SPU_OFFSET

=item *

XINE_PARAM_IGNORE_VIDEO

=item *

XINE_PARAM_IGNORE_AUDIO

=item *

XINE_PARAM_IGNORE_SPU

=item *

XINE_PARAM_BROADCASTER_PORT

=item *

XINE_PARAM_METRONOM_PREBUFFER

=item *

XINE_PARAM_EQ_30HZ

=item *

XINE_PARAM_EQ_60HZ

=item *

XINE_PARAM_EQ_125HZ

=item *

XINE_PARAM_EQ_250HZ

=item *

XINE_PARAM_EQ_500HZ

=item *

XINE_PARAM_EQ_1000HZ

=item *

XINE_PARAM_EQ_2000HZ

=item *

XINE_PARAM_EQ_4000HZ

=item *

XINE_PARAM_EQ_8000HZ

=item *

XINE_PARAM_EQ_16000HZ

=item *

XINE_PARAM_AUDIO_CLOSE_DEVICE

=item *

XINE_PARAM_AUDIO_AMP_MUTE

=item *

XINE_PARAM_FINE_SPEED

=back

=head2 INFO CONSTANTS

Exported in the tag 'info_constants'.

=over

=item *

XINE_STREAM_INFO_BITRATE

=item *

XINE_STREAM_INFO_SEEKABLE

=item *

XINE_STREAM_INFO_VIDEO_WIDTH

=item *

XINE_STREAM_INFO_VIDEO_HEIGHT

=item *

XINE_STREAM_INFO_VIDEO_RATIO

=item *

XINE_STREAM_INFO_VIDEO_CHANNELS

=item *

XINE_STREAM_INFO_VIDEO_STREAMS

=item *

XINE_STREAM_INFO_VIDEO_BITRATE

=item *

XINE_STREAM_INFO_VIDEO_FOURCC

=item *

XINE_STREAM_INFO_VIDEO_HANDLED

=item *

XINE_STREAM_INFO_FRAME_DURATION

=item *

XINE_STREAM_INFO_AUDIO_CHANNELS

=item *

XINE_STREAM_INFO_AUDIO_BITS

=item *

XINE_STREAM_INFO_AUDIO_SAMPLERATE

=item *

XINE_STREAM_INFO_AUDIO_BITRATE

=item *

XINE_STREAM_INFO_AUDIO_FOURCC

=item *

XINE_STREAM_INFO_AUDIO_HANDLED

=item *

XINE_STREAM_INFO_HAS_CHAPTERS

=item *

XINE_STREAM_INFO_HAS_VIDEO

=item *

XINE_STREAM_INFO_HAS_AUDIO

=item *

XINE_STREAM_INFO_IGNORE_VIDEO

=item *

XINE_STREAM_INFO_IGNORE_AUDIO

=item *

XINE_STREAM_INFO_IGNORE_SPU

=item *

XINE_STREAM_INFO_VIDEO_HAS_STILL

=item *

XINE_STREAM_INFO_MAX_AUDIO_CHANNEL

=item *

XINE_STREAM_INFO_MAX_SPU_CHANNEL

=item *

XINE_STREAM_INFO_AUDIO_MODE

=item *

XINE_STREAM_INFO_SKIPPED_FRAMES

=item *

XINE_STREAM_INFO_DISCARDED_FRAMES

=item *

XINE_STREAM_INFO_VIDEO_AFD

=item *

XINE_STREAM_INFO_DVD_TITLE_NUMBER

=item *

XINE_STREAM_INFO_DVD_TITLE_COUNT

=item *

XINE_STREAM_INFO_DVD_CHAPTER_NUMBER

=item *

XINE_STREAM_INFO_DVD_CHAPTER_COUNT

=item *

XINE_STREAM_INFO_DVD_ANGLE_NUMBER

=item *

XINE_STREAM_INFO_DVD_ANGLE_COUNT

=back

=head2 META CONSTANTS

Exported with the C<:meta_constants> tag.

=over

=item *

XINE_META_INFO_TITLE

=item *

XINE_META_INFO_COMMENT

=item *

XINE_META_INFO_ARTIST

=item *

XINE_META_INFO_GENRE

=item *

XINE_META_INFO_ALBUM

=item *

XINE_META_INFO_YEAR

=item *

XINE_META_INFO_VIDEOCODEC

=item *

XINE_META_INFO_AUDIOCODEC

=item *

XINE_META_INFO_SYSTEMLAYER

=item *

XINE_META_INFO_INPUT_PLUGIN

=item *

XINE_META_INFO_CDINDEX_DISCID

=item *

XINE_META_INFO_TRACK_NUMBER

=back

=head1 SEE ALSO

L<Video::Xine>

=cut
