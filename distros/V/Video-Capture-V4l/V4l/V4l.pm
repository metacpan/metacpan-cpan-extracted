package Video::Capture::V4l;

use strict 'subs';
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

use Fcntl;

$VERSION = '0.902';

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	MODE_AUTO MODE_NTSC MODE_PAL MODE_SECAM
	PALETTE_GREY PALETTE_HI240 PALETTE_PLANAR PALETTE_RAW PALETTE_RGB24
	PALETTE_RGB32 PALETTE_RGB555 PALETTE_RGB565 PALETTE_UYVY PALETTE_YUV410P
	PALETTE_YUV411 PALETTE_YUV411P PALETTE_YUV420 PALETTE_YUV420P PALETTE_YUV422
	PALETTE_YUV422P PALETTE_YUYV
	SOUND_LANG1 SOUND_LANG2 SOUND_MONO SOUND_STEREO
        VBI_MAXLINES VBI_BPL VBI_BPF
);

@EXPORT_OK = qw(
	MODE_AUTO MODE_NTSC MODE_PAL MODE_SECAM
	PALETTE_GREY PALETTE_HI240 PALETTE_PLANAR PALETTE_RAW PALETTE_RGB24
	PALETTE_RGB32 PALETTE_RGB555 PALETTE_RGB565 PALETTE_UYVY PALETTE_YUV410P
	PALETTE_YUV411 PALETTE_YUV411P PALETTE_YUV420 PALETTE_YUV420P PALETTE_YUV422
	PALETTE_YUV422P PALETTE_YUYV
	SOUND_LANG1 SOUND_LANG2 SOUND_MONO SOUND_STEREO
	AUDIO_MUTE 

	AUDIO_BASS AUDIO_MUTABLE AUDIO_TREBLE AUDIO_VOLUME
	TUNER_LOW TUNER_MBS_ON TUNER_NORM TUNER_NTSC TUNER_PAL
	TUNER_RDS_ON TUNER_SECAM TUNER_STEREO_ON
	VC_AUDIO VC_TUNER
	TYPE_CAMERA TYPE_TV

	BASE_VIDIOCPRIVATE
	CAPTURE_EVEN
	CAPTURE_ODD
	CLIPMAP_SIZE
	CLIP_BITMAP
	MAX_FRAME
	NO_UNIT
	PALETTE_COMPONENT
	WINDOW_INTERLACE
	HARDWARE_AZTECH
	HARDWARE_BROADWAY
	HARDWARE_BT848
	HARDWARE_CADET
	HARDWARE_GEMTEK
	HARDWARE_PERMEDIA2
	HARDWARE_PLANB
	HARDWARE_PMS
	HARDWARE_PSEUDO
	HARDWARE_QCAM_BW
	HARDWARE_QCAM_C
	HARDWARE_RIVA128
	HARDWARE_RTRACK
	HARDWARE_RTRACK2
	HARDWARE_SAA5249
	HARDWARE_SAA7146
	HARDWARE_SF16MI
	HARDWARE_TYPHOON
	HARDWARE_VIDEUM
	HARDWARE_VINO
	HARDWARE_ZOLTRIX
	TYPE_CAPTURE
	TYPE_CHROMAKEY
	TYPE_CLIPPING
	TYPE_FRAMERAM
	TYPE_MONOCHROME
	TYPE_OVERLAY
	TYPE_SCALES
	TYPE_SUBCAPTURE
	TYPE_TELETEXT
	TYPE_TUNER
);

# shit
sub VBI_MAXLINES	(){ 32 }
sub VBI_BPL		(){ 2048 }
sub VBI_BPF		(){ VBI_BPL * VBI_MAXLINES }

bootstrap Video::Capture::V4l $VERSION;

sub new(;$) {
   my $class  = shift;
   my $device = shift || "/dev/video0";
   my $self = bless { device => $device }, $class;

   $self->{handle} = local *{$device};
   sysopen $self->{handle},$device,O_RDWR or return;
   $self->{fd} = fileno ($self->{handle});
   $self->{capability} = _capabilities_new ($self->{fd});
   $self->{picture} = _picture_new ($self->{fd});

   $self->{capability}->get
   && $self->{picture}->get ? $self : ();
}

sub capability($) { shift->{capability} }
sub picture($)    { shift->{picture} }

sub channel($$) {
   my $c = _channel_new ($_[0]->{fd});
   $c->channel ($_[1]);
   $c->get ? $c : ();
}

sub tuner($$) {
   my $c = _tuner_new ($_[0]->{fd});
   $c->tuner ($_[1]);
   $c->get ? $c : ();
}

sub audio($$) {
   my $c = _audio_new ($_[0]->{fd});
   $c->audio ($_[1]);
   $c->get ? $c : ();
}

sub freq($;$) {
   _freq (shift->{fd},@_);
}

package Video::Capture::V4l::Capability;

