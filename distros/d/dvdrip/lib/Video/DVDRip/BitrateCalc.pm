# $Id: BitrateCalc.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::BitrateCalc;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;
use strict;

my $VCD_ADDITION_FACTOR = 2324 / 2048;
my $VCD_DISC_OVERHEAD   = 600 * 2324;
my $AVI_VIDEO_OVERHEAD  = 45;
my $AVI_AUDIO_OVERHEAD  = 15;
my $OGG_SIZE_OVERHEAD   = 0.25 / 100;
my $VCD_VIDEO_RATE      = 1152;
my $MAX_SVCD_SUM_RATE   = 2748;
my $MAX_SVCD_VIDEO_RATE = 2600;
my $MAX_VIDEO_RATE      = 9000;

my %VORBIS_NOMINAL_BITRATES = (
    0  => 60,
    1  => 80,
    2  => 96,
    3  => 112,
    4  => 128,
    5  => 160,
    6  => 192,
    7  => 224,
    8  => 256,
    9  => 320,
    10 => 498,
);

# methods for calculation parameters

sub title			{ shift->{title}			}
sub with_sheet			{ shift->{with_sheet}			}
sub audio_size			{ shift->{audio_size}			}
sub vobsub_size			{ shift->{vobsub_size}			}
sub vcd_video_rate		{ shift->{vcd_video_rate}		}
sub max_svcd_sum_rate		{ shift->{max_svcd_sum_rate}		}
sub max_svcd_video_rate		{ shift->{max_svcd_video_rate}		}
sub max_video_rate		{ shift->{max_video_rate}		}

sub set_title			{ shift->{title}		= $_[1]	}
sub set_with_sheet		{ shift->{with_sheet}		= $_[1]	}
sub set_audio_size		{ shift->{audio_size}		= $_[1]	}
sub set_vobsub_size		{ shift->{vobsub_size}		= $_[1]	}
sub set_vcd_video_rate		{ shift->{vcd_video_rate}	= $_[1]	}
sub set_max_svcd_sum_rate	{ shift->{max_svcd_sum_rate}	= $_[1]	}
sub set_max_svcd_video_rate	{ shift->{max_svcd_video_rate}	= $_[1]	}
sub set_max_video_rate		{ shift->{max_video_rate}	= $_[1]	}

# methods for the result of calculation

sub video_bitrate		{ shift->{video_bitrate}		}
sub video_bpp			{ shift->{video_bpp}			}
sub audio_bitrate		{ shift->{audio_bitrate}		}
sub vcd_reserve_bitrate		{ shift->{vcd_reserve_bitrate}		}
sub target_size			{ shift->{target_size}			}
sub disc_size			{ shift->{disc_size}			}
sub video_size			{ shift->{video_size}			}
sub cont_overhead_size		{ shift->{cont_overhead_size}		}
sub other_size			{ shift->{other_size}			}
sub frames			{ shift->{frames}			}
sub runtime			{ shift->{runtime}			}
sub file_size			{ shift->{file_size}			}
sub sheet			{ shift->{sheet}			}

sub set_video_bitrate		{ shift->{video_bitrate}	= $_[1]	}
sub set_video_bpp		{ shift->{video_bpp}		= $_[1]	}
sub set_audio_bitrate		{ shift->{audio_bitrate}	= $_[1]	}
sub set_vcd_reserve_bitrate	{ shift->{vcd_reserve_bitrate}	= $_[1]	}
sub set_target_size		{ shift->{target_size}		= $_[1]	}
sub set_disc_size		{ shift->{disc_size}		= $_[1]	}
sub set_video_size		{ shift->{video_size}		= $_[1]	}
sub set_cont_overhead_size	{ shift->{cont_overhead_size}	= $_[1]	}
sub set_other_size		{ shift->{other_size}		= $_[1]	}
sub set_frames			{ shift->{frames}		= $_[1]	}
sub set_runtime			{ shift->{runtime}		= $_[1]	}
sub set_file_size		{ shift->{file_size}		= $_[1]	}
sub set_sheet			{ shift->{sheet}		= $_[1]	}

