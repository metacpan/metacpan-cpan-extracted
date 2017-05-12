# $Id: Audio.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Audio;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;

# Title this track belongs to
sub title			{ shift->{title}			}
sub set_title			{ shift->{title}		= $_[1]	}

# Attributes of the audio channel on DVD

sub type			{ shift->{type}				}
sub lang			{ shift->{lang}				}
sub channels			{ shift->{channels}			}
sub bitrate			{ shift->{bitrate}			}
sub sample_rate			{ shift->{sample_rate}			}
sub volume_rescale		{ shift->{volume_rescale}		}
sub scan_output			{ shift->{scan_output}			}

sub set_type			{ shift->{type}			= $_[1]	}
sub set_lang			{ shift->{lang}			= $_[1]	}
sub set_channels		{ shift->{channels}		= $_[1]	}
sub set_bitrate			{ shift->{bitrate}		= $_[1]	}
sub set_sample_rate		{ shift->{sample_rate}		= $_[1]	}
sub set_volume_rescale		{ shift->{volume_rescale}	= $_[1]	}
sub set_scan_output		{ shift->{scan_output}		= $_[1] }

# Options for transcoding the audio channel

sub tc_nr			{ shift->{tc_nr}			}
sub tc_target_track		{ shift->{tc_target_track}		}
sub tc_audio_filter		{ shift->{tc_audio_filter}		}
sub tc_option_n			{ shift->{tc_option_n}			}
sub tc_volume_rescale		{ shift->{tc_volume_rescale}		}

sub set_tc_nr			{ shift->{tc_nr}		= $_[1]	}
sub set_tc_target_track		{ shift->{tc_target_track}	= $_[1]	}
#sub set_tc_audio_filter	{ shift->{tc_audio_filter}	= $_[1]	}
sub set_tc_option_n		{ shift->{tc_option_n}		= $_[1]	}
sub set_tc_volume_rescale	{ shift->{tc_volume_rescale}	= $_[1]	}

sub tc_audio_codec		{ shift->{tc_audio_codec}		}
sub tc_mp3_bitrate		{ shift->{tc_mp3_bitrate}		}
sub tc_mp3_samplerate		{ shift->{tc_mp3_samplerate}		}
sub tc_mp3_quality		{ shift->{tc_mp3_quality}		}
sub tc_ac3_bitrate		{ shift->{tc_ac3_bitrate}		}
sub tc_vorbis_bitrate		{ shift->{tc_vorbis_bitrate}		}
sub tc_vorbis_samplerate	{ shift->{tc_vorbis_samplerate}		}
sub tc_vorbis_quality		{ shift->{tc_vorbis_quality}		}
sub tc_vorbis_quality_enable	{ shift->{tc_vorbis_quality_enable}	}
sub tc_mp2_bitrate		{ shift->{tc_mp2_bitrate}		}
sub tc_mp2_samplerate		{ shift->{tc_mp2_samplerate}		}
sub tc_pcm_bitrate		{ shift->{tc_pcm_bitrate}		}

#sub set_tc_audio_codec		{ shift->{tc_audio_codec}	= $_[1]	}
#sub set_tc_mp3_bitrate		{ shift->{tc_mp3_bitrate}	= $_[1]	}
sub set_tc_mp3_samplerate	{ shift->{tc_mp3_samplerate}	= $_[1]	}
sub set_tc_mp3_quality		{ shift->{tc_mp3_quality}	= $_[1]	}
sub set_tc_ac3_bitrate		{ shift->{tc_ac3_bitrate}	= $_[1]	}
#sub set_tc_vorbis_bitrate	{ shift->{tc_vorbis_bitrate}	= $_[1]	}
sub set_tc_vorbis_samplerate	{ shift->{tc_vorbis_samplerate}	= $_[1]	}
#sub set_tc_vorbis_quality	{ shift->{tc_vorbis_quality}	= $_[1]	}
#sub set_tc_vorbis_quality_enable{ shift->{tc_vorbis_quality_enable}=$_[1]}
#sub set_tc_mp2_bitrate		{ shift->{tc_mp2_bitrate}	= $_[1]	}
sub set_tc_mp2_samplerate	{ shift->{tc_mp2_samplerate}	= $_[1]	}
sub set_tc_pcm_bitrate		{ shift->{tc_pcm_bitrate}	= $_[1]	}

sub set_tc_audio_filter {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_audio_filter} = $value;
    if ( $value eq 'rescale' ) {
        $self->set_tc_volume_rescale( $self->volume_rescale );
    }
    else {
        $self->set_tc_volume_rescale("");
    }
    return $value;
}

sub set_tc_audio_codec {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_audio_codec} = $value;
    $self->title->calc_video_bitrate;
    return $value;
}

sub set_tc_mp3_bitrate {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_mp3_bitrate} = $value;
    $self->title->calc_video_bitrate;
    return $value;
}