sub capture   ($){ shift->type & &Video::Capture::V4l::TYPE_CAPTURE   }
sub tuner     ($){ shift->type & &Video::Capture::V4l::TYPE_TUNER     }
sub teletext  ($){ shift->type & &Video::Capture::V4l::TYPE_TELETEXT  }
sub overlay   ($){ shift->type & &Video::Capture::V4l::TYPE_OVERLAY   }
sub chromakey ($){ shift->type & &Video::Capture::V4l::TYPE_CHROMAKEY }
sub clipping  ($){ shift->type & &Video::Capture::V4l::TYPE_CLIPPING  }
sub frameram  ($){ shift->type & &Video::Capture::V4l::TYPE_FRAMERAM  }
sub scales    ($){ shift->type & &Video::Capture::V4l::TYPE_SCALES    }
sub monochrome($){ shift->type & &Video::Capture::V4l::TYPE_MONOCHROME}
sub subcapture($){ shift->type & &Video::Capture::V4l::TYPE_SUBCAPTURE}

package Video::Capture::V4l::Channel;

sub tuner     ($){ shift->flags & &Video::Capture::V4l::VC_TUNER      }
sub audio     ($){ shift->flags & &Video::Capture::V4l::VC_AUDIO      }

sub tv        ($){ shift->type & &Video::Capture::V4l::TYPE_TV        }
sub camera    ($){ shift->type & &Video::Capture::V4l::TYPE_CAMERA    }

package Video::Capture::V4l::Tuner;

sub pal       ($){ shift->flags & &Video::Capture::V4l::TUNER_PAL     }
sub ntsc      ($){ shift->flags & &Video::Capture::V4l::TUNER_NTSC    }
sub secam     ($){ shift->flags & &Video::Capture::V4l::TUNER_SECAM   }
sub low       ($){ shift->flags & &Video::Capture::V4l::TUNER_LOW     }
sub norm      ($){ shift->flags & &Video::Capture::V4l::TUNER_NORM    }
sub stereo_on ($){ shift->flags & &Video::Capture::V4l::TUNER_STEREO_ON}
sub rds_on    ($){ shift->flags & &Video::Capture::V4l::TUNER_RDS_ON  }
sub mbs_on    ($){ shift->flags & &Video::Capture::V4l::TUNER_MBS_ON  }

package Video::Capture::V4l::Audio;

sub mute      ($){ shift->flags & &Video::Capture::V4l::AUDIO_MUTE    }
sub mutatble  ($){ shift->flags & &Video::Capture::V4l::AUDIO_MUTABLE }
sub volume    ($){ shift->flags & &Video::Capture::V4l::AUDIO_VOLUME  }
sub bass      ($){ shift->flags & &Video::Capture::V4l::AUDIO_BASS    }
sub treble    ($){ shift->flags & &Video::Capture::V4l::AUDIO_TREBLE  }

package Video::Capture::V4l::VBI;

use Fcntl;

sub new(;$) {
   my $class  = shift;
   my $device = shift || "/dev/vbi0";
   my $self = bless { device => $device }, $class;

   $self->{handle} = local *{$device};
   sysopen $self->{handle},$device,O_RDWR or return;
   $self->{fd} = fileno ($self->{handle});

   $self
}

sub fileno($) {
   $_[0]->{fd}
}

1;
__END__

=head1 NAME

Video::Capture::V4l - Perl interface to the Video4linux framegrabber interface.

=head1 SYNOPSIS

  use Video::Capture::V4l;

=head1 DESCRIPTION

Not documentation AGAIN! Please see the scripts grab, inexer or vbi that
are packaged in the distribution and direct any question and feature
requests (as well as bug reports) to the author.

=head1 Exported constants

The following hideous constants are defined in the C<Video::Capture::V4l> package,
but you rarely need to use them.

  AUDIO_BASS
  AUDIO_MUTABLE
  AUDIO_MUTE
  AUDIO_TREBLE
  AUDIO_VOLUME
  CAPTURE_EVEN
  CAPTURE_ODD
  MAX_FRAME
  MODE_AUTO
  MODE_NTSC
  MODE_PAL
  MODE_SECAM
  PALETTE_COMPONENT
  PALETTE_GREY
  PALETTE_HI240
  PALETTE_PLANAR
  PALETTE_RAW
  PALETTE_RGB24
  PALETTE_RGB32
  PALETTE_RGB555
  PALETTE_RGB565
  PALETTE_UYVY
  PALETTE_YUV410P
  PALETTE_YUV411
  PALETTE_YUV411P
  PALETTE_YUV420
  PALETTE_YUV420P
  PALETTE_YUV422
  PALETTE_YUV422P
  PALETTE_YUYV
  SOUND_LANG1
  SOUND_LANG2
  SOUND_MONO
  SOUND_STEREO
  TUNER_LOW
  TUNER_MBS_ON
  TUNER_NORM
  TUNER_NTSC
  TUNER_PAL
  TUNER_RDS_ON
  TUNER_SECAM
  TUNER_STEREO_ON
  TYPE_CAMERA
  TYPE_TV
  VC_AUDIO
  VC_TUNER
  TYPE_CAPTURE
  TYPE_CHROMAKEY
  TYPE_CLIPPING
  TYPE_FRAMERAM
  TYPE_MONOCHROME
  TYPE_OVERLAY
  TYPE_SCALES
  TYPE_SUBCAPTURE
  TYPE_TELETEXT
  TYPE_TUNER

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=head1 LICENSE

This module is available under GPL only (see the file COPYING for
details), if you want an exception please contact the author, who might
grant exceptions freely ;)

=head1 SEE ALSO

perl(1).

=cut