sub non_video_size {
    my $self = shift;

    return $self->audio_size + $self->cont_overhead_size + $self->other_size;
}

sub new {
    my $class = shift;
    my %par = @_;
    my  ($title, $with_sheet, $video_bitrate, $video_bpp) =
    @par{'title','with_sheet','video_bitrate','video_bpp'};
    my  ($video_size, $audio_size, $audio_bitrate, $target_size) =
    @par{'video_size','audio_size','audio_bitrate','target_size'};
    my  ($disc_size, $vobsub_size) =
    @par{'disc_size','vobsub_size'};

    my $self = {
        title               => $title,
        with_sheet          => $with_sheet,

        video_bitrate       => $video_bitrate,
        video_bpp           => $video_bpp,
        video_size          => $video_size,

        audio_size          => $audio_size,
        audio_bitrate       => $audio_bitrate,

        target_size         => $target_size,
        disc_size           => $disc_size,
        vobsub_size         => $vobsub_size,

        sheet               => [],
        vcd_video_rate      => $VCD_VIDEO_RATE,
        max_svcd_sum_rate   => $MAX_SVCD_SUM_RATE,
        max_svcd_video_rate => $MAX_SVCD_VIDEO_RATE,
        max_video_rate      => $MAX_VIDEO_RATE,
    };

    return bless $self, $class;
}

sub add_audio_size {
    my $self    = shift;
    my %par     = @_;
    my ($bytes) = @par{'bytes'};

    $self->log( sprintf( "Add audio size: %.2f MB", $bytes / 1024 / 1024 ) );

    $self->set_audio_size( $bytes + $self->audio_size );

    1;
}

sub add_vobsub_size {
    my $self    = shift;
    my %par     = @_;
    my ($bytes) = @par{'bytes'};

    $self->set_vobsub_size( $bytes + $self->vobsub_size );

    1;
}

sub add_to_sheet {
    my $self = shift;
    return 1 if not $self->with_sheet;
    my ($href) = @_;
    push @{ $self->sheet }, $href;
    1;
}

sub calc_frames_and_runtime {
    my $self = shift;

    my $title     = $self->title;
    my $frames    = $title->frames;
    my $framerate = $title->tc_video_framerate;
    my $runtime   = $title->runtime;

    if ( $title->tc_use_chapter_mode eq 'select' ) {

        # get sum of chapter frames (if chapter mode enabled)
        if ( not $title->real_actual_chapter ) {
            $frames = 0;
            my $chapters = $title->get_chapters;
            foreach my $chapter ( @{$chapters} ) {
                $frames += $title->chapter_frames->{$chapter};
            }
        }
        else {
            $frames = $title->chapter_frames->{ $title->actual_chapter };
        }

    }
    elsif ( $title->tc_video_bitrate_range ) {

        # reduce sum of frames (if a range was set)
        if (   $title->tc_start_frame ne ''
            or $title->tc_end_frame ne '' ) {
            $frames = $title->tc_end_frame || $title->frames;
            $frames = $frames - $title->tc_start_frame
                if $title->has_vob_nav_file;
            $frames ||= $title->frames;
        }
        if ( $frames < 0 ) {
            $frames = $title->frames;
        }
    }

    # document frames and recalculate runtime
    if ( $frames and $framerate ) {
        $runtime = $frames / $framerate;
        $self->add_to_sheet(
            {   label    => __ "Number of frames",
                operator => "=",
                value    => $frames,
                unit     => "",
            }
        );
        $self->add_to_sheet(
            {   label    => __ "Frames per second",
                operator => "/",
                value    => $framerate,
                unit     => "fps",
            }
        );
        $self->add_to_sheet(
            {   label    => __ "Runtime",
                operator => "=",
                value    => $runtime,
                unit     => "s",
            }
        );
    }

    $frames  ||= 1;
    $runtime ||= 1;

    $self->set_frames($frames);
    $self->set_runtime($runtime);

    1;
}

