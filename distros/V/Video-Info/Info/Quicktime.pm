package Video::Info::Quicktime;

use strict;
use Video::OpenQuicktime;
use base qw(Video::Info);

our $VERSION = '0.02';
use constant DEBUG => 0;

sub init {
  my $self = shift;
  my %raw = @_;
  my %param;
  foreach(keys %raw){/^-?(.+)/;$param{$1} = $raw{$_}};

  warn Video::OpenQuicktime->new( );
  $self->oqt( Video::OpenQuicktime->new( file=>$param{file} ) );
  $self->init_attributes(%param);
  return $self;
}

sub oqt {
  my $self = shift;
  my $arg = shift;
  $self->{oqt} = $arg if defined $arg;
  return $self->{oqt};
}

sub probe {
  return 1;
}

sub achans { return shift->oqt->get_audio_channels      }
sub acodec { return shift->oqt->get_audio_compressor    }
sub acodecraw { warn 'not implemented! ask the author to add reverse-lookups for GUIDs in Magic.pm'; return -1       }
sub arate  { return shift->oqt->get_audio_samplerate    }
sub astreams { return shift->oqt->get_audio_track_count }
sub afrequency { warn "not implemented!"; return -1     }
sub vcodec { return shift->oqt->get_video_compressor    }
sub vframes { return shift->oqt->get_video_length       }
sub vrate  { warn "not implemented!"; return -1         }
sub vstreams { return shift->oqt->get_video_track_count }
sub fps { return shift->oqt->get_video_framerate        }
sub width { return shift->oqt->get_video_width          }
sub height { return shift->oqt->get_video_height        }
sub type { warn 'not implemented! ask the author to implement stream_reference()'; return -1 }
sub duration { return shift->oqt->length                }
sub title { warn 'not implemented!'; return -1          }
sub copyright { warn 'not implemented!'; return -1      }

1;

__END__

=head1 NAME

Video::Info::Quicktime - extract information from Quicktime (TM) files.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day <allenday@ucla.edu>

=head1 SEE ALSO

L<perl>
L<Video::Info>
L<Video::OpenQuicktime>

=cut