sub set_tc_mp2_bitrate {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_mp2_bitrate} = $value;
    $self->title->calc_video_bitrate;
    return $value;
}

sub set_tc_vorbis_bitrate {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_vorbis_bitrate} = $value;
    $self->title->calc_video_bitrate;
    return $value;
}

sub set_tc_vorbis_quality {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_vorbis_quality} = $value;
    $self->title->calc_video_bitrate;
    return $value;
}

sub set_tc_vorbis_quality_enable {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_vorbis_quality_enable} = $value;
    $self->title->calc_video_bitrate;
    return $value;
}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $type, $lang, $channels, $bitrate, $volume_rescale )
        = @par{ 'type', 'lang', 'channels', 'bitrate', 'volume_rescale' };
    my ( $title, $sample_rate, $scan_output )
        = @par{ 'title', 'sample_rate', 'scan_output' };
    my ( $tc_target_track, $tc_audio_codec, $tc_bitrate )
        = @par{ 'tc_target_track', 'tc_audio_codec', 'tc_bitrate' };
    my ( $tc_ac3_passthrough, $tc_mp3_quality, $tc_audio_filter )
        = @par{ 'tc_ac3_passthrough', 'tc_mp3_quality', 'tc_audio_filter' };
    my ( $tc_option_n, $tc_volume_rescale, $tc_nr )
        = @par{ 'tc_option_n', 'tc_volume_rescale', 'tc_nr' };
    my ( $tc_ac3_bitrate, $tc_samplerate )
        = @par{ 'tc_ac3_bitrate', 'tc_samplerate' };

    $tc_target_track = -1    if not defined $tc_target_track;
    $tc_audio_codec  = "ac3" if $tc_ac3_passthrough;
    $tc_audio_codec    ||= "mp3";
    $tc_bitrate        ||= 128;
    $tc_mp3_quality    ||= 2;
    $tc_audio_filter   ||= 'rescale';
    $tc_option_n       ||= '';
    $tc_volume_rescale ||= 0;

    my $self = {
        title                    => $title,
        type                     => $type,
        lang                     => $lang,
        channels                 => $channels,
        bitrate                  => $bitrate,
        sample_rate              => $sample_rate,
        volume_rescale           => $volume_rescale,
        scan_output              => $scan_output,
        tc_nr                    => $tc_nr,
        tc_target_track          => $tc_target_track,
        tc_audio_codec           => $tc_audio_codec,
        tc_ac3_bitrate           => $tc_ac3_bitrate,
        tc_mp3_bitrate           => $tc_bitrate,
        tc_mp2_bitrate           => $tc_bitrate,
        tc_vorbis_bitrate        => $tc_bitrate,
        tc_mp3_samplerate        => $tc_samplerate,
        tc_vorbis_samplerate     => $tc_samplerate,
        tc_mp3_quality           => $tc_mp3_quality,
        tc_audio_filter          => $tc_audio_filter,
        tc_option_n              => $tc_option_n,
        tc_volume_rescale        => $tc_volume_rescale,
        tc_vorbis_quality        => 3.00,
        tc_vorbis_quality_enable => 0,
    };

    return bless $self, $class;
}

sub tc_bitrate {
    my $self        = shift;
    my $audio_codec = $self->tc_audio_codec;
    my $method      = "tc_" . $audio_codec . "_bitrate";
    return $self->$method();
}

sub set_tc_bitrate {
    my $self        = shift;
    my ($val)       = @_;
    my $audio_codec = $self->tc_audio_codec;
    my $method      = "set_tc_" . $audio_codec . "_bitrate";
    return $self->$method($val);
}

sub tc_samplerate {
    my $self        = shift;
    my $audio_codec = $self->tc_audio_codec;
    my $method      = "tc_" . $audio_codec . "_samplerate";
    return $self->$method();
}

sub ac3_ok {
    my $self = shift;

    my $ok = ( $self->type eq 'ac3' and $self->bitrate ne '' );

    return $ok;
}

sub pcm_ok {
    my $self = shift;

    my $ok = ( $self->type eq 'lpcm' and $self->bitrate ne '' );

    return $ok;
}

sub is_passthrough {
    my $self = shift;
    return $self->tc_audio_codec eq 'ac3'
        || $self->tc_audio_codec eq 'pcm';
}

sub info {
    my $self          = shift;
    my %par           = @_;
    my ($with_target) = @par{'with_target'};

    my $sample_rate = $self->sample_rate;
    $sample_rate = "48kHz"   if $sample_rate == 48000;
    $sample_rate = "41.1kHz" if $sample_rate == 44100;

    my $target;
    if ($with_target) {
        if ( $self->tc_target_track < 0 ) {
            $target = " => " . __ "Discard";
        }
        else {
            $target = " => " . ( $self->tc_target_track + 1 );
        }
    }

    return $self->lang . " "
        . $self->type . " "
        . "$sample_rate "
        . $self->channels
        . "Ch$target";
}

1;