sub calc_audio_size_and_bitrate {
    my $self       = shift;
    my %par        = @_;
    my ($operator) = @par{'operator'};

    my $title = $self->title;

    my $audio_size = 0;
    my $audio_bitrate;

    my $runtime   = $self->runtime;
    my $frames    = $self->frames;
    my $container = $title->tc_container;
    if ( $self->audio_size ) {

        # audio size is known already, no need to calculate it.
        $audio_size = sprintf( "%.2f", $self->audio_size / 1024 / 1024 );
        $self->log(
            __x("Audio size is given with {audio_size} MB",
                audio_size => $audio_size
            )
        );
        $self->add_to_sheet(
            {   label    => __ "Audio size",
                operator => "+",
                value    => $audio_size,
                unit     => "MB",
            }
        );
    }
    else {
        my $nr = -1;
        foreach my $audio ( @{ $title->audio_tracks } ) {
            ++$nr;
            next if $audio->tc_target_track == -1;

            my $bitrate = $audio->tc_bitrate;

            if (    $audio->tc_audio_codec eq 'vorbis'
                and $audio->tc_vorbis_quality_enable ) {

                # derive a bitrate from vorbis quality setting
                $bitrate = $VORBIS_NOMINAL_BITRATES{
                    int( $audio->tc_vorbis_quality + 0.5 ) };
            }
            my $track_size = $runtime * $bitrate * 1000 / 8 / 1024 / 1024;
            my $audio_overhead;
            $audio_overhead = $AVI_AUDIO_OVERHEAD * $frames / 1024 / 1024
                if $container eq 'avi';

            $track_size = sprintf( "%.2f", $track_size + $audio_overhead );

            my $comment;

            if ( $container eq 'avi' ) {
                $comment = " "
                    . __x(
                    "(incl. {avi_overhead} byte" . " AVI overhead per frame)",
                    avi_overhead => $AVI_AUDIO_OVERHEAD
                    );
            }

            if ( $audio->tc_audio_codec eq 'vorbis' ) {
                if ( $audio->tc_vorbis_quality_enable ) {
                    $comment = " "
                        . __ "(assume nominal bitrate for this quality)";
                }
                else {
                    $comment = " " . __ "(exact bitrate match assumed)";
                }
            }

            $self->add_to_sheet(
                {   label => __x( "Audio track #{nr}", nr => $nr ) . $comment,
                    operator => $operator,
                    value    => $track_size,
                    unit     => "MB",
                }
            );

            $audio_size    += $track_size;
            $audio_bitrate += $bitrate;
        }
    }

    $self->set_audio_size($audio_size);
    $self->set_audio_bitrate($audio_bitrate);

    1;
}

sub calc_container_overhead {
    my $self       = shift;
    my %par        = @_;
    my ($operator) = @par{'operator'};

    my $title              = $self->title;
    my $container          = $title->tc_container;
    my $frames             = $self->frames;
    my $container_overhead = 0;

    if ( $container eq 'avi' ) {
        $container_overhead
            = sprintf( "%.2f", $AVI_VIDEO_OVERHEAD * $frames / 1024 / 1024 );

        $self->add_to_sheet(
            {   label => __x(
                    "AVI video overhead ({avi_overhead} bytes per frame)",
                    avi_overhead => $AVI_VIDEO_OVERHEAD
                ),
                operator => $operator,
                value    => $container_overhead,
                unit     => "MB",
            }
        );

    }
    elsif ( $container eq 'ogg' ) {
        my $file_size;
        if ( $self->video_size ) {
            $file_size = $self->video_size + $self->audio_size;
        }
        else {
            $file_size = $self->target_size - $self->non_video_size;
        }
        $container_overhead
            = sprintf( "%.2f", $OGG_SIZE_OVERHEAD * $file_size );

        $self->add_to_sheet(
            {   label => __x(
                    "OGG overhead ({ogg_overhead} percent of video+audio size)",
                    ogg_overhead => $OGG_SIZE_OVERHEAD * 100
                ),
                operator => $operator,
                value    => $container_overhead,
                unit     => "MB",
            }
        );
    }

    $self->set_cont_overhead_size($container_overhead);

    # calculate vcd multiplex bitrate reserve
    my $vcd_reserve_bitrate = $self->audio_bitrate +
        int( ( $self->audio_bitrate + $self->video_bitrate ) * 0.02 );

    $self->set_vcd_reserve_bitrate($vcd_reserve_bitrate);

    1;
}

sub calc_target_size {
    my $self = shift;

    my $title = $self->title;

    my $target_size;
    if ($title->tc_disc_cnt * $title->tc_disc_size == $title->tc_target_size )
    {

        # Number of discs
        my $disc_cnt = $title->tc_disc_cnt;
        $self->add_to_sheet(
            {   label    => __ "Number of discs",
                operator => "",
                value    => $disc_cnt,
                unit     => "",
            }
        );

        # Size of a disc
        my $disc_size = $title->tc_disc_size;
        $self->add_to_sheet(
            {   label    => __ "Disc size",
                operator => "*",
                value    => $disc_size,
                unit     => "MB",
            }
        );

        $target_size = $disc_cnt * $disc_size;
    }
    else {
        $target_size = $title->tc_target_size;
    }

    $self->add_to_sheet(
        {   label    => __ "Target size",
            operator => "=",
            value    => $target_size,
            unit     => "MB",
        }
    );

    $self->set_target_size($target_size);

    1;
}

sub calc_disc_size {
    my $self = shift;

    my $title = $self->title;

    my $disc_size = $title->tc_disc_size;
    $disc_size = int(
        $disc_size * $VCD_ADDITION_FACTOR - $VCD_DISC_OVERHEAD / 1024 / 1024 )
        if $title->tc_container eq 'vcd';

    $self->set_disc_size($disc_size);

    1;
}

sub calc_svcd_overhead {
    my $self = shift;

    my $title       = $self->title;
    my $target_size = $self->target_size || 1;
    my $container   = $title->tc_container;

    if (    $container eq 'vcd'
        and $title->tc_disc_cnt * $title->tc_disc_size
        == $title->tc_target_size ) {
        my $addition = sprintf( "%.2f", ( 2324 / 2048 - 1 ) * $target_size );
        $self->add_to_sheet(
            {   label    => __ "VCD sector size addition (factor: 2324/2048)",
                operator => "+",
                value    => $addition,
                unit     => "MB",
            }
        );
        $target_size += $addition;

        my $disc_overhead = sprintf( "%.2f",
            $VCD_DISC_OVERHEAD * $title->tc_disc_cnt / 1024 / 1024 );
        $self->add_to_sheet(
            {   label    => __ "VCD per disc overhead (600 sectors)",
                operator => "-",
                value    => $disc_overhead,
                unit     => "MB",
            }
        );
        $target_size -= $disc_overhead;

        $self->add_to_sheet(
            {   label    => __ "(X)(S)VCD/CVD target size",
                operator => "=",
                value    => $target_size,
                unit     => "MB",
            }
        );

        $self->set_target_size($target_size);
    }

    1;
}

sub calc_vobsub_size {
    my $self       = shift;
    my %par        = @_;
    my ($operator) = @par{'operator'};

    my $title = $self->title;

    my $vobsub_size = 0;

    if ( $self->vobsub_size ) {

        # vobsub size is known already, no need to calculate it.
        $vobsub_size = sprintf( "%.2f", $self->vobsub_size / 1024 / 1024 );
        $self->add_to_sheet(
            {   label    => __ "vobsub size",
                operator => $operator,
                value    => $vobsub_size,
                unit     => "MB",
            }
        );
    }
    else {
        foreach my $subtitle ( sort { $a->id <=> $b->id }
            values %{ $title->subtitles } ) {
            next if not $subtitle->tc_vobsub;
            $vobsub_size += 1;
            $self->add_to_sheet(
                {   label => __x(
                        "vobsub size subtitle #{nr}",
                        nr => $subtitle->id
                    ),
                    operator => $operator,
                    value    => 1,
                    unit     => "MB",
                }
            );
        }
    }

    $self->set_vobsub_size($vobsub_size);

    1;
}

sub calc_video_size_and_bitrate {
    my $self = shift;

    my $title = $self->title;

    my $runtime       = $self->runtime;
    my $audio_bitrate = $self->audio_bitrate;

    my ( $width, $height ) = $title->get_effective_ratio( type => "clip2" );

    # video size
    my $video_size = $self->target_size - $self->non_video_size;

    $self->add_to_sheet(
        {   label    => __ "Space left for video",
            operator => "=",
            value    => $video_size,
            unit     => "MB",
        }
    );

    # resulting video bitrate
    my $video_bitrate
        = int( $video_size / $runtime / 1000 * 1024 * 1024 * 8 );

    $self->add_to_sheet(
        {   label    => __("Resulting video bitrate, rounded"),
            operator => "~",
            value    => $video_bitrate,
            unit     => "kbit/s",
        }
    );

    # probably too high for selected video codec
    $video_bitrate
        = $self->calc_video_bitrate_limit( video_bitrate => $video_bitrate, );

    # calculate bpp
    my $bpp = 0;
    if ( $title->tc_video_bitrate_mode eq 'bpp' ) {
        $bpp = sprintf( "%.3f", $title->tc_video_bpp_manual );
    }
    else {
        my $pps = $title->frame_rate * $width * $height;
        $bpp = $video_bitrate * 1000 / $pps if $pps != 0;
        $bpp = sprintf( "%.3f", $bpp );
    }

    $self->add_to_sheet(
        {   label    => __("Resulting BPP"),
            operator => "",
            value    => $bpp,
            unit     => "bpp",
        }
    );

    # calculate *real* video size, if bitrate has changed
    # after calculation (due to limits)
    $video_size = sprintf( "%.2f",
        $video_bitrate * $runtime * 1000 / 1024 / 1024 / 8 );

    $self->add_to_sheet(
        {   label    => __ "Resulting video size",
            operator => "~",
            value    => $video_size,
            unit     => "MB",
        }
    );

    $self->set_video_bitrate($video_bitrate);
    $self->set_video_bpp($bpp);
    $self->set_video_size($video_size);

    1;
}

sub calc_video_bitrate_limit {
    my $self            = shift;
    my %par             = @_;
    my ($video_bitrate) = @par{'video_bitrate'};

    my $title         = $self->title;
    my $audio_bitrate = $self->audio_bitrate;

    my $comment;
    if ( $video_bitrate > $self->max_video_rate ) {
        $video_bitrate = $self->max_video_rate;
        $comment       = __x(
            "Bitrate too high, set to {max_video_rate}",
            max_video_rate => $self->max_video_rate
        );
    }

    if (    $title->tc_video_codec =~ /^(SVCD|CVD|VCD)$/
        and $video_bitrate + $audio_bitrate > $self->max_svcd_sum_rate ) {
        $video_bitrate = $self->max_svcd_sum_rate - $audio_bitrate;
        $comment       = __ "Bitrate too high, limited";
    }

    if (    $title->tc_video_codec =~ /^(SVCD|CVD|VCD)$/
        and $video_bitrate > $self->max_svcd_video_rate ) {
        $video_bitrate = $self->max_svcd_video_rate;
        $comment       = __ "Bitrate too high, limited";
    }

    if (    $title->tc_video_codec =~ /^VCD$/
        and $title->tc_video_bitrate_mode ne 'manual' ) {
        $video_bitrate = $self->vcd_video_rate;
        $comment       = __ "VCD has fixed rate";
    }

    if ($comment) {
        $self->add_to_sheet(
            {   label    => $comment,
                operator => "=",
                value    => $video_bitrate,
                unit     => "kbit/s",
            }
        );
    }

    return $video_bitrate;
}

sub calc_video_size_from_bitrate {
    my $self = shift;

    my $title = $self->title;

    my $video_bitrate = $title->tc_video_bitrate_manual;
    my $video_bpp     = $title->tc_video_bpp_manual;
    my ( $width, $height ) = $title->get_effective_ratio( type => "clip2" );

    # pixel per second
    my $pps = $title->frame_rate * $width * $height;

    if ( $title->tc_video_bitrate_mode eq 'bpp' ) {
        $video_bitrate = int( $video_bpp * $pps / 1000 );
        $video_bitrate = 100 if $video_bitrate < 100;
        $video_bpp     = sprintf( "%.3f", $video_bpp );
        $self->add_to_sheet(
            {   label    => __ "Manual BPP setting",
                operator => "=",
                value    => $video_bpp,
                unit     => "bpp",
            }
        );
        $self->add_to_sheet(
            {   label    => __ "Resulting Video Bitrate",
                operator => "~",
                value    => $video_bitrate,
                unit     => "kbit/s",
            }
        );
        $video_bitrate = $self->calc_video_bitrate_limit(
            video_bitrate => $video_bitrate, );
    }
    else {
        $video_bpp = $video_bitrate * 1000 / $pps if $pps != 0;
        $video_bpp = sprintf( "%.3f", $video_bpp );
        $self->add_to_sheet(
            {   label    => __ "Manual video bitrate setting",
                operator => "=",
                value    => $video_bitrate,
                unit     => "kbit/s",
            }
        );
        $video_bitrate = $self->calc_video_bitrate_limit(
            video_bitrate => $video_bitrate, );
        $self->add_to_sheet(
            {   label    => __ "Resulting BPP",
                operator => "~",
                value    => $video_bpp,
                unit     => "bpp",
            }
        );
    }

    my $video_size = sprintf( "%.2f",
        $video_bitrate * $self->runtime * 1000 / 1024 / 1024 / 8 );

    $self->add_to_sheet(
        {   label    => __ "Resulting Video Size",
            operator => "=",
            value    => $video_size,
            unit     => "MB",
        }
    );

    $self->set_video_bitrate($video_bitrate);
    $self->set_video_bpp($video_bpp);
    $self->set_video_size($video_size);

    1;
}

sub calc_file_size {
    my $self = shift;

    my $file_size
        = $self->video_size + $self->audio_size + $self->cont_overhead_size
        + $self->other_size;

    $self->add_to_sheet(
        {   label    => __ "Resulting File Size",
            operator => "=",
            value    => $file_size,
            unit     => "MB",
        }
    );

    $self->set_file_size($file_size);

    1;
}

sub calc_other_size {
    my $self = shift;

    my $other_size = $self->vobsub_size;

    $self->set_other_size($other_size);

    1;
}

sub calculate {
    my $self = shift;

    my $title = $self->title;

    if ( $title->tc_video_bitrate_mode eq 'size' ) {
        return $self->calculate_video_bitrate;
    }
    else {
        return $self->calculate_with_manual_bitrate;
    }
}

sub calculate_video_bitrate {
    my $self = shift;

    # init sheet
    $self->set_sheet( [] );

    # 1. frames and runtime
    $self->calc_frames_and_runtime;

    # 2. target size
    $self->calc_target_size;

    # 3. (S)VCD addition? (probably changes target_size)
    $self->calc_svcd_overhead;

    # 4. Audio tracks
    $self->calc_audio_size_and_bitrate( operator => "-" );

    # 5. vobsub size
    $self->calc_vobsub_size( operator => "-" );

    # 7. AVI / OGG overhead
    $self->calc_container_overhead( operator => "-" );

    # 6. resulting video size
    $self->calc_video_size_and_bitrate;

    # 8. calculate real disc size (inkl. vcd addition)
    $self->calc_disc_size;

    # 9. calculate other size
    $self->calc_other_size;

    # 10. calculate final file size
    $self->calc_file_size;

    return $self->video_bitrate;
}

sub calculate_with_manual_bitrate {
    my $self = shift;

    # init sheet
    $self->set_sheet( [] );

    # 1. frames and runtime
    $self->calc_frames_and_runtime;

    # 2. resulting video size, bitrate or bpp
    $self->calc_video_size_from_bitrate;

    # 3. Audio tracks
    $self->calc_audio_size_and_bitrate( operator => "+" );

    # 4. vobsub size
    $self->calc_vobsub_size( operator => "+" );

    # 5. AVI / OGG overhead
    $self->calc_container_overhead( operator => "+" );

    # 6. calculate real disc size (inkl. vcd addition)
    $self->calc_disc_size;

    # 7. calculate other size
    $self->calc_other_size;

    # 8. calc target size as sum of all calculated sizes
    $self->calc_file_size;

    return $self->video_bitrate;
}

1;
