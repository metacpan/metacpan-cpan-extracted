# $Id: Title.pm 2374 2009-02-22 18:33:07Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Title;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Video::DVDRip::Probe;
use Video::DVDRip::PSU;
use Video::DVDRip::Audio;
use Video::DVDRip::Subtitle;
use Video::DVDRip::BitrateCalc;
use Video::DVDRip::FilterSettings;

use Carp;
use strict;

use FileHandle;
use File::Path;
use File::Basename;
use File::Copy;

# Back reference to the project of this title

sub project			{ shift->{project}			}
sub set_project			{ shift->{project}		= $_[1] }

#------------------------------------------------------------------------
# These attributes are probed from the DVD
#------------------------------------------------------------------------

sub width			{ shift->{width}			}
sub height			{ shift->{height}			}
sub aspect_ratio		{ shift->{aspect_ratio}			}
sub video_mode			{ shift->{video_mode}			}
sub letterboxed			{ shift->{letterboxed}			}
sub frames			{ shift->{frames}			}
sub runtime			{ shift->{runtime}			}
sub frame_rate			{
    my $self = shift;
    my $frame_rate = $self->{frame_rate};
    $frame_rate =~ tr/,/./;
    return $frame_rate;
}
sub bitrates			{ shift->{bitrates}			}
sub audio_tracks		{ shift->{audio_tracks}			}
sub chapters			{ shift->{chapters}			}
sub viewing_angles		{ shift->{viewing_angles}		}
sub dvd_probe_output		{ shift->{dvd_probe_output}		}
sub vob_probe_output		{ shift->{vob_probe_output}		}

sub set_width			{ shift->{width}		= $_[1]	}
sub set_height			{ shift->{height}		= $_[1]	}
sub set_aspect_ratio		{ shift->{aspect_ratio}		= $_[1]	}
sub set_video_mode		{ shift->{video_mode}		= $_[1]	}
sub set_letterboxed		{ shift->{letterboxed}		= $_[1]	}
sub set_frames			{ shift->{frames}		= $_[1]	}
sub set_runtime			{ shift->{runtime}		= $_[1]	}
sub set_frame_rate		{ shift->{frame_rate}		= $_[1]	}
sub set_bitrates		{ shift->{bitrates}		= $_[1]	}
sub set_audio_tracks		{ shift->{audio_tracks}		= $_[1]	}
sub set_chapters		{ shift->{chapters}		= $_[1]	}
sub set_viewing_angles		{ shift->{viewing_angles}	= $_[1]	}
sub set_dvd_probe_output	{ shift->{dvd_probe_output}	= $_[1]	}
sub set_vob_probe_output	{ shift->{vob_probe_output}	= $_[1]	}

#------------------------------------------------------------------------
# Some calculated attributes
#------------------------------------------------------------------------

sub nr				{ shift->{nr}				}
sub size			{ shift->{size}				}
sub audio_channel		{ shift->{audio_channel}		}
sub preset			{ shift->{preset}			}
sub last_applied_preset		{ shift->{last_applied_preset}		}
sub preview_frame_nr		{ shift->{preview_frame_nr}		}
sub files			{ shift->{files}			}
sub actual_chapter		{
	# if no actual chapter is set, this method returns the first
	# chapter, so all functions that are not aware of chapter
	# mode should do something senseful.
	# If you want to have the *real* actual chapter, use the
	# methode ->real_actual_chapter!
	my $self = shift;
	$self->{actual_chapter} ||
	$self->get_first_chapter;
}
sub real_actual_chapter		{ shift->{actual_chapter}		}
sub program_stream_units	{ shift->{program_stream_units}		}
sub bbox_min_x			{ shift->{bbox_min_x}			}
sub bbox_min_y			{ shift->{bbox_min_y}			}
sub bbox_max_x			{ shift->{bbox_max_x}			}
sub bbox_max_y			{ shift->{bbox_max_y}			}
sub chapter_frames		{ shift->{chapter_frames} ||= {}	}

sub set_nr			{ shift->{nr}			= $_[1] }
sub set_size			{ shift->{size}			= $_[1] }
sub set_audio_channel		{ shift->{audio_channel}	= $_[1] }
sub set_preset			{ shift->{preset}		= $_[1] }
sub set_last_applied_preset	{ shift->{last_applied_preset}	= $_[1]	}
sub set_preview_frame_nr	{ shift->{preview_frame_nr}	= $_[1] }
sub set_actual_chapter		{ shift->{actual_chapter}	= $_[1] }
sub set_program_stream_units	{ shift->{program_stream_units}	= $_[1] }
sub set_bbox_min_x		{ shift->{bbox_min_x}		= $_[1]	}
sub set_bbox_min_y		{ shift->{bbox_min_y}		= $_[1]	}
sub set_bbox_max_x		{ shift->{bbox_max_x}		= $_[1]	}
sub set_bbox_max_y		{ shift->{bbox_max_y}		= $_[1]	}
sub set_chapter_frames		{ shift->{chapter_frames}	= $_[1]	}

#------------------------------------------------------------------------
# These attributes must be specified by the user and are
# input parameters for the transcode process.
#------------------------------------------------------------------------

sub tc_container		{ shift->{tc_container}			}
sub tc_viewing_angle		{ shift->{tc_viewing_angle}      	}
sub tc_deinterlace		{ shift->{tc_deinterlace} || 0 		}
sub tc_anti_alias		{ shift->{tc_anti_alias}  || 0 		}
sub tc_clip1_top		{ shift->{tc_clip1_top}			}
sub tc_clip1_bottom		{ shift->{tc_clip1_bottom}		}
sub tc_clip1_left		{ shift->{tc_clip1_left}		}
sub tc_clip1_right		{ shift->{tc_clip1_right}		}
sub tc_zoom_width		{ shift->{tc_zoom_width}		}
sub tc_zoom_height		{ shift->{tc_zoom_height}		}
sub tc_clip2_top		{ shift->{tc_clip2_top}			}
sub tc_clip2_bottom		{ shift->{tc_clip2_bottom}		}
sub tc_clip2_left		{ shift->{tc_clip2_left}		}
sub tc_clip2_right		{ shift->{tc_clip2_right}		}
sub tc_video_codec		{ shift->{tc_video_codec}		}
sub tc_video_af6_codec		{ shift->{tc_video_af6_codec}		}
sub tc_video_bitrate		{ shift->{tc_video_bitrate}      	}
sub tc_video_bitrate_manual	{ shift->{tc_video_bitrate_manual}	}
sub tc_video_bpp		{ shift->{tc_video_bpp}      		}
sub tc_video_bpp_manual		{ shift->{tc_video_bpp_manual}		}
sub tc_video_bitrate_mode	{ shift->{tc_video_bitrate_mode}	}
sub tc_video_bitrate_range	{ shift->{tc_video_bitrate_range}	}
sub tc_video_framerate		{ shift->{tc_video_framerate}      	}
sub tc_fast_bisection		{ shift->{tc_fast_bisection}      	}
sub tc_psu_core			{ shift->{tc_psu_core}      		}
sub tc_keyframe_interval	{ shift->{tc_keyframe_interval}	|| 250	}
sub tc_split			{ shift->{tc_split}			}
sub tc_force_slow_grabbing	{ shift->{tc_force_slow_grabbing}	}

sub tc_target_size		{ shift->{tc_target_size}		}
sub tc_disc_cnt 	    	{ shift->{tc_disc_cnt}			}
sub tc_disc_size	    	{ shift->{tc_disc_size}			}
sub tc_start_frame	    	{ shift->{tc_start_frame}		}
sub tc_end_frame	    	{ shift->{tc_end_frame}			}
sub tc_fast_resize	    	{ shift->{tc_fast_resize}		}
sub tc_multipass	    	{ shift->{tc_multipass}			}
sub tc_multipass_reuse_log	{ shift->{tc_multipass_reuse_log}	}
sub tc_title_nr	    		{ $_[0]->{tc_title_nr} || $_[0]->{nr}	}
sub tc_use_chapter_mode    	{ shift->{tc_use_chapter_mode} || 0	}
sub tc_selected_chapters	{ shift->{tc_selected_chapters}		}
sub tc_options			{ shift->{tc_options}			}
sub tc_nice			{ shift->{tc_nice}			}
sub tc_preview			{ shift->{tc_preview}			}
sub tc_execute_afterwards	{ shift->{tc_execute_afterwards}	}
sub tc_exit_afterwards		{ shift->{tc_exit_afterwards}		}

sub set_tc_viewing_angle	{ shift->{tc_viewing_angle}	= $_[1]	}
sub set_tc_deinterlace		{ shift->{tc_deinterlace}	= $_[1]	}
sub set_tc_anti_alias		{ shift->{tc_anti_alias}	= $_[1]	}
# implemented below : sub set_tc_clip1_top {}
# implemented below : sub set_tc_clip1_bottom {}
# implemented below : sub set_tc_clip1_left {}
# implemented below : sub set_tc_clip1_right {}
# implemented below : sub set_tc_zoom_width {}
# implemented below : sub set_tc_zoom_height {}
# implemented below : sub set_tc_clip2_top {}
# implemented below : sub set_tc_clip2_bottom {}
# implemented below : sub set_tc_clip2_left {}
# implemented below : sub set_tc_clip2_right {}
# implemented below : sub set_tc_video_codec {}
# implemented below : sub set_tc_video_af6_codec {}
sub set_tc_video_bitrate	{ shift->{tc_video_bitrate}  	= $_[1]	}
# implemented below : sub set_tc_video_bitrate_manual {}
sub set_tc_video_bpp		{ shift->{tc_video_bpp}  	= $_[1]	}
# implemented below : sub set_tc_video_bpp_manual {}
# implemented below : sub set_tc_video_bitrate_mode {}
# implemented below : sub set_tc_video_bitrate_range {}
sub set_tc_video_framerate	{ shift->{tc_video_framerate} 	= $_[1]	}
sub set_tc_fast_bisection	{ shift->{tc_fast_bisection} 	= $_[1]	}
sub set_tc_psu_core		{ shift->{tc_psu_core} 		= $_[1]	}
sub set_tc_keyframe_interval	{ shift->{tc_keyframe_interval}	= $_[1]	}
sub set_tc_split		{ shift->{tc_split}		= $_[1]	}
sub set_tc_force_slow_grabbing	{ shift->{tc_force_slow_grabbing}= $_[1]}

# implemented below : sub set_tc_disc_cnt
# implemented below : sub set_tc_disc_size
# implemented below : sub set_tc_target_size
# implemented below : sub set_tc_start_frame
# implemented below : sub set_tc_end_frame
sub set_tc_fast_resize		{ shift->{tc_fast_resize}    	= $_[1]	}
sub set_tc_multipass		{ shift->{tc_multipass}    	= $_[1]	}
sub set_tc_multipass_reuse_log	{ shift->{tc_multipass_reuse_log}= $_[1]}
sub set_tc_title_nr	    	{ shift->{tc_title_nr}    	= $_[1]	}
sub set_tc_use_chapter_mode 	{ shift->{tc_use_chapter_mode}	= $_[1] }
sub set_tc_selected_chapters	{ shift->{tc_selected_chapters}	= $_[1] }
sub set_tc_options		{ shift->{tc_options}		= $_[1] }
sub set_tc_nice			{ shift->{tc_nice}		= $_[1] }
sub set_tc_preview		{ shift->{tc_preview}		= $_[1] }
sub set_tc_execute_afterwards	{ shift->{tc_execute_afterwards}= $_[1]	}
sub set_tc_exit_afterwards	{ shift->{tc_exit_afterwards}	= $_[1]	}

#-- Attributes for storage ----------------------------------------------

sub storage_video_size      	{ shift->{storage_video_size}	    	}
sub storage_audio_size      	{ shift->{storage_audio_size}	    	}
sub storage_other_size      	{ shift->{storage_other_size}	    	}
sub storage_total_size      	{ shift->{storage_total_size}	    	}

sub set_storage_video_size	{ shift->{storage_video_size}	= $_[1]	}
sub set_storage_audio_size	{ shift->{storage_audio_size}	= $_[1]	}
sub set_storage_other_size	{ shift->{storage_other_size}	= $_[1]	}
sub set_storage_total_size	{ shift->{storage_total_size}	= $_[1]	}

sub bitrate_calc		{ shift->{bitrate_calc}			}
sub set_bitrate_calc		{ shift->{bitrate_calc}		= $_[1]	}

#-- Attributes for CD burning -------------------------------------------

sub burn_cd_type		{ shift->{burn_cd_type} || 'iso'	}
sub burn_label			{ shift->{burn_label}			}
sub burn_abstract		{ shift->{burn_abstract}		}
sub burn_number			{ shift->{burn_number}			}
sub burn_abstract_sticky	{ shift->{burn_abstract_sticky}		}
sub burn_files_selected		{ shift->{burn_files_selected}		}

sub set_burn_cd_type		{ shift->{burn_cd_type}		= $_[1]	}
sub set_burn_label		{ shift->{burn_label}		= $_[1]	}
sub set_burn_abstract		{ shift->{burn_abstract}	= $_[1]	}
sub set_burn_number		{ shift->{burn_number}		= $_[1]	}
sub set_burn_abstract_sticky	{ shift->{burn_abstract_sticky}	= $_[1]	}
sub set_burn_files_selected	{ shift->{burn_files_selected}	= $_[1]	}

#-- Attributes for subtitles --------------------------------------------

sub subtitles			{ shift->{subtitles}			}
sub selected_subtitle_id	{ shift->{selected_subtitle_id}		}
sub subtitle_test		{ shift->{subtitle_test}		}
sub tc_rip_subtitle_mode	{ shift->{tc_rip_subtitle_mode}		}
sub tc_rip_subtitle_lang	{ shift->{tc_rip_subtitle_lang}		}

sub set_subtitles		{ shift->{subtitles}		= $_[1]	}
sub set_selected_subtitle_id	{ shift->{selected_subtitle_id}	= $_[1]	}
sub set_subtitle_test		{ shift->{subtitle_test}	= $_[1]	}
sub set_tc_rip_subtitle_mode	{ shift->{tc_rip_subtitle_mode}	= $_[1]	}
sub set_tc_rip_subtitle_lang    { shift->{tc_rip_subtitle_lang}	= $_[1]	}

#-- Filter Settings -----------------------------------------------------

sub tc_filter_settings {
    my $self = shift;
    if ( not $self->{tc_filter_settings} ) {
        return $self->{tc_filter_settings}
            = Video::DVDRip::FilterSettings->new;
    }
    return $self->{tc_filter_settings};
}

sub tc_filter_setting_id        { shift->{tc_filter_setting_id}         }
sub set_tc_filter_setting_id    { shift->{tc_filter_setting_id} = $_[1] }

sub tc_selected_filter_setting {
    my $self = shift;
    return if not $self->tc_filter_setting_id;
    return $self->tc_filter_settings->get_filter_instance(
        id => $self->tc_filter_setting_id );
}

sub tc_preview_start_frame      { shift->{tc_preview_start_frame}       }
sub tc_preview_end_frame        { shift->{tc_preview_end_frame}         }
sub tc_preview_buffer_frames    { shift->{tc_preview_buffer_frames}||20 }

sub set_tc_preview_start_frame  { shift->{tc_preview_start_frame}   = $_[1] }
sub set_tc_preview_end_frame    { shift->{tc_preview_end_frame}     = $_[1] }
sub set_tc_preview_buffer_frames{ shift->{tc_preview_buffer_frames} = $_[1] }

sub tc_use_yuv_internal {
    my $self = shift;

    # enabled only if all selected filters support YUV
    # and we have no odd clipping / resizing

    return 0
        if $self->tc_clip1_left % 2
        or $self->tc_clip1_right % 2
        or $self->tc_clip1_top % 2
        or $self->tc_clip1_bottom % 2
        or $self->tc_clip2_left % 2
        or $self->tc_clip2_right % 2
        or $self->tc_clip2_top % 2
        or $self->tc_clip2_bottom % 2
        or $self->tc_zoom_width % 2
        or $self->tc_zoom_height % 2;

    foreach my $filter_instance ( @{ $self->tc_filter_settings->filters } ) {
        return 0
            if $filter_instance->get_filter->can_video
            and not $filter_instance->get_filter->can_yuv;
    }

    return 1;
}

#-- Constructor ---------------------------------------------------------

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $nr, $project ) = @par{ 'nr', 'project' };

    my $default_subtitle_grab = $class->config('default_subtitle_grab');

    my $self = {
        project              => $project,
        nr                   => $nr,
        size                 => 0,
        files                => [],
        audio_channel        => 0,
        scan_result          => undef,
        tc_clip1_top         => 0,
        tc_clip1_bottom      => 0,
        tc_clip1_left        => 0,
        tc_clip1_right       => 0,
        tc_clip2_top         => 0,
        tc_clip2_bottom      => 0,
        tc_clip2_left        => 0,
        tc_clip2_right       => 0,
        tc_rip_subtitle_mode => $default_subtitle_grab,
        tc_selected_chapters => [],
        tc_preview_buffer_frames => 20,
        program_stream_units => [],
        chapter_frames       => {},
        tc_filter_settings   => Video::DVDRip::FilterSettings->new,
    };

    return bless $self, $class;
}

sub set_tc_video_codec {
    my $self = shift;
    my ($value) = @_;

    $self->{tc_video_codec} = $value;

    $self->set_tc_video_af6_codec('mpeg4') if $value eq 'ffmpeg';
    $self->set_tc_video_af6_codec('') if $value ne 'ffmpeg';

    if ( $value eq 'VCD' ) {
        $self->audio_track->set_tc_bitrate(224);
        $self->audio_track->set_tc_audio_codec('mp2');
        $self->set_tc_multipass(0);
        $self->set_tc_video_bitrate_manual(1152);
        $self->set_tc_video_bitrate_mode("manual");

    }
    elsif ( $value =~ /^(X?S?VCD|CVD)$/ ) {
        $self->audio_track->set_tc_audio_codec('mp2');
        $self->set_tc_multipass(0);
    }

    if ( $value =~ /^X?S?VCD$/ ) {
        foreach my $audio ( @{ $self->audio_tracks } ) {
            $audio->set_tc_mp2_samplerate(44100);
        }
    }

    return $value;
}

sub set_tc_video_af6_codec {
    my $self = shift;
    my ($value) = @_;

    $self->{tc_video_af6_codec} = $value;

#    $self->set_tc_multipass(0) if $value eq 'h264';

    return $value;
}

#-- get actually selected audio (or a dummy object, if no track is selected)

sub audio_track {
    my $self = shift;
    if ( $self->audio_channel == -1 ) {
        # no audio track selected. create a dummy object.
        # (probably this title has no audio at all)
        return Video::DVDRip::Audio->new( title => $self );
    }
    return $self->audio_tracks->[ $self->audio_channel ];
}

sub has_target_audio_tracks {
    my $self = shift;
    
    foreach my $audio ( @{ $self->audio_tracks } ) {
        return 1 if $audio->tc_target_track != -1;
    }
    
    return 0;
}

sub set_tc_container {
    my $self = shift;
    my ($container) = @_;

    return $container if $container eq $self->tc_container;

    $self->{tc_container} = $container;

    return if not defined $self->audio_tracks;

    my @messages;

    if ( $container eq 'avi' ) {

        # no vorbis and mp2 audio here
        foreach my $audio ( @{ $self->audio_tracks } ) {
            next if $audio->tc_target_track == -1;
            if ( $audio->tc_audio_codec eq 'vorbis' ) {
                push @messages,
                    __x(
                    "Set codec of audio track #{nr} to 'mp3', "
                        . "'vorbis' not supported by AVI container",
                    nr => $audio->tc_nr
                    );
                $audio->set_tc_audio_codec('mp3');
            }
            elsif ( $audio->tc_audio_codec eq 'mp2' ) {
                push @messages,
                    __x(
                    "Set codec of audio track #{nr} to 'mp3', "
                        . "'mp2' not supported by AVI container",
                    nr => $audio->tc_nr
                    );
                $audio->set_tc_audio_codec('mp3');
            }
        }

        # no (S)VCD here
        if ( $self->tc_video_codec =~ /^(X?S?VCD|CVD)$/ ) {
            push @messages,
                __ "Set video codec to 'xvid', '"
                . $self->tc_video_codec
                . __ "' not supported by AVI container";
            $self->set_tc_video_codec("xvid");
        }

    }
    elsif ( $container eq 'vcd' ) {

        # only mp2 audio here
        foreach my $audio ( @{ $self->audio_tracks } ) {
            next if $audio->tc_target_track == -1;
            if ( $audio->tc_audio_codec ne 'mp2' ) {
                push @messages,
                    __x( "Set codec of audio track #{nr} to 'mp2', '",
                    nr => $audio->tc_nr )
                    . $audio->tc_audio_codec
                    . __ "' not supported by MPEG container";
                $audio->set_tc_audio_codec('mp2');
            }
        }

        # only (S)VCD here
        if ( $self->tc_video_codec !~ /^(X?S?VCD|CVD)$/ ) {
            push @messages,
                __ "Set video codec to 'SVCD', '"
                . $self->tc_video_codec
                . __ "' not supported by MPEG container";
            $self->set_tc_video_codec("SVCD");
        }

    }
    elsif ( $container eq 'ogg' ) {

        # no mp2 and pcm audio here
        foreach my $audio ( @{ $self->audio_tracks } ) {
            next if $audio->tc_target_track == -1;
            if (   $audio->tc_audio_codec eq 'mp2'
                or $audio->tc_audio_codec eq 'pcm' ) {
                push @messages,
                    __x( "Set codec of audio track #{nr} to 'vorbis', '",
                    nr => $audio->tc_nr )
                    . $audio->tc_audio_codec
                    . __ "' not supported by OGG container";
                $audio->set_tc_audio_codec('vorbis');
            }
        }

        # no (S)VCD here
        if ( $self->tc_video_codec =~ /^(X?S?VCD|CVD)$/ ) {
            $self->set_tc_video_codec("xvid");
            push @messages, __
                "Set video codec to 'xvid', MPEG not supported by OGG container";
        }
    }

    foreach my $msg (@messages) {
        $self->log($msg);
    }

    $self->calc_video_bitrate;

    return $container;
}

sub set_tc_disc_cnt {
    my $self = shift;
    my ($cnt) = @_;
    $self->{tc_disc_cnt} = $cnt;
    $self->set_tc_target_size( $cnt * $self->tc_disc_size );
    return $cnt;
}

sub set_tc_disc_size {
    my $self = shift;
    my ($size) = @_;
    $self->{tc_disc_size} = $size;
    $self->set_tc_target_size( $self->tc_disc_cnt * $size );
    return $size;
}

sub set_tc_target_size {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_target_size} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_video_bitrate_manual {
    my $self = shift;
    my ($size) = @_;
    $self->{tc_video_bitrate_manual} = $size;
    $self->calc_video_bitrate;
    return $size;
}

sub set_tc_video_bpp_manual {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_video_bpp_manual} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_video_bitrate_mode {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_video_bitrate_mode} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_video_bitrate_range {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_video_bitrate_range} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_start_frame {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_start_frame} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_end_frame {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_end_frame} = $value;
    $self->calc_video_bitrate;
    return $value;
}

#---------------------

sub set_tc_clip1_top {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip1_top} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_clip1_bottom {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip1_bottom} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_clip1_left {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip1_left} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_clip1_right {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip1_right} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_zoom_width {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_zoom_width} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_zoom_height {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_zoom_height} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_clip2_top {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip2_top} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_clip2_bottom {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip2_bottom} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_clip2_left {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip2_left} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub set_tc_clip2_right {
    my $self = shift;
    my ($value) = @_;
    $self->{tc_clip2_right} = $value;
    $self->calc_video_bitrate;
    return $value;
}

sub is_ogg {
    my $self = shift;
    return $self->tc_container eq 'ogg';
}

sub is_mpeg {
    my $self = shift;
    return $self->tc_container eq 'vcd';
}

sub is_resized {
    my $self = shift;
    
    my $clip_size = $self->preview_label(type => "clip1", size_only => 1);
    my $zoom_size = $self->preview_label(type => "zoom",  size_only => 1);
    
    return $clip_size ne $zoom_size;
}

sub has_vbr_audio {
    my $self = shift;

    return 0 if $self->tc_video_bitrate_mode eq 'manual';

    foreach my $audio ( @{ $self->audio_tracks } ) {
        next if $audio->tc_target_track == -1;
        return 1 if $audio->tc_audio_codec eq 'vorbis';
    }

    return 0;
}

sub vob_dir {
    my $self = shift;

    my $vob_dir;

    if ( $self->tc_use_chapter_mode ) {
        $vob_dir = sprintf( "%s/%03d-C%03d/",
            $self->project->vob_dir, $self->nr,
            ( $self->actual_chapter || $self->get_first_chapter || 1 ) );

    }
    else {
        $vob_dir = sprintf( "%s/%03d/", $self->project->vob_dir, $self->nr );
    }

    return $vob_dir;
}

sub get_vob_size {
    my $self = shift;

    return 1 if $self->project->rip_mode ne 'rip';

    my $vob_dir = $self->vob_dir;

    my $vob_size = 0;
    $vob_size += -s for <$vob_dir/*>;
    $vob_size = int( $vob_size / 1024 / 1024 );

    return $vob_size;
}

sub get_title_info {
    my $self = shift;

    my $fps = $self->frame_rate;
    $fps =~ s/\.0+$//;

    my $length = $self->runtime - 1;
    my $h      = int( $length / 3600 );
    my $m      = int( ( $length - $h * 3600 ) / 60 );
    my $s      = $length - $h * 3600 - $m * 60;

    $length = sprintf( "%02d:%02d:%02d", $h, $m, $s );

    return $length . ", "
        . uc( $self->video_mode ) . ", "
        . $self->chapters . " "
        . __("Chp") . ", "
        . scalar( @{ $self->audio_tracks } ) . " "
        . __("Aud") . ", "
        . "$fps fps, "
        . $self->aspect_ratio . ", "
        . $self->frames . " "
        . __("frames") . ", "
        . $self->width . "x"
        . $self->height

}

sub transcode_data_source {
    my $self = shift;

    my $project = $self->project;
    my $mode    = $project->rip_mode;

    my $source;

    if ( $mode eq 'rip' ) {
        $source = $self->vob_dir;

    }
    else {
        $source = $project->rip_data_source;

    }

    return quotemeta($source);
}

sub data_source_options {
    my $self = shift;
    my %par = @_;
    my ($audio_channel) = @par{'audio_channel'};

    $audio_channel = $self->audio_channel
        if not defined $audio_channel;

    my $mode   = $self->project->rip_mode;
    my $source = $self->transcode_data_source;

    my ( $input_filter, $need_title );

    if ( $mode eq 'rip' ) {
        $input_filter = "vob";
        $need_title   = 0;

    }
    else {
        $input_filter = "dvd";
        $need_title   = 1;

    }

    $input_filter .= ",null" if $audio_channel == -1;

    my %options = (
        i => $source,
        x => $input_filter
    );

    if ($need_title) {
        my $chapter = $self->actual_chapter || -1;
        $options{T} = $self->nr . ",$chapter," . $self->tc_viewing_angle;
    }

    return \%options;
}

sub create_vob_dir {
    my $self = shift;

    my $vob_dir = $self->vob_dir;

    if ( not -d $vob_dir ) {
        mkpath( [$vob_dir], 0, 0755 )
            or croak __x( "Can't mkpath directory '{dir}'", dir => $vob_dir );
    }

    1;
}

sub avi_dir {
    my $self = shift;

    return sprintf( "%s/%03d", $self->project->avi_dir, $self->nr, );
}

sub get_target_ext {
    my $self = shift;

    my $video_codec = $self->tc_video_codec;
    my $ext         = ( $video_codec =~ /^(X?S?VCD|CVD)$/ ) ? "" : ".avi";

    $ext = "." . $self->config('ogg_file_ext') if $self->is_ogg;

    return $ext;
}

sub avi_file {
    my $self = shift;

    my $ext = $self->get_target_ext;

    my $target_dir =
          $self->subtitle_test
        ? $self->get_subtitle_preview_dir
        : $self->avi_dir;

    if ( $self->tc_use_chapter_mode ) {
        return sprintf(
            "%s/%s-%03d-C%03d$ext",
            $target_dir, $self->project->name,
            $self->nr,   $self->actual_chapter
        );
    }
    else {
        return sprintf( "%s/%s-%03d$ext",
            $target_dir, $self->project->name, $self->nr );
    }
}

sub target_avi_file {
    my $self = shift;
    return $self->avi_file;
}

sub target_avi_audio_file {
    my $self = shift;
    my %par  = @_;
    my ( $vob_nr, $avi_nr ) = @par{ 'vob_nr', 'avi_nr' };

    my $ext = $self->is_ogg ? "." . $self->config('ogg_file_ext') : '.avi';
    $ext = "" if $self->tc_container eq 'vcd';

    my $audio_file = $self->target_avi_file;
    $audio_file =~ s/\.[^.]+$//;
    $audio_file = sprintf( "%s-%02d$ext", $audio_file, $avi_nr );

    return $audio_file;
}

sub multipass_log_dir {
    my $self = shift;
    return dirname( $self->preview_filename );
}

sub create_avi_dir {
    my $self = shift;

    my $avi_dir = dirname $self->avi_file;

    if ( not -d $avi_dir ) {
        mkpath( [$avi_dir], 0, 0755 )
            or croak __x( "Can't mkpath directory '{dir}'", dir => $avi_dir );
    }

    1;
}

sub preview_filename {
    my $self = shift;
    my %par = @_;
    my ($type) = @par{'type'};

    return sprintf( "%s/%s-%03d-preview-%s.jpg",
        $self->project->snap_dir, $self->project->name, $self->nr, $type );
}

sub preview_filename_orig {
    shift->preview_filename( type => "orig" );
}

sub preview_filename_clip1 {
    shift->preview_filename( type => "clip1" );
}

sub preview_filename_zoom {
    shift->preview_filename( type => "zoom" );
}

sub preview_filename_clip2 {
    shift->preview_filename( type => "clip2" );
}

sub preview_scratch_filename {
    my $self = shift;
    my %par = @_;
    my ($type) = @par{'type'};

    return sprintf( "%s/%s-%03d-preview-scratch-%s.jpg",
        $self->project->snap_dir, $self->project->name, $self->nr, $type );
}

sub preview_label {
    my $self = shift;
    my %par = @_;
    my ($type, $details, $size_only) = @par{'type','details','size_only'};

    my ( $width, $height, $warn_width, $warn_height, $text, $ratio,
        $phys_ratio );
    ( $width, $height, $ratio ) = $self->get_effective_ratio( type => $type );

    $ratio = "4:3"  if $ratio >= 1.32 and $ratio <= 1.34;
    $ratio = "16:9" if $ratio >= 1.76 and $ratio <= 1.78;

    ($ratio) = $ratio =~ /(\d+[.,]\d{1,2})/ if $ratio !~ /:/;

    $phys_ratio = $width / $height;
    ($phys_ratio) = $phys_ratio =~ /(\d+[.,]\d{1,2})/;

    $warn_width  = ( $type eq 'clip2' and $width % 16 )  ? "!16" : "";
    $warn_height = ( $type eq 'clip2' and $height % 16 ) ? "!16" : "";

    $warn_width  ||= ( $width % 2 )  ? "!2" : "";
    $warn_height ||= ( $height % 2 ) ? "!2" : "";

    if ( $type eq 'clip1' ) {
        $warn_height ||= "!"
            if $self->tc_clip1_top % 2
            or $self->tc_clip1_bottom % 2;
        $warn_width ||= "!"
            if $self->tc_clip1_left % 2
            or $self->tc_clip1_right % 2;
    }

    if ( $type eq 'clip2' ) {
        $warn_height ||= "!"
            if $self->tc_clip2_top % 2
            or $self->tc_clip2_bottom % 2;
        $warn_width ||= "!"
            if $self->tc_clip2_left % 2
            or $self->tc_clip2_right % 2;
    }

    if ( $details ) {
        my @status;
        if ( $warn_width =~ /2/ ) {
            push @status, __"Width isn't even.";
        }
        elsif ( $warn_width =~ /16/ ) {
            push @status, __"Width is not divisible by 16.";
        }
        if ( $warn_height =~ /2/ ) {
            push @status, __"Height isn't even.";
        }
        elsif ( $warn_height =~ /16/ ) {
            push @status, __"Height is not divisible by 16.";
        }
        $text = join (" ", @status);
        if ( $text ) {
            $text = qq[<span foreground="red"><b>$text</b></span>];
        }
        else {
            $text = qq[<span foreground="#007700"><b>].
                    __("Settings Ok").
                    qq[</b></span>];
        }
    }
    else {
        my $type_text =
              $type eq 'clip1' ? __ "After 1st clipping"
            : $type eq 'clip2' ? __ "After 2nd clipping"
            : __ "After zoom";

        $text = sprintf(
            "<u>$type_text</u>: <b>%d%sx%d%s</b>\n"
                . __x(
                "Eff. ratio: <b>{eff}</b>, phys. ratio: <b>{phys}</b>",
                eff  => $ratio,
                phys => $phys_ratio
                ),
            $width,
            qq[<span foreground="red">$warn_width</span>],
            $height,
            qq[<span foreground="red">$warn_height</span>],
        );
    }

    return "${width}x${height}" if $size_only;
    return $text;
}

sub preview_label_clip1 {
    shift->preview_label( type => "clip1" );
}

sub preview_label_zoom {
    shift->preview_label( type => "zoom" );
}

sub preview_label_clip2 {
    shift->preview_label( type => "clip2" );
}

sub vob_nav_file {
    my $self = shift;

    my $file;
    if ( $self->tc_use_chapter_mode ) {
        $file = sprintf( "%s/%s-%03d-C%03d-nav.log",
            $self->project->snap_dir, $self->project->name, $self->nr,
            $self->actual_chapter );
    }
    else {
        $file = sprintf( "%s/%s-%03d-nav.log",
            $self->project->snap_dir, $self->project->name, $self->nr );
    }

    return $file;
}

sub has_vob_nav_file {
    my $self = shift;

    my $old_chapter = $self->actual_chapter;

    $self->set_actual_chapter( $self->get_first_chapter )
        if $self->tc_use_chapter_mode;

    my $vob_nav_file = $self->vob_nav_file;

    $self->set_actual_chapter($old_chapter)
        if $self->tc_use_chapter_mode;

    return -f $vob_nav_file;
}

sub audio_wav_file {
    my $self = shift;

    my $chap;
    if ( $self->actual_chapter ) {
        $chap = sprintf( "-C%02d", $self->actual_chapter );
    }

    return sprintf(
        "%s/%s-%03d-%02d$chap.wav",
        $self->avi_dir, $self->project->name,
        $self->nr,      $self->audio_track->tc_nr,
    );
}

sub add_vob {
    my $self = shift;
    my %par = @_;
    my ($file) = @par{'file'};

    $self->set_size( $self->size + ( -s $file ) );
    push @{ $self->files }, $file;

    1;
}

sub apply_preset {
    my $self     = shift;
    my %par      = @_;
    my ($preset) = @par{'preset'};

    $preset ||= $self->config_object->get_preset( name => $self->preset );

    return 1 if not $preset;

    $self->set_last_applied_preset( $preset->name );

    if ( $preset->auto_clip ) {
        $self->auto_adjust_clip_only;
    }
    elsif ( $preset->auto ) {
        $self->auto_adjust_clip_zoom(
            frame_size  => $preset->frame_size,
            fast_resize => $preset->tc_fast_resize,
        );
    }
    else {
        my $attributes = $preset->attributes;
        my $set_method;
        foreach my $attr ( @{$attributes} ) {
            $set_method = "set_$attr";
            $self->$set_method( $preset->$attr() );
        }
    }
    
    1;
}

sub get_chapters {
    my $self = shift;

    my @chapters;
    if ( $self->tc_use_chapter_mode eq 'select' ) {
        @chapters = sort { $a <=> $b } @{ $self->tc_selected_chapters || [] };
    }
    else {
        @chapters = ( 1 .. $self->chapters );
    }

    return \@chapters;
}

sub get_first_chapter {
    my $self = shift;

    my $chapter_mode = $self->tc_use_chapter_mode;
    return if not $chapter_mode;

    if ( $chapter_mode eq 'select' ) {
        my $chapters = $self->get_chapters;
        return $chapters->[0];
    }
    else {
        return 1;
    }
}

sub get_last_chapter {
    my $self = shift;

    my $chapter_mode = $self->tc_use_chapter_mode;
    return if not $chapter_mode;

    my $chapters = $self->get_chapters;
    return $chapters->[ @{$chapters} - 1 ];
}

sub calc_program_stream_units {
    my $self = shift;

    my $vob_nav_file = $self->vob_nav_file;

    my $fh = FileHandle->new;
    open( $fh, $vob_nav_file )
        or croak __x( "Can't read VOB navigation file '{filename}'",
        filename => $vob_nav_file );

    my $current_unit = 0;
    my ( @program_stream_units, $unit, $frame, $last_frame );

    while (<$fh>) {
        ( $unit, $frame ) = /(\d+)\s+(\d+)/;
        if ( $unit != $current_unit ) {
            push @program_stream_units,
                Video::DVDRip::PSU->new(
                nr     => $current_unit,
                frames => $last_frame,
                );
            $current_unit = $unit;
        }
        $last_frame = $frame;
    }

    if ( $last_frame != 0 ) {
        push @program_stream_units,
            Video::DVDRip::PSU->new(
            nr     => $current_unit,
            frames => $last_frame,
            );
    }

    close $fh;

    $self->set_program_stream_units( \@program_stream_units );

    $self->log( __ "Program stream units calculated" );

    1;
}

sub get_effective_ratio {
    my $self   = shift;
    my %par    = @_;
    my ($type) = @par{'type'};    # clip1, zoom, clip2

    my $width       = $self->width;
    my $height      = $self->height || 1;
    my $clip1_ratio = $width / $height;

    my $from_width  = $width - $self->tc_clip1_left - $self->tc_clip1_right;
    my $from_height = $height - $self->tc_clip1_top - $self->tc_clip1_bottom;

    return ( $from_width, $from_height, $clip1_ratio ) if $type eq 'clip1';

    my $zoom_width  = $self->tc_zoom_width  || $from_width;
    my $zoom_height = $self->tc_zoom_height || $from_height;
    my $zoom_ratio = ( $zoom_width / $zoom_height ) * ( $width / $height )
        / ( $from_width / $from_height );

    return ( $zoom_width, $zoom_height, $zoom_ratio ) if $type eq 'zoom';

    my $clip2_width
        = $zoom_width - $self->tc_clip2_left - $self->tc_clip2_right;
    my $clip2_height
        = $zoom_height - $self->tc_clip2_top - $self->tc_clip2_bottom;

    return ( $clip2_width, $clip2_height, $zoom_ratio );
}

sub calc_export_par {
    my $self = shift;

    my $width  = $self->width;
    my $height = $self->height;

    my $source_aspect = $width/$height;
    my $target_aspect = $self->aspect_ratio;

    my ($w, $h) = split(":", $target_aspect);
    $target_aspect = $w/$h;
    
    return sprintf("%d,100", 100 * $target_aspect / $source_aspect);
}

sub auto_adjust_clip_only {
    my $self = shift;

    $self->set_tc_fast_resize(1);

    my $result = $self->get_zoom_parameters(
        target_width        => undef,
        target_height       => undef,
        fast_resize_align   => 16,
        result_align        => 16,
        result_align_clip2  => 1,
        auto_clip           => 1,
        use_clip1           => 0,
    );

    $self->set_tc_zoom_width( undef );
    $self->set_tc_zoom_height( undef );
    $self->set_tc_clip1_left( 0 );
    $self->set_tc_clip1_right( 0 );
    $self->set_tc_clip1_top( 0 );
    $self->set_tc_clip1_bottom( 0 );
    $self->set_tc_clip2_left( $result->{clip2_left} );
    $self->set_tc_clip2_right( $result->{clip2_right} );
    $self->set_tc_clip2_top( $result->{clip2_top} );
    $self->set_tc_clip2_bottom( $result->{clip2_bottom} );

    1;
}

sub auto_adjust_clip_zoom {
    my $self = shift;
    my %par  = @_;
    my ( $frame_size, $fast_resize ) = @par{ 'frame_size', 'fast_resize' };

    croak __x( "invalid parameter for frame_size ('{frame_size}')",
        frame_size => $frame_size )
        if not $frame_size =~ /^(big|medium|small)$/;

    my %width_presets;
    if ($fast_resize) {
        %width_presets = (
            small  => 496,
            medium => 640,
            big    => 720,
        );
    }
    else {
        %width_presets = (
            small  => 496,
            medium => 640,
            big    => 768,
        );
    }

    $self->set_tc_fast_resize($fast_resize);

    my $results = $self->calculator;

    my $target_width = $width_presets{$frame_size};

    my %result_by_ar_err;
    my $range = 16;
    while ( keys(%result_by_ar_err) == 0 and $range < 1024 ) {
        foreach my $result ( @{$results} ) {
            next if abs( $target_width - $result->{clip2_width} ) > $range;
            $result_by_ar_err{ abs( $result->{ar_err} ) }
                ->{ abs( $target_width - $result->{clip2_width} ) } = $result;
        }
        $range += 16;
    }

    my ($min_err) = sort { $a <=> $b } keys %result_by_ar_err;
    my ($min_width_diff)
        = sort { $a <=> $b } keys %{ $result_by_ar_err{$min_err} };
    my $result = $result_by_ar_err{$min_err}->{$min_width_diff};

    $self->set_tc_zoom_width( $result->{zoom_width} );
    $self->set_tc_zoom_height( $result->{zoom_height} );
    $self->set_tc_clip1_left( $result->{clip1_left} );
    $self->set_tc_clip1_right( $result->{clip1_right} );
    $self->set_tc_clip1_top( $result->{clip1_top} );
    $self->set_tc_clip1_bottom( $result->{clip1_bottom} );
    $self->set_tc_clip2_left( $result->{clip2_left} );
    $self->set_tc_clip2_right( $result->{clip2_right} );
    $self->set_tc_clip2_top( $result->{clip2_top} );
    $self->set_tc_clip2_bottom( $result->{clip2_bottom} );

    1;
}

sub calc_zoom {
    my $self = shift;
    my %par  = @_;
    my ( $width, $height ) = @par{ 'width', 'height' };

    my $result = $self->get_zoom_parameters(
        target_width  => ( $height ? $self->tc_zoom_width  : undef ),
        target_height => ( $width  ? $self->tc_zoom_height : undef ),
        fast_resize_align => ( $self->tc_fast_resize ? 8 : 0 ),
        result_align => 16,
        result_align_clip2 => 1,
        auto_clip          => 0,
        use_clip1          => 1,
    );

    $self->set_tc_zoom_width( $result->{zoom_width} );
    $self->set_tc_zoom_height( $result->{zoom_height} );
    $self->set_tc_clip1_left( $result->{clip1_left} );
    $self->set_tc_clip1_right( $result->{clip1_right} );
    $self->set_tc_clip1_top( $result->{clip1_top} );
    $self->set_tc_clip1_bottom( $result->{clip1_bottom} );
    $self->set_tc_clip2_left( $result->{clip2_left} );
    $self->set_tc_clip2_right( $result->{clip2_right} );
    $self->set_tc_clip2_top( $result->{clip2_top} );
    $self->set_tc_clip2_bottom( $result->{clip2_bottom} );

    1;
}

sub calculator {
    my $self = shift;
    my %par  = @_;
    my ( $fast_resize_align, $result_align, $result_align_clip2 )
        = @par{ 'fast_resize_align', 'result_align', 'result_align_clip2' };
    my ( $auto_clip, $use_clip1, $video_bitrate )
        = @par{ 'auto_clip', 'use_clip1', 'video_bitrate' };

    $fast_resize_align = $self->tc_fast_resize * 8
        if not defined $fast_resize_align;
    $result_align       = 16 if not defined $result_align;
    $result_align_clip2 = 1  if not defined $result_align_clip2;
    $auto_clip          = 1  if not defined $auto_clip;
    $use_clip1          = 0  if not defined $use_clip1;

    my ( $width, $height ) = ( $self->width, $self->height );

    my @result;
    my $last_result;
    my ( $actual_width, $actual_height, $best_result );

    for ( my $i = 0;; ++$i ) {
        my $result = $self->get_zoom_parameters(
            step               => $i,
            step_size          => 1,
            auto_clip          => $auto_clip,
            use_clip1          => $use_clip1,
            fast_resize_align  => $fast_resize_align,
            result_align       => $result_align,
            result_align_clip2 => $result_align_clip2,
            video_bitrate      => $video_bitrate,
        );

        last if $result->{clip2_width} < 200;
        next if $result->{ar_err} > 1;
        next
            if $fast_resize_align
            and ( ( $result->{clip1_width} > $result->{zoom_width} )
            xor( $result->{clip1_height} > $result->{zoom_height} ) );

        if ($i != 0
            and (  $actual_width != $result->{clip2_width}
                or $actual_height != $result->{clip2_height} )
            ) {
            push @result, $best_result;
            $best_result = undef;
        }

        if ( not $best_result
            or $best_result->{ar_err} > $result->{ar_err} ) {
            $best_result = $result;
        }

        $actual_width  = $result->{clip2_width};
        $actual_height = $result->{clip2_height};
    }

    push @result, $best_result if $best_result;

    return \@result;
}

sub get_zoom_parameters {
    my $self = shift;
    my %par = @_;
    my  ($target_width, $target_height, $fast_resize_align) =
    @par{'target_width','target_height','fast_resize_align'};
    my  ($result_align, $result_align_clip2, $auto_clip, $step) =
    @par{'result_align','result_align_clip2','auto_clip','step'};
    my  ($step_size, $use_clip1, $video_bitrate) =
    @par{'step_size','use_clip1','video_bitrate'};

    #use Data::Dumper; print Dumper(\%par);

    my ( $clip1_top, $clip1_bottom, $clip1_left, $clip1_right );
    my ( $clip_top,  $clip_bottom,  $clip_left,  $clip_right );

    my ( $width, $height ) = ( $self->width, $self->height );
    $height ||= 1;
    my $ar = $self->aspect_ratio eq '16:9' ? 16 / 9 : 4 / 3;
    my $ar_width_factor = $ar / ( $width / $height );
    my $zoom_align = $fast_resize_align ? $fast_resize_align : 2;
    $zoom_align ||= $result_align if not $result_align_clip2;
    $use_clip1 = 1 if not $auto_clip;
    $video_bitrate ||= $self->tc_video_bitrate;

    #print "width=$width height=$height\n";

    # clip image
    if ($auto_clip) {
        $clip_top = $self->bbox_min_y || 0;
        $clip_bottom
            = defined $self->bbox_max_y ? $height - $self->bbox_max_y : 0;
        $clip_left = $self->bbox_min_x || 0;
        $clip_right
            = defined $self->bbox_max_x ? $width - $self->bbox_max_x : 0;
    }
    else {
        $clip_top    = $self->tc_clip1_top;
        $clip_bottom = $self->tc_clip1_bottom;
        $clip_left   = $self->tc_clip1_left;
        $clip_right  = $self->tc_clip1_right;
    }

    if ($use_clip1) {
        $clip1_top    = $clip_top;
        $clip1_bottom = $clip_bottom;
        $clip1_left   = $clip_left;
        $clip1_right  = $clip_right;
    }
    else {
        $clip1_top    = 0;
        $clip1_bottom = 0;
        $clip1_left   = 0;
        $clip1_right  = 0;
    }

    # align clip1 values when fast resizing is enabled
    if ($fast_resize_align) {
        $clip1_left   = int( $clip1_left / $zoom_align ) * $zoom_align;
        $clip1_right  = int( $clip1_right / $zoom_align ) * $zoom_align;
        $clip1_top    = int( $clip1_top / $zoom_align ) * $zoom_align;
        $clip1_bottom = int( $clip1_bottom / $zoom_align ) * $zoom_align;
    }

    # no odd clip values
    --$clip1_left   if $clip1_left % 2;
    --$clip1_right  if $clip1_right % 2;
    --$clip1_top    if $clip1_top % 2;
    --$clip1_bottom if $clip1_bottom % 2;

    # calculate start width and height
    my $clip_width  = $width - $clip1_left - $clip1_right;
    my $clip_height = $height - $clip1_top - $clip1_bottom;

    #print "clip_width=$clip_width clip_height=$clip_height\n";

    if ( not $target_height ) {
        $target_width
            ||= int( $clip_width * $ar_width_factor - $step * $step_size );
    }

    my ( $actual_width, $actual_height );
    my ( $zoom_width,   $zoom_height );
    my ( $clip2_width,  $clip2_height );
    my ( $clip2_top,    $clip2_bottom, $clip2_left, $clip2_right );

    if ($target_width) {
        $actual_width  = $target_width;
        $actual_height = int(
            $clip_height - ( $clip_width * $ar_width_factor - $target_width )
                / ( $ar * $height / $clip_height ) );
    }
    else {
        $actual_height = $target_height;
        $actual_width  = int(
            $clip_width * $ar_width_factor - ( $clip_height - $actual_height )
                * ( $ar * $height / $clip_height ) );
    }

    my $zoom_width  = $actual_width;
    my $zoom_height = $actual_height;

    #print "actual_width=$actual_width actual_height=$actual_height\n";

    if ( $zoom_width % $zoom_align ) {
        $zoom_width = int( $zoom_width / $zoom_align + 1 ) * $zoom_align
            if $zoom_width % $zoom_align >= $zoom_align / 2;
        $zoom_width = int( $zoom_width / $zoom_align ) * $zoom_align
            if $zoom_width % $zoom_align < $zoom_align / 2;
    }

    if ( $zoom_height % $zoom_align ) {
        $zoom_height = int( $zoom_height / $zoom_align + 1 ) * $zoom_align
            if $zoom_height % $zoom_align >= $zoom_align / 2;
        $zoom_height = int( $zoom_height / $zoom_align ) * $zoom_align
            if $zoom_height % $zoom_align < $zoom_align / 2;
    }

    #print "zoom_width=$zoom_width zoom_height=$zoom_height\n";

    my $eff_ar = ( $zoom_width / $zoom_height ) * ( $width / $height )
        / ( $clip_width / $clip_height );
    my $ar_err = abs( 100 - $eff_ar / $ar * 100 );

#print "clip_left=$clip_left clip_right=$clip_right clip_top=$clip_top clip_bottom=$clip_bottom\n";

    if ( not $use_clip1 ) {
        $clip2_left  = int( $clip_left * $zoom_width / $clip_width / 2 ) * 2;
        $clip2_right = int( $clip_right * $zoom_width / $clip_width / 2 ) * 2;
        $clip2_top   = int( $clip_top * $zoom_height / $clip_height / 2 ) * 2;
        $clip2_bottom
            = int( $clip_bottom * $zoom_height / $clip_height / 2 ) * 2;
        $result_align_clip2 = 1;
        $result_align = 16 if not defined $result_align;
    }

    $clip2_width  = $zoom_width - $clip2_left - $clip2_right;
    $clip2_height = $zoom_height - $clip2_top - $clip2_bottom;

    #print "clip2_width=$clip2_width clip2_height=$clip2_height\n";

    if ($result_align_clip2) {
        $result_align ||= 16;    # fail safe -> prevent division by zero
        my $rest;
        if ( $rest = $clip2_width % $result_align ) {
            $clip2_left  += $rest / 2;
            $clip2_right += $rest / 2;
            $clip2_width -= $rest;
            if ( $clip2_left % 2 and $clip2_left > $clip2_right ) {
                --$clip2_left;
                ++$clip2_right;
            }
            elsif ( $clip2_left % 2 ) {
                ++$clip2_left;
                --$clip2_right;
            }
        }
        if ( $rest = $clip2_height % $result_align ) {
            $clip2_top    += $rest / 2;
            $clip2_bottom += $rest / 2;
            $clip2_height -= $rest;
            if ( $clip2_top % 2 and $clip2_top > $clip2_bottom ) {
                --$clip2_top;
                ++$clip2_bottom;
            }
            elsif ( $clip2_top % 2 ) {
                ++$clip2_top;
                --$clip2_bottom;
            }
        }
    }

    my $phys_ar = 0;
    $phys_ar = $clip2_width / $clip2_height if $clip2_height != 0;

    # pixels per second
    my $pps = $self->frame_rate * $clip2_width * $clip2_height;

    # bits per pixel
    my $bpp = 0;
    $bpp = $video_bitrate * 1000 / $pps if $pps != 0;

    return {
        zoom_width   => $zoom_width,
        zoom_height  => $zoom_height,
        eff_ar       => $eff_ar,
        ar_err       => $ar_err,
        clip1_left   => ( $clip1_left || 0 ),
        clip1_right  => ( $clip1_right || 0 ),
        clip1_top    => ( $clip1_top || 0 ),
        clip1_bottom => ( $clip1_bottom || 0 ),
        clip1_width  => $width - $clip1_left - $clip1_right,
        clip1_height => $height - $clip1_top - $clip1_bottom,
        clip2_left   => ( $clip2_left || 0 ),
        clip2_right  => ( $clip2_right || 0 ),
        clip2_top    => ( $clip2_top || 0 ),
        clip2_bottom => ( $clip2_bottom || 0 ),
        clip2_width  => $clip2_width,
        clip2_height => $clip2_height,
        phys_ar      => $phys_ar,
        bpp          => $bpp,
        exact_width  => $actual_width,
        exact_height => $actual_height,
    };
}

#---------------------------------------------------------------------
# Methods for Ripping
#---------------------------------------------------------------------

sub is_ripped {
    my $self = shift;

    my $project = $self->project;
    return 1 if $project->rip_mode ne 'rip';

    my $name = $project->name;

    if ( not $self->tc_use_chapter_mode ) {
        my $vob_dir = $self->vob_dir;
        return -f "$vob_dir/$name-001.vob";
    }

    my $chapters = $self->get_chapters;

    my $vob_dir;
    foreach my $chapter ( @{$chapters} ) {
        $self->set_actual_chapter($chapter);
        $vob_dir = $self->vob_dir;
        $self->set_actual_chapter(undef);
        return if not -f "$vob_dir/$name-001.vob";
    }

    return 1;
}

sub get_rip_command {
    my $self = shift;

    my $nr           = $self->tc_title_nr;
    my $name         = $self->project->name;
    my $dvd_device   = quotemeta($self->project->dvd_device);
    my $vob_dir      = $self->vob_dir;
    my $vob_nav_file = $self->vob_nav_file;

    $self->create_vob_dir;

    my $chapter = $self->tc_use_chapter_mode ? $self->actual_chapter : "-1";

    my $angle = $self->tc_viewing_angle || 1;

    my ( $setup_subtitle_grabbing, $subtitle_grabbing_pipe )
        = $self->get_subtitle_rip_commands;

    my $tc_nice = $self->tc_nice || 0;

    my $command = $setup_subtitle_grabbing
        . "rm -f $vob_dir/$name-???.vob && "
        . "execflow -n $tc_nice tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device "
        . $subtitle_grabbing_pipe
        . "| dvdrip-splitpipe -f $vob_nav_file 1024 "
        . "  $vob_dir/$name vob >/dev/null && echo EXECFLOW_OK";

    return $command;
}

sub set_chapter_length {
    my $self = shift;

    my $chapter      = $self->actual_chapter;
    my $vob_nav_file = $self->vob_nav_file;

    my $fh = FileHandle->new;
    open( $fh, $vob_nav_file )
        or croak __x( "Can't read VOB navigation file '{vob_nav_file}'",
        vob_nav_file => $vob_nav_file );

    my ( $frames, $block_offset, $frame_offset );
    ++$frames while <$fh>;
    close $fh;

    $self->chapter_frames->{$chapter} = $frames;

    1;
}

#---------------------------------------------------------------------
# Methods for Volume Scanning
#---------------------------------------------------------------------

sub get_tc_scan_command_pipe {
    my $self = shift;

    my $audio_channel = $self->audio_channel;
    my $codec         = $self->audio_track->type =~ /pcm/ ? 'pcm' : 'ac3';
    my $tcdecode      = $codec eq 'ac3' ? "| tcdecode -x ac3 " : "";

    my $tc_nice = $self->tc_nice || 0;

    my $command .= "tcextract -a $audio_channel -x $codec -t vob "
        . $tcdecode
        . "| tcscan -x pcm";

    return $command;
}

sub get_scan_command {
    my $self = shift;

    my $nr             = $self->tc_title_nr;
    my $name           = $self->project->name;
    my $data_source    = $self->transcode_data_source;
    my $vob_dir        = $self->vob_dir;
    my $source_options = $self->data_source_options;
    my $rip_mode       = $self->project->rip_mode;
    my $tc_nice        = $self->tc_nice || 0;

    $self->create_vob_dir;

    my $command;

    if ( $rip_mode eq 'rip' ) {
        my $vob_size = $self->get_vob_size;
        $command
            = "execflow -n $tc_nice cat $vob_dir/* | dvdrip-progress -m $vob_size -i 5 | tccat -t vob";

    }
    else {
        $command = "execflow -n $tc_nice tccat ";
        delete $source_options->{x};
        $command .= " -" . $_ . " " . $source_options->{$_}
            for keys %{$source_options};
        $command .= "| dvdrip-splitpipe -f /dev/null 0 - -";
    }

    my $scan_command = $self->get_tc_scan_command_pipe;

    $command .= " | $scan_command";
    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub get_subtitle_languages {
    my $self = shift;

    my %lang_list;
    foreach my $subtitle ( values %{ $self->subtitles } ) {
        $lang_list{ $subtitle->lang } = 1;
    }

    return \%lang_list;
}

sub has_subtitles {
    my $self = shift;
    return scalar( keys %{ $self->subtitles } ); 
}

sub get_subtitle_rip_commands_spuunmux {
    my $self = shift;

    return if $self->version("spuunmux") < 611;

    my $mode = $self->tc_rip_subtitle_mode;
    return if !$mode;

    my $setup_subtitle_grabbing;
    my $subtitle_grabbing = " | dvdrip-multitee 1 ";

    my $lang = $self->tc_rip_subtitle_lang || [];
    my %lang;
    @lang{ @{$lang} } = (1) x @{$lang};

    my $lang_match;
    foreach my $subtitle ( sort { $a->id <=> $b->id }
        values %{ $self->subtitles } ) {
        next if $mode eq 'lang' && !$lang{ $subtitle->lang };
        $lang_match = 1;
        my $sub_dir = $self->get_subtitle_preview_dir( $subtitle->id );
        my $sid     = $subtitle->id;
        $setup_subtitle_grabbing .= "rm -rf $sub_dir; mkdir -p $sub_dir; "
            . "touch $sub_dir/.ripped; ";
        $subtitle_grabbing .= "'spuunmux -s $sid -o $sub_dir/pic -' ";
    }

    return unless $lang_match;
    return ( $setup_subtitle_grabbing, $subtitle_grabbing );
}

sub get_subtitle_rip_commands {
    my $self = shift;

    my $mode = $self->tc_rip_subtitle_mode;
    return if !$mode;

    my $setup_subtitle_grabbing;
    my $subtitle_grabbing = " | dvdrip-multitee 1 ";

    my $lang = $self->tc_rip_subtitle_lang || [];
    my %lang;
    @lang{ @{$lang} } = (1) x @{$lang};

    my $lang_match;
    foreach my $subtitle ( sort { $a->id <=> $b->id }
        values %{ $self->subtitles } ) {
        next if $mode eq 'lang' && !$lang{ $subtitle->lang };
        $lang_match = 1;
        my $sub_dir = $self->get_subtitle_preview_dir( $subtitle->id );
        my $sid = sprintf( "0x%x", 32 + $subtitle->id );
        $setup_subtitle_grabbing .= "rm -rf $sub_dir; mkdir -p $sub_dir; "
            . "touch $sub_dir/.ripped; ";
        $subtitle_grabbing .= "'tcextract -x ps1 -t vob -a $sid |"
            . " subtitle2pgm -P -C 0 -o $sub_dir/pic -e 00:00:00,50000 2>&1 |"
            . " dvdrip-subpng' ";
    }

    return unless $lang_match;
    return ( $setup_subtitle_grabbing, $subtitle_grabbing );
}

#---------------------------------------------------------------------
# Methods for Ripping and Scanning
#---------------------------------------------------------------------

sub get_rip_and_scan_command {
    my $self = shift;

    my $nr            = $self->tc_title_nr;
    my $audio_channel = $self->audio_channel;
    my $name          = $self->project->name;
    my $dvd_device    = quotemeta($self->project->dvd_device);
    my $vob_dir       = $self->vob_dir;
    my $vob_nav_file  = $self->vob_nav_file;
    my $tc_nice       = $self->tc_nice || 0;

    $self->create_vob_dir;

    my $chapter = $self->tc_use_chapter_mode ? $self->actual_chapter : "-1";

    my $angle = $self->tc_viewing_angle || 1;

    my ( $setup_subtitle_grabbing, $subtitle_grabbing_pipe )
        = $self->get_subtitle_rip_commands;

    my $command = $setup_subtitle_grabbing
        . "rm -f $vob_dir/$name-???.vob && "
        . "execflow -n $tc_nice tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device "
        . $subtitle_grabbing_pipe
        . "| dvdrip-splitpipe -f $vob_nav_file 1024 $vob_dir/$name vob ";

    if ( $audio_channel != -1 ) {
        my $scan_command = $self->get_tc_scan_command_pipe;
        $command .= " | $scan_command && echo EXECFLOW_OK";

    }
    else {
        $command .= ">/dev/null && echo EXECFLOW_OK";
    }

    return $command;
}

sub analyze_scan_output {
    my $self = shift;
    my %par = @_;
    my ( $output, $count ) = @par{ 'output', 'count' };

    return 1 if $self->audio_channel == -1;

    $output =~ s/^.*?--splitpipe-finished--\n//s;

    Video::DVDRip::Probe->analyze_scan(
        scan_output => $output,
        audio       => $self->audio_track,
        count       => $count,
    );

    1;
}

#---------------------------------------------------------------------
# Methods for Probing DVD
#---------------------------------------------------------------------

sub get_probe_command {
    my $self = shift;

    my $nr          = $self->tc_title_nr;
    my $data_source = $self->project->rip_data_source;

    my $command = "execflow tcprobe -H 10 -i $data_source -T $nr && "
        . "echo EXECFLOW_OK; "
        . "execflow dvdxchap -t $nr $data_source 2>/dev/null";

    return $command;
}

sub analyze_probe_output {
    my $self = shift;
    my %par = @_;
    my ($output) = @par{'output'};

    Video::DVDRip::Probe->analyze(
        probe_output => $output,
        title        => $self,
    );

    1;
}

#---------------------------------------------------------------------
# Methods for probing detailed audio information
#---------------------------------------------------------------------

sub get_probe_audio_command {
    my $self = shift;

    my $nr      = $self->tc_title_nr;
    my $vob_dir = $self->vob_dir;

    my $probe_mb    = 25;
    my $vob_size_mb = $self->get_vob_size;

    $probe_mb = $vob_size_mb - 1 if $probe_mb > $vob_size_mb;

    my $h_option = $probe_mb <= 0 ? "" : "-H $probe_mb";

    return "execflow tcprobe $h_option -i $vob_dir && echo EXECFLOW_OK";
}

sub get_detect_audio_bitrate_command {
    my $self = shift;
    
    my $nr          = $self->tc_title_nr;
    my $tmp_file    = $self->project->snap_dir."/dvdrip.audioprobe.$$.vob";
    my $data_source = $self->project->rip_data_source;

    return
        "execflow tccat -i $data_source -T $nr | ".
        "dvdrip-progress -m 25 -i 1 | ".
        "head -c 25m > $tmp_file && ".
        "tcprobe -i $tmp_file && ".
        "echo EXECFLOW_OK; ".
        "rm -f $tmp_file";
}

sub probe_audio {
    my $self = shift;

    return 1 if $self->audio_channel == -1;

    my $output = $self->system( command => $self->get_probe_audio_command );

    $self->analyze_probe_audio_output( output => $output, );

    1;
}

sub analyze_probe_audio_output {
    my $self = shift;
    my %par = @_;
    my ($output) = @par{'output'};

    Video::DVDRip::Probe->analyze_audio(
        probe_output => $output,
        title        => $self,
    );

    1;
}

#---------------------------------------------------------------------
# Methods for Transcoding
#---------------------------------------------------------------------

sub suggest_transcode_options {
    my $self = shift;
    my ($mode) = @_;

    $mode ||= "all";  # or "update", called after ripping, probing VOB

    my $rip_mode = $self->project->rip_mode;

    if (    $self->video_mode eq 'ntsc'
        and $rip_mode eq 'rip'
        and @{ $self->program_stream_units } > 1 ) {
        $self->set_tc_psu_core(1);
        $self->log(
            __ "Enabled PSU core. Movie is NTSC and has more than one PSU." );

    }
    elsif ( $self->video_mode eq 'ntsc' and $rip_mode eq 'rip' ) {
        $self->log(
            __ "Not enabling PSU core, because this movie has only one PSU."
        );
    }

    if ( $rip_mode eq 'rip' ) {
        if ( $self->tc_use_chapter_mode ) {
            my $chapter = $self->get_first_chapter;
            $self->set_preview_frame_nr(
                int( $self->chapter_frames->{$chapter} / 2 ) );
        }
        else {
            $self->set_preview_frame_nr( int( $self->frames / 2 ) );
        }
    }
    else {
        $self->set_preview_frame_nr(200);
    }

    my $pref_lang = $self->config('preferred_lang');
    if ( $pref_lang =~ /^\s*([a-z]{2})/ ) {
        $pref_lang = $1;
    }
    else {
        $pref_lang = "";
    }

    if ( $pref_lang  ) {
        #-- select the subtitle stream of the preferred language
        #-- with the minumum number of images, because it's likely
        #-- that this is a forced subtitle.
        my $min_image_cnt = 1_000_000;
        my $min_image_subtitle_id;
        foreach my $sid ( sort { $a <=> $b } keys %{ $self->subtitles } ) {
            my $subtitle = $self->subtitles->{$sid};
            if ( $subtitle->lang eq $pref_lang ) {
                if ( $subtitle->ripped_images_cnt < $min_image_cnt ) {
                    $min_image_subtitle_id = $subtitle->id;
                    $min_image_cnt         = $subtitle->ripped_images_cnt;
                }
            }
        }
        if ( defined $min_image_subtitle_id ) {
            $self->set_selected_subtitle_id($min_image_subtitle_id);
        }
    }

    $self->set_tc_video_framerate( $self->frame_rate );

    return if $mode ne 'all';

    if ( $pref_lang  ) {
        foreach my $audio ( @{ $self->audio_tracks } ) {
            if ( $audio->lang eq $pref_lang ) {
                $self->set_audio_channel( $audio->tc_nr );
                last;
            }
        }
    }

    $self->set_skip_video_bitrate_calc(1);

    $self->set_tc_viewing_angle(1) if !$self->tc_viewing_angle;
    $self->set_tc_multipass(1);
    $self->set_tc_keyframe_interval(50);

    my $container = $self->config('default_container');

    # Internal value for MPEG/X*S*VCD/CVD container is 'vcd',
    # but in the Config dialog the more convenient 'mpeg'
    # is used, so this is translated here.
    $container = 'vcd' if $container eq 'mpeg';

    $self->set_tc_container( $self->config('default_container') );
    $self->set_tc_video_codec( $self->config('default_video_codec') );

    if ( $self->tc_video_codec =~ /^(X?S?VCD|CVD)$/ ) {
        $self->set_tc_container('vcd');
    }

    $self->set_preset($self->config("default_preset"))
        unless $self->last_applied_preset;

    my $subtitle_langs = $self->get_subtitle_languages;

    if ( $subtitle_langs->{$pref_lang} ) {
        $self->set_tc_rip_subtitle_lang( [$pref_lang] );
    }

    $self->set_tc_video_bitrate_mode("size");
    $self->set_tc_target_size(1400);
    $self->set_tc_disc_size(700);
    $self->set_tc_disc_cnt(2);
    $self->set_tc_video_bitrate_manual(1800);
    $self->set_tc_nice(19);

    if ( $self->config('default_bpp') ne '<none>' ) {
        $self->set_tc_video_bitrate_mode('bpp');
        $self->set_tc_video_bpp_manual( $self->config('default_bpp') );
    }

    $self->set_skip_video_bitrate_calc(0);

    $self->calc_video_bitrate;

    1;
}

sub skip_video_bitrate_calc     { shift->{skip_video_bitrate_calc} }
sub set_skip_video_bitrate_calc { shift->{skip_video_bitrate_calc} = $_[1] }

sub calc_video_bitrate {
    my $self = shift;

    return if $self->skip_video_bitrate_calc;

    my $bc = Video::DVDRip::BitrateCalc->new(
        title      => $self,
        with_sheet => 1,
    );
    $bc->calculate;

    $self->set_tc_video_bpp( $bc->video_bpp );
    $self->set_tc_video_bitrate( $bc->video_bitrate );
    $self->set_storage_video_size( int( $bc->video_size ) );
    $self->set_storage_audio_size( int( $bc->audio_size ) );
    $self->set_storage_other_size( int( $bc->other_size ) );
    $self->set_storage_total_size( int( $bc->file_size ) );

    $self->set_bitrate_calc($bc);

    return $bc->video_bitrate;
}

sub get_first_audio_track {
    my $self = shift;

    return -1 if $self->audio_channel == -1;
    return -1 if not $self->audio_tracks;

    foreach my $audio ( @{ $self->audio_tracks } ) {
        return $audio->tc_nr if $audio->tc_target_track == 0;
    }

    return -1;
}

sub get_last_audio_track {
    my $self = shift;

    return -1 if $self->audio_channel == -1;
    return -1 if not $self->audio_tracks;

    my $tc_nr = -1;
    foreach my $audio ( @{ $self->audio_tracks } ) {
        $tc_nr = $audio->tc_nr if $audio->tc_target_track > $tc_nr;
    }

    return $tc_nr;
}

sub get_additional_audio_tracks {
    my $self = shift;

    my %avi2vob;
    foreach my $audio ( @{ $self->audio_tracks } ) {
        next if $audio->tc_target_track == -1;
        next if $audio->tc_target_track == 0;
        $avi2vob{ $audio->tc_target_track } = $audio->tc_nr;
    }

    return \%avi2vob;
}

sub get_transcode_frame_cnt {
    my $self      = shift;
    my %par       = @_;
    my ($chapter) = @par{'chapter'};

    my $frames_cnt;
    if ( not $chapter ) {
        $frames_cnt = $self->frames;
    }
    else {
        $frames_cnt = $self->chapter_frames->{$chapter};
    }

    my $frames = $frames_cnt;

    if (   $self->tc_start_frame ne ''
        or $self->tc_end_frame ne '' ) {
        $frames = $self->tc_end_frame || $frames_cnt;
        $frames = $frames - $self->tc_start_frame
            if $self->has_vob_nav_file;
        $frames ||= $frames_cnt;
    }

    return $frames;
}

sub get_transcode_progress_max {
    my $self = shift;

    my $subtitle_test = $self->subtitle_test;

    my $chapter = $self->actual_chapter;

    my $progress_max;

    if ($subtitle_test) {
        my ( $from, $to ) = $self->get_subtitle_test_frame_range;
        $progress_max = $to - $from;
    }
    else {
        $progress_max = $self->get_transcode_frame_cnt( chapter => $chapter );
    }

    return $progress_max;
}

sub multipass_log_is_reused {
    my $self = shift;

    return $self->tc_multipass_reuse_log
        && -f $self->multipass_log_dir . "/divx4.log";
}

sub get_transcode_status_option {
    my $self = shift;
    my ($rate) = @_;
    
    $rate ||= 25;
    
    if ( $self->version("transcode") >= 10100) {
        return "--progress_meter 2 --progress_rate $rate";
    }
    else {
        return "--print_status $rate";
    }
}

sub get_transcode_command {
    my $self = shift;
    my %par = @_;
    my ( $pass, $split, $no_audio, $output_file )
        = @par{ 'pass', 'split', 'no_audio', 'output_file' };

    my $bc = Video::DVDRip::BitrateCalc->new( title => $self );
    $bc->calculate;

    my $nr            = $self->nr;
    my $avi_file      = $output_file || $self->avi_file;
    my $audio_channel = $self->get_first_audio_track;

    $audio_channel = -1 if $no_audio;

    my $source_options
        = $self->data_source_options( audio_channel => $audio_channel );

    my ($audio_info);

    if ( $audio_channel != -1 ) {
        $audio_info = $self->audio_tracks->[$audio_channel];
    }

    my $mpeg = 0;
    $mpeg = "svcd" if $self->tc_video_codec =~ /^(X?SVCD|CVD)$/;
    $mpeg = "vcd"  if $self->tc_video_codec =~ /^X?VCD$/;

    my $dir = dirname($avi_file);

    my $tc_nice = $self->tc_nice || 0;
    my $command = "mkdir -p $dir && execflow -n $tc_nice transcode -H 10";

    $command .= " -a $audio_channel" if $audio_channel != -1;

    $command .= " -" . $_ . " " . $source_options->{$_}
        for keys %{$source_options};

    if ( $self->tc_video_bitrate ) {
        $command .= " -w "
            . int( $self->tc_video_bitrate ) . ","
            . $self->tc_keyframe_interval;
    }

    #	if ( not $mpeg ) {
    #		$command .=
    #			" -w ".int($self->tc_video_bitrate);
    #	} elsif ( $mpeg eq 'svcd' and $self->tc_video_bitrate ) {
    #		$command .=
    #			" -w ".int($self->tc_video_bitrate);
    #	}

    if (   $self->tc_start_frame ne ''
        or $self->tc_end_frame ne '' ) {
        my $start_frame = $self->tc_start_frame;
        my $end_frame   = $self->tc_end_frame;
        $start_frame ||= 0;
        $end_frame   ||= $self->frames;

        if ( $start_frame != 0 ) {
            my $options
                = $self->get_frame_grab_options( frame => $start_frame );
            $options->{c} =~ /(\d+)/;
            my $c1 = $1;
            my $c2 = $c1 + $end_frame - $start_frame;
            $command .= " -c $c1-$c2";
            $command .= " -L $options->{L}"
                if $options->{L} ne '';

        }
        else {
            $command .= " -c $start_frame-$end_frame";
        }
    }

    if ($mpeg) {
        my $size            = $bc->disc_size || 1;
        my $reserve_bitrate = $bc->vcd_reserve_bitrate;
        my $mpeg2enc_opts   = "-B $reserve_bitrate -I 0 ";
        if ($split) {
            $mpeg2enc_opts .= "-S $size ";
        }
        else {
            $mpeg2enc_opts .= "-S 10000 ";
        }

        if ( $mpeg eq 'svcd' ) {
            if ( $self->video_mode eq 'pal' ) {
                $mpeg2enc_opts .= " -g 6 -G 15";
            }
            else {
                $mpeg2enc_opts .= " -g 9 -G 18";
                if ( $self->frame_rate == 23.976 ) {
                    $mpeg2enc_opts .= " -p";
                }
            }

            $mpeg2enc_opts = ",'$mpeg2enc_opts'" if $mpeg2enc_opts;

            $command .= " -F 5$mpeg2enc_opts";

            if ( $self->aspect_ratio eq '16:9' ) {

                # 16:9
                if ( $self->last_applied_preset =~ /4_3/ ) {

                    # 4:3 with black bars
                    $command .= " --export_asr 2";
                }
                else {
                    $command .= " --export_asr 3";
                }
            }
            else {

                # 4:3
                $command .= " --export_asr 2";
            }
        }
        else {
            $mpeg2enc_opts = ",'$mpeg2enc_opts'" if $mpeg2enc_opts;

            if ( $self->tc_video_codec eq 'XVCD' ) {
                $command .= " -F 2$mpeg2enc_opts --export_asr 2";
            }
            else {
                $command .= " -F 1$mpeg2enc_opts --export_asr 2";
            }
        }

    }
    else {
        $command .= " -F " . $self->tc_video_af6_codec
            if $self->tc_video_af6_codec ne '';
    }

    if ( $audio_channel != -1 ) {
        $command .= " -d"
            if $audio_info->type eq 'lpcm'
            and $self->version("transcode") < 613;

        if ($mpeg) {
            $command .= " -b " . $audio_info->tc_bitrate;
        }
        elsif ( $audio_info->tc_audio_codec =~ /^mp\d/ ) {
            $command .= " -b "
                . $audio_info->tc_bitrate . ",0,"
                . $audio_info->tc_mp3_quality;
        }
        elsif ( $audio_info->tc_audio_codec eq 'vorbis' ) {
            if ( $audio_info->tc_vorbis_quality_enable ) {
                $command .= " -b 0,1," . $audio_info->tc_vorbis_quality;
            }
            else {
                $command .= " -b " . $audio_info->tc_bitrate;
            }
        }

        if ( $audio_info->tc_audio_codec eq 'ac3' ) {
            $command .= " -A -N " . $audio_info->tc_option_n;

        }
        elsif ( $audio_info->tc_audio_codec eq 'pcm' ) {
            $command .= " -N 0x1";

        }
        else {
            $command .= " -s " . $audio_info->tc_volume_rescale
                if $audio_info->tc_volume_rescale != 0
                and $audio_info->type ne 'lpcm';
            $command .= " --a52_drc_off"
                if $audio_info->tc_audio_filter ne 'a52drc';
            $command .= " -J normalize"
                if $audio_info->tc_audio_filter eq 'normalize';
        }
    }

    if ( $self->version("transcode") >= 613 ) {
        $command .= " --use_rgb -k "
            if not $self->tc_use_yuv_internal;

    }
    elsif ( $self->version("transcode") >= 608 ) {
        $command .= " -V "
            if $self->tc_use_yuv_internal
            and $self->tc_deinterlace ne 'smart'

    }
    else {
        $command .= " -V "
            if $self->tc_use_yuv_internal
            and $self->version("transcode") >= 603;
    }

    $command .= " -C " . $self->tc_anti_alias
        if $self->tc_anti_alias;

    my $fr = $self->tc_video_framerate;

    if ( $self->tc_deinterlace eq '32detect' ) {
        $command .= " -J 32detect=force_mode=3";

    }
    elsif ( $self->tc_deinterlace eq 'smart' ) {
        if ( $self->version("transcode") >= 608 ) {
            $command
                .= " -J smartyuv=threshold=10:Blend=1:diffmode=2:highq=1";
        }
        else {
            $command
                .= " -J smartdeinter=threshold=10:Blend=1:diffmode=2:highq=1";
        }

    }
    elsif ( $self->tc_deinterlace eq 'ivtc' ) {
        $fr = 23.976;
        $command .= " -J ivtc,32detect=force_mode=3,decimate";

    }
    elsif ( $self->tc_deinterlace ) {
        $command .= " -I " . $self->tc_deinterlace;
    }

    if ( $self->tc_video_framerate ) {
        $fr = "24,1" if $fr == 23.976;
        $fr = "30,4" if $fr == 29.97;
        $command .= " -f $fr";
    }

    if ( $self->video_mode eq 'ntsc' and $self->tc_options !~ /-M/ ) {
        my $m = " -M 2";
        $m = " -M 0" if $self->tc_deinterlace eq 'ivtc';
        $command .= $m;
    }

    $command .= " -J preview=xv" if $self->tc_preview;

    my $clip1 = ( $self->tc_clip1_top || 0 ) . ","
        . ( $self->tc_clip1_left   || 0 ) . ","
        . ( $self->tc_clip1_bottom || 0 ) . ","
        . ( $self->tc_clip1_right  || 0 );

    $command .= " -j $clip1"
        if $clip1 =~ /^-?\d+,-?\d+,-?\d+,-?\d+$/
        and $clip1 ne '0,0,0,0';

    my $clip2 = ( $self->tc_clip2_top || 0 ) . ","
        . ( $self->tc_clip2_left   || 0 ) . ","
        . ( $self->tc_clip2_bottom || 0 ) . ","
        . ( $self->tc_clip2_right  || 0 );

    $command .= " -Y $clip2"
        if $clip2 =~ /^-?\d+,-?\d+,-?\d+,-?\d+$/
        and $clip2 ne '0,0,0,0';

    if ( not $self->is_resized ) {
        my $export_par = $self->calc_export_par;
        $command .= " --export_par $export_par";
    }
    else {
        if ( $self->tc_fast_bisection ) {
            $command .= " -r 2,2";

        }
        elsif ( not $self->tc_fast_resize ) {
            my $zoom = $self->tc_zoom_width . "x" . $self->tc_zoom_height;
            $command .= " -Z $zoom"
                if $zoom =~ /^\d+x\d+$/;

        }
        else {
            my $multiple_of = 8;

            my ( $width_n, $height_n, $err_div32, $err_shrink_expand )
                = $self->get_fast_resize_options;

            if ($err_div32) {
                croak __x(
                    "When using fast resize: Clip1 and Zoom size must be divisible by {multiple_of}",
                    multiple_of => $multiple_of
                );
            }

            if ($err_shrink_expand) {
                croak __
                    "When using fast resize: Width and height must both shrink or expand";
            }

            if ( $width_n * $height_n >= 0 ) {
                if ( $width_n > 0 or $height_n > 0 ) {
                    $command .= " -X $height_n,$width_n";
                    $command .= ",$multiple_of" if $multiple_of != 32;
                }
                elsif ( $width_n < 0 or $height_n < 0 ) {
                    $width_n  = abs($width_n);
                    $height_n = abs($height_n);
                    $command .= " -B $height_n,$width_n";
                    $command .= ",$multiple_of" if $multiple_of != 32;
                }
            }
        }
    }

    my $dir = $self->multipass_log_dir;
    $command = "mkdir -m 0775 -p '$dir' && cd $dir && $command";

    if ( $self->tc_multipass ) {
        $command .= " -R $pass";

        $avi_file = "/dev/null" if $pass == 1;

        if ($pass == 1 and not $self->has_vbr_audio
            or (    $pass == 2
                and $self->has_vbr_audio
                and not $self->multipass_log_is_reused )
            ) {
            $command =~ s/(-x\s+[^\s]+)/$1,null/;
            $command =~ s/-x\s+([^,]+),null,null/-x $1,null/;
            $command .= " -y " . $self->tc_video_codec;
            $command .= ",null" if not $self->has_vbr_audio or $pass == 2;
        }

        if ( $pass == 1 and $self->video_mode eq 'ntsc' ) {

            # Don't use -x vob,null with NTSC, because this may
            # cause out-of-sync audio.
            $command =~ s/(-x\s+[^,]+),null/$1/;
        }
    }

    if (   not $self->tc_multipass
        or ( $pass == 2 xor $self->has_vbr_audio )
        or ( $pass == 2 and $self->multipass_log_is_reused ) ) {
        if ($mpeg) {
            $command .= " -y mpeg2enc,mp2enc";
            $command .= " -E " . $audio_info->tc_samplerate
                if $audio_info->tc_samplerate;
        }
        else {
            $command .= " -y " . $self->tc_video_codec;
            if (    $self->tc_container eq 'ogg'
                and $audio_channel != -1 ) {
                $command .= ",ogg"
                    if $audio_info->tc_audio_codec eq 'vorbis';
                $command .= " -m "
                    . $self->target_avi_audio_file(
                    vob_nr => $audio_channel,
                    avi_nr => 0
                    );
            }
            if ( $audio_channel == -1 ) {
                $command .= ",null";

            }
            else {
                if (    not $audio_info->is_passthrough
                    and $audio_info->tc_samplerate != $audio_info->sample_rate
                    and $audio_info->tc_samplerate ) {
                    $command .= " -E " . $audio_info->tc_samplerate
                        if $audio_info->tc_samplerate;
                    $command .= " -J resample"
                        if $audio_info->tc_audio_codec eq 'vorbis';
                }
            }
        }
    }

    if ( $self->tc_psu_core ) {
        $command .= " --psu_mode --nav_seek "
            . $self->vob_nav_file
            . " --no_split ";
    }

    $command .= " -o $avi_file";

    $command .= " ".$self->get_transcode_status_option;

    if ( $self->tc_container eq 'avi' and $self->tc_target_size > 2048 ) {
        $command .= " --avi_limit 9999";
    }

    # Filters
    my $config_strings = $self->tc_filter_settings->get_filter_config_strings;

    foreach my $config ( @{$config_strings} ) {
        next if not $config->{enabled};
        $command .= " -J $config->{filter}";
        $command .= "=$config->{options}" if $config->{options};
    }

    $self->create_avi_dir;

    $command = $self->combine_command_options(
        cmd      => "transcode",
        cmd_line => $command,
        options  => $self->tc_options,
        )
        if $self->tc_options =~ /\S/;

    $command .= $self->get_subtitle_transcode_options;

    if ( $self->tc_video_af6_codec eq 'h264' and
         $self->tc_multipass and $pass == 1 ) {
        $command .= " && cp x264_2pass.log divx4.log";
    }
         

    $command = "$command && echo EXECFLOW_OK ";

    return $command;
}

sub get_transcode_audio_command {
    my $self = shift;
    my %par  = @_;
    my ( $vob_nr, $target_nr ) = @par{ 'vob_nr', 'target_nr' };

    my $source_options
        = $self->data_source_options( audio_channel => $vob_nr );

    $source_options->{x} = "null,$source_options->{x}";

    my $audio_info = $self->audio_tracks->[$vob_nr];

    my $audio_file = $self->target_avi_audio_file(
        vob_nr => $vob_nr,
        avi_nr => $target_nr
    );

    my $dir = dirname($audio_file);

    my $tc_nice = $self->tc_nice || 0;

    my $command = "mkdir -p $dir && "
        . "execflow -n $tc_nice transcode "
        . " -H 10"
        . " -u 50"
        . " -a $vob_nr"
        . " -y raw";

    if ( $self->is_ogg ) {
        if ( $audio_info->tc_audio_codec eq 'vorbis' ) {
            $command .= ",ogg -m $audio_file -o /dev/null";
        }
        else {
            $command .= " -m $audio_file -o /dev/null";
        }

    }
    elsif ( $self->tc_container eq 'vcd' ) {
        $command .= ",mp2enc -o $audio_file";

    }
    else {
        $command .= " -o " . $audio_file;
    }

    my ( $k, $v );
    while ( ( $k, $v ) = each %{$source_options} ) {
        $command .= " -$k $v";
    }

    if ( $self->tc_video_framerate ) {
        my $fr = $self->tc_video_framerate;
        $fr = "24,1" if $fr == 23.976;
        $fr = "30,4" if $fr == 29.97;
        $command .= " -f $fr";
    }

    if ( $audio_info->tc_audio_codec eq 'ac3' ) {
        $command .= " -A -N " . $audio_info->tc_option_n;

    }
    elsif ( $audio_info->tc_audio_codec eq 'pcm' ) {
        $command .= " -N 0x1";

    }
    else {

        if ( $audio_info->tc_audio_codec =~ /^mp\d/ ) {
            $command .= " -b "
                . $audio_info->tc_bitrate . ",0,"
                . $audio_info->tc_mp3_quality;

        }
        elsif ( $audio_info->tc_audio_codec eq 'vorbis' ) {
            if ( $audio_info->tc_vorbis_quality_enable ) {
                $command .= " -b 0,1," . $audio_info->tc_vorbis_quality;
            }
            else {
                $command .= " -b " . $audio_info->tc_bitrate;
            }
        }

        $command .= " -s " . $audio_info->tc_volume_rescale
            if $audio_info->tc_volume_rescale != 0;

        $command .= " --a52_drc_off "
            if $audio_info->tc_audio_filter ne 'a52drc';
        $command .= " -J normalize"
            if $audio_info->tc_audio_filter eq 'normalize';

        if (    $audio_info->tc_samplerate != $audio_info->sample_rate
            and $audio_info->tc_samplerate ) {
            $command .= " -E " . $audio_info->tc_samplerate
                if $audio_info->tc_samplerate;
            $command .= " -J resample"
                if $audio_info->tc_audio_codec eq 'vorbis';
        }
    }

    if (   $self->tc_start_frame ne ''
        or $self->tc_end_frame ne '' ) {
        my $start_frame = $self->tc_start_frame;
        my $end_frame   = $self->tc_end_frame;
        $start_frame ||= 0;
        $end_frame   ||= $self->frames;

        if ( $start_frame != 0 ) {
            my $options
                = $self->get_frame_grab_options( frame => $start_frame );
            $options->{c} =~ /(\d+)/;
            my $c1 = $1;
            my $c2 = $c1 + $end_frame - $start_frame;
            $command .= " -c $c1-$c2";
            $command .= " -L $options->{L}"
                if $options->{L} ne '';

        }
        else {
            $command .= " -c $start_frame-$end_frame";
        }
    }

    if ( $self->tc_psu_core ) {
        $command .= " --psu_mode --nav_seek "
            . $self->vob_nav_file
            . " --no_split";
    }

    $command .= " ".$self->get_transcode_status_option;

    $command = $self->combine_command_options(
        cmd      => "transcode",
        cmd_line => $command,
        options  => $self->tc_options,
        )
        if $self->tc_options =~ /\S/;

    if ( $self->tc_container eq 'vcd' ) {
        $command .= " && rm -f " . $self->target_avi_file;
    }

    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub get_merge_audio_command {
    my $self = shift;
    my %par  = @_;
    my ( $vob_nr, $target_nr ) = @par{ 'vob_nr', 'target_nr' };

    my $avi_file = $self->target_avi_file;
    my $audio_file;
    $audio_file = $self->target_avi_audio_file(
        vob_nr => $vob_nr,
        avi_nr => $target_nr
        )
        if $vob_nr != -1;

    my $command;

    my $tc_nice = $self->tc_nice || 0;

    if ( $self->is_ogg ) {
        $command .= "execflow -n $tc_nice ogmmerge -o $avi_file.merged "
            . " $avi_file"
            . " $audio_file &&"
            . " mv $avi_file.merged $avi_file &&"
            . " rm -f $audio_file &&"
            . " echo EXECFLOW_OK";

    }
    else {
        die "avimerge without audio isn't possible"
            if not $audio_file;

        $command .= "execflow -n $tc_nice avimerge"
            . " -p $audio_file"
            . " -a $target_nr"
            . " -o $avi_file.merged"
            . " -i $avi_file &&"
            . " mv $avi_file.merged $avi_file &&"
            . " rm $audio_file &&"
            . " echo EXECFLOW_OK";
    }

    return $command;
}

sub get_fast_resize_options {
    my $self = shift;

    my $multiple_of = 8;

    my $width  = $self->width - $self->tc_clip1_left - $self->tc_clip1_right;
    my $height = $self->height - $self->tc_clip1_top - $self->tc_clip1_bottom;

    my $zoom_width  = $self->tc_zoom_width;
    my $zoom_height = $self->tc_zoom_height;

    $zoom_width  ||= $width;
    $zoom_height ||= $height;

    my $width_n  = ( $zoom_width - $width ) / $multiple_of;
    my $height_n = ( $zoom_height - $height ) / $multiple_of;

    my ( $err_div32, $err_shrink_expand );

    if ((   $width_n != 0
            and
            ( $zoom_width % $multiple_of != 0 or $width % $multiple_of != 0 )
        )
        or ($height_n != 0
            and (  $zoom_height % $multiple_of != 0
                or $height % $multiple_of != 0 )
        )
        ) {
        $err_div32 = 1;
    }

    if ( $width_n * $height_n < 0 ) {
        $err_shrink_expand = 1;
    }

    return ( $width_n, $height_n, $err_div32, $err_shrink_expand );
}

sub fast_resize_possible {
    my $self = shift;
    my ( undef, undef, $err1, $err2 ) = $self->get_fast_resize_options;
    my $ok = !( $err1 || $err2 );
    $self->set_tc_fast_resize(0) unless $ok;
    return $ok;
}

#---------------------------------------------------------------------
# Methods for MPEG multiplexing
#---------------------------------------------------------------------

sub get_mplex_command {
    my $self = shift;

    my $video_codec = $self->tc_video_codec;

    my $avi_file = $self->target_avi_file;
    my $size     = $self->tc_disc_size;

    my %mplex_f = (
        XSVCD => 5,
        SVCD  => 4,
        CVD   => 4,
        XVCD  => 2,
        VCD   => 1,
    );

    my %mplex_v = (
        XSVCD => "-V",
        SVCD  => "-V",
        CVD   => "-V",
        XVCD  => "-V",
        VCD   => "",
    );

    my %vext = (
        XSVCD => "m2v",
        SVCD  => "m2v",
        CVD   => "m2v",
        XVCD  => "m1v",
        VCD   => "m1v",
    );

    my $mplex_f = $mplex_f{$video_codec};
    my $mplex_v = $mplex_v{$video_codec};
    my $vext    = $vext{$video_codec};
    
    my $target_file = "$avi_file-%d.mpg";

    my $add_audio_tracks;
    my $add_audio_tracks_href = $self->get_additional_audio_tracks;

    if ( keys %{$add_audio_tracks_href} ) {
        my ( $avi_nr, $vob_nr );
        foreach $avi_nr ( sort keys %{$add_audio_tracks_href} ) {
            $vob_nr = $add_audio_tracks_href->{$avi_nr};
            $add_audio_tracks .= " "
                . $self->target_avi_audio_file(
                vob_nr => $vob_nr,
                avi_nr => $avi_nr,
                )
                . ".mpa";
        }
    }

    my $opt_r;
    if ( $video_codec =~ /^(XS?VCD|CVD)$/ ) {

        #-- get overall bitrate, needed for X(S)VCD.
        my $bc = Video::DVDRip::BitrateCalc->new( title => $self );
        $bc->calculate;
        my $bitrate = $bc->video_bitrate + $bc->audio_bitrate
            + $bc->vcd_reserve_bitrate;
        $opt_r = "-r $bitrate";
    }

    my $tc_nice = $self->tc_nice || 0;

    my $command = "execflow -n $tc_nice mplex -f $mplex_f $opt_r $mplex_v "
        . "-o $target_file $avi_file.$vext $avi_file.mpa "
        . "$add_audio_tracks && echo EXECFLOW_OK";

    return $command;
}

#---------------------------------------------------------------------
# Methods for AVI Splitting
#---------------------------------------------------------------------

sub get_split_command {
    my $self = shift;

    my $avi_file = $self->target_avi_file;
    my $size     = $self->tc_disc_size;

    my $avi_dir = dirname $avi_file;
    $avi_file = basename $avi_file;

    my $split_mask = sprintf( "%s-%03d", $self->project->name, $self->nr, );

    my $command;

    if (    -s "$avi_dir/$avi_file" > 0
        and -s "$avi_dir/$avi_file" <= $size * 1024 * 1024 ) {
        $command = "echo File is smaller than one disc, no need to split. "
            . "&& echo EXECFLOW_OK";
        return $command;
    }

    my $tc_nice = $self->tc_nice || 0;

    if ( $self->is_ogg ) {
        $split_mask .= $self->config('ogg_file_ext');

        $command .= "cd $avi_dir && ls -l && "
            . "execflow -n $tc_nice ogmsplit -s $size $avi_file && "
            . "echo EXECFLOW_OK";
    }
    else {
        $command .= "cd $avi_dir && "
            . "execflow -n $tc_nice avisplit -s $size -i $avi_file -o $split_mask && "
            . "echo EXECFLOW_OK";
    }

    return $command;
}

#---------------------------------------------------------------------
# Methods for taking Snapshots
#---------------------------------------------------------------------

sub snapshot_filename {
    my $self = shift;

    return $self->preview_filename( type => 'orig' );
}

sub raw_snapshot_filename {
    my $self = shift;

    my $raw_filename = $self->snapshot_filename;
    $raw_filename =~ s/\.jpg$/.raw/;

    return $raw_filename;
}

sub get_frame_grab_options {
    my $self    = shift;
    my %par     = @_;
    my ($frame) = @par{'frame'};

    if (   $self->project->rip_mode ne 'rip'
        || !$self->has_vob_nav_file
        || $self->tc_force_slow_grabbing ) {
        $self->log( __ "Fast VOB navigation only available for ripped DVD's, "
                . "falling back to slow method." )
            if $self->project->rip_mode ne 'rip';
        $self->log(
            __ "VOB navigation file is missing. Slow navigation method used."
            )
            if $self->project->rip_mode eq 'rip'
            and not $self->has_vob_nav_file;
        $self->log( __ "Using slow preview grabbing as adviced by user" )
            if $self->tc_force_slow_grabbing;
        return { c => $frame . "-" . ( $frame + 1 ), };
    }

    my $old_chapter = $self->actual_chapter;

    $self->set_actual_chapter( $self->get_first_chapter )
        if $self->tc_use_chapter_mode;

    my $vob_nav_file = $self->vob_nav_file;

    $self->set_actual_chapter($old_chapter)
        if $self->tc_use_chapter_mode;

    my $fh = FileHandle->new;
    open( $fh, $vob_nav_file )
        or croak "msg:"
        . __x( "Can't read VOB navigation file '{vob_nav_file}'",
        vob_nav_file => $vob_nav_file );

    my ( $found, $block_offset, $frame_offset, $psu );

    my $frames = 0;

    while (<$fh>) {
        if ( $frames == $frame ) {
            s/^\s+//;
            s/\s+$//;
            croak "msg:"
                . __x( "VOB navigation file '{vob_nav_file}' is corrupted.",
                vob_nav_file => $vob_nav_file )
                if !/^\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+$/;
            ( $psu, $block_offset, $frame_offset )
                = ( split( /\s+/, $_ ) )[ 0, 4, 5 ];
            $found = 1;
            last;
        }
        ++$frames;
    }

    close $fh;

    croak "msg:"
        . __x(
        "Can't find frame {frame} in VOB navigation file "
            . "'{vob_nav_file}' (which has only {frames} frames). ",
        frame        => $frame,
        vob_nav_file => $vob_nav_file,
        frames       => $frames
        )
        if not $found;

    my @psu;
    if ($psu) {
        @psu = ( S => --$psu );
    }

    return {
        @psu,
        L => $block_offset,
        c => $frame_offset . "-" . ( $frame_offset + 1 )
    };
}

sub get_take_snapshot_command {
    my $self = shift;

    return $self->get_take_snapshot_command_transcode
        if not $self->has("ffmpeg");

    my $nr           = $self->nr;
    my $frame        = $self->preview_frame_nr;
    my $tmp_dir      = $self->project->snap_dir."/dvdrip$$.snap";
    my $filename     = $self->preview_filename( type => 'orig' );
    my $raw_filename = $self->raw_snapshot_filename;
    my $frame_rate   = $self->frame_rate;

    my $source_options = $self->data_source_options;
    my $grab_options   = $self->get_frame_grab_options( frame => $frame );

    $grab_options->{S} ||= "0";
    $grab_options->{L} ||= "0";

    my ($start_frame) = $grab_options->{c} =~ /(\d+)/;
    my $start = sprintf("%.3f", $start_frame / $frame_rate);

    my $T;
    $T = "-T $source_options->{T}" if $source_options->{T};

    my $command = "mkdir -m 0775 $tmp_dir; "
        . "cd $tmp_dir; "
        . "execflow "
        . "tccat -i $source_options->{i} $T "
        . "-t $source_options->{x} "
        . "-S $grab_options->{L} -d 0 | "
        . "tcdemux -s 0x80 -x mpeg2 -S $grab_options->{S} "
        . "-M 0 -d 0 -P /dev/null | "
        . "tcextract -t vob -a 0 -x mpeg2 -d 0 | "
        . "ffmpeg -r $frame_rate -i - -an -r 1 -ss '$start' -vframes 1 snapshot%03d.png ";

    $command .= " && "
        . "execflow convert"
        . " -size "
        . $self->width . "x"
        . $self->height
        . " $tmp_dir/snapshot*.png $filename && "
        . "execflow convert"
        . " -size "
        . $self->width . "x"
        . $self->height
        . " $tmp_dir/snapshot*.png gray:$raw_filename &&"
        . " rm -r $tmp_dir && "
        . "echo EXECFLOW_OK";

    return $command;
}

sub get_take_snapshot_command_transcode {
    my $self = shift;

    my $nr           = $self->nr;
    my $frame        = $self->preview_frame_nr;
    my $tmp_dir      = $self->project->snap_dir."/dvdrip$$.ppm";
    my $filename     = $self->preview_filename( type => 'orig' );
    my $raw_filename = $self->raw_snapshot_filename;

    my $source_options = $self->data_source_options;

    $source_options->{x} .= ",null";

    my $command = "mkdir -m 0775 $tmp_dir; "
        . "cd $tmp_dir; "
        . "execflow transcode "
        . " -H 10 "
        . $self->get_transcode_status_option
        . ( $self->version("transcode") < 613 ? " -z -k" : "" )
        . " -o snapshot"
        . " -y ppm,null";

    $command .= " -" . $_ . " " . $source_options->{$_}
        for keys %{$source_options};

    my $grab_options = $self->get_frame_grab_options( frame => $frame );

    $command .= " -" . $_ . " " . $grab_options->{$_}
        for keys %{$grab_options};

    $command .= " && "
        . "execflow convert"
        . " -size "
        . $self->width . "x"
        . $self->height
        . " $tmp_dir/snapshot*.ppm $filename && "
        . "execflow convert"
        . " -size "
        . $self->width . "x"
        . $self->height
        . " $tmp_dir/snapshot*.ppm gray:$raw_filename &&"
        . " rm -r $tmp_dir && "
        . "echo EXECFLOW_OK";

    $command =~ s/-x\s+([^,]+),null,null/-x $1,null/;

    return $command;
}

sub calc_snapshot_bounding_box {
    my $self = shift;

    my $filename = $self->raw_snapshot_filename;

    open( IN, $filename )
        or die "can't read '$filename'";
    my $blob = "";
    while (<IN>) {
        $blob .= $_;
    }
    close IN;

    my ( $min_x, $min_y, $max_x, $max_y, $x, $y );
    my $width  = $min_x = $self->width;
    my $height = $min_y = $self->height;
    my $thres  = 12;

    # search min_y
    for ( $x = 0; $x < $width; ++$x ) {
        for ( $y = 0; $y < $height; ++$y ) {
            if (unpack( "C", substr( $blob, $y * $width + $x, 1 ) ) > $thres )
            {
                $min_y = $y if $y < $min_y;
                last;
            }
        }
    }

    # search max_y
    for ( $x = 0; $x < $width; ++$x ) {
        for ( $y = $height - 1; $y >= 0; --$y ) {
            if (unpack( "C", substr( $blob, $y * $width + $x, 1 ) ) > $thres )
            {
                $max_y = $y if $y > $max_y;
                last;
            }
        }
    }

    # search min_x
    for ( $y = 0; $y < $height; ++$y ) {
        for ( $x = 0; $x < $width; ++$x ) {

# print "x=$x y=$y min_x=$min_x c=".unpack("C", substr($blob, $y*$width+$x, 1)),"\n";
            if (unpack( "C", substr( $blob, $y * $width + $x, 1 ) ) > $thres )
            {
                $min_x = $x if $x < $min_x;
                last;
            }
        }
    }

    # search max_y
    for ( $y = 0; $y < $height; ++$y ) {
        for ( $x = $width - 1; $x >= 0; --$x ) {
            if (unpack( "C", substr( $blob, $y * $width + $x, 1 ) ) > $thres )
            {
                $max_x = $x if $x > $max_x;
                last;
            }
        }
    }

    # height clipping must not be odd
    --$min_y if $min_y % 2;
    ++$max_y if $max_y % 2;

    $self->set_bbox_min_x($min_x);
    $self->set_bbox_min_y($min_y);
    $self->set_bbox_max_x($max_x);
    $self->set_bbox_max_y($max_y);

    1;
}

#---------------------------------------------------------------------
# Methods for making clip and zoom images
#---------------------------------------------------------------------

sub make_preview_clip1 {
    my $self = shift;

    return $self->make_preview_clip( type => "clip1", );
}

sub make_preview_clip2 {
    my $self = shift;

    return $self->make_preview_clip( type => "clip2", );
}

sub make_preview_clip {
    my $self = shift;
    my %par = @_;
    my ($type) = @par{'type'};

    my $source_file;
    if ( $type eq 'clip1' ) {
        $source_file = $self->preview_filename( type => 'orig' );
    }
    else {
        $source_file = $self->preview_filename( type => 'zoom' );
    }

    return if not -f $source_file;

    my $target_file = $self->preview_filename( type => $type );

    my $catch = $self->system( command => "identify $source_file" );
    my ( $width, $height );
    ( $width, $height ) = ( $catch =~ /\s+(\d+)x(\d+)\s+/ );

    my ( $top, $bottom, $left, $right );
    if ( $type eq 'clip1' ) {
        $top    = $self->tc_clip1_top;
        $bottom = $self->tc_clip1_bottom;
        $left   = $self->tc_clip1_left;
        $right  = $self->tc_clip1_right;
    }
    else {
        $top    = $self->tc_clip2_top;
        $bottom = $self->tc_clip2_bottom;
        $left   = $self->tc_clip2_left;
        $right  = $self->tc_clip2_right;
    }

    my $new_width  = $width - $left - $right;
    my $new_height = $height - $top - $bottom;

    my $command = "convert $source_file -crop "
        . "${new_width}x${new_height}+$left+$top "
        . $target_file;

    $self->system( command => "convert $source_file -crop "
            . "${new_width}x${new_height}+$left+$top "
            . $target_file );

    1;
}

sub make_preview_zoom {
    my $self = shift;
    my %par = @_;

    my $source_file = $self->preview_filename( type => 'clip1' );
    my $target_file = $self->preview_filename( type => 'zoom' );

    my $new_width  = $self->tc_zoom_width;
    my $new_height = $self->tc_zoom_height;

    if ( not $new_width or not $new_height ) {
        copy( $source_file, $target_file );
        return 1;
    }

    my $catch = $self->system( command => "identify $source_file" );

    $self->system( command => "convert $source_file -geometry "
            . "'${new_width}!x${new_height}!' "
            . $target_file );

    1;
}

sub get_make_preview_command {
    my $self   = shift;
    my %par    = @_;
    my ($type) = @par{'type'};

    my $command;
    if ( $type =~ /clip/ ) {
        my ( $top, $bottom, $left, $right, $source_file );
        if ( $type eq 'clip1' ) {
            $source_file = $self->preview_filename( type => 'orig' );
            $top         = $self->tc_clip1_top;
            $bottom      = $self->tc_clip1_bottom;
            $left        = $self->tc_clip1_left;
            $right       = $self->tc_clip1_right;
        }
        else {
            $source_file = $self->preview_filename( type => 'zoom' );
            $top         = $self->tc_clip2_top;
            $bottom      = $self->tc_clip2_bottom;
            $left        = $self->tc_clip2_left;
            $right       = $self->tc_clip2_right;
        }

        $top    ||= "0";
        $bottom ||= "0";
        $left   ||= "0";
        $right  ||= "0";

        my $target_file = $self->preview_filename( type => $type );
        return "execflow dvdrip-thumb $source_file $target_file "
            . "$top $right $bottom $left";
    }
    elsif ( $type eq 'zoom' ) {
        my $source_file = $self->preview_filename( type => 'clip1' );
        my $target_file = $self->preview_filename( type => 'zoom' );
        my $new_width  = $self->tc_zoom_width  || $self->width;
        my $new_height = $self->tc_zoom_height || $self->height;
        return "execflow dvdrip-thumb $source_file $target_file "
            . "$new_width $new_height";
    }
}

sub get_make_previews_command {
    my $self = shift;

    return $self->get_make_preview_command( type => 'clip1' ) . " && "
        . $self->get_make_preview_command( type  => 'zoom' ) . " && "
        . $self->get_make_preview_command( type  => 'clip2' );
}

#---------------------------------------------------------------------

sub remove_vob_files {
    my $self = shift;

    my $vob_dir = $self->vob_dir;

    unlink(<$vob_dir/*>);

    1;
}

sub get_remove_vobs_command {
    my $self = shift;

    my $vob_dir = $self->vob_dir;

    my $command = "rm $vob_dir/* && echo EXECFLOW_OK";

    return $command;
}

sub get_view_dvd_command {
    my $self           = shift;
    my %par            = @_;
    my ($command_tmpl) = @par{command_tmpl};

    my $nr            = $self->nr;
    my $audio_channel = $self->audio_channel;
    my $base_audio_code;

    if ( $self->audio_track->type eq 'lpcm' ) {
        $base_audio_code = 160;

    }
    elsif ( $self->audio_track->type eq 'mpeg1' ) {
        $base_audio_code = 0;

    }
    else {
        $base_audio_code = 128;
    }

    my @opts = (
        {   t => $self->nr,
            a => $self->audio_channel,
            m => $self->tc_viewing_angle,
            b => $base_audio_code,
            d => quotemeta($self->project->dvd_device),
        }
    );

    if ( $self->tc_use_chapter_mode eq 'select' ) {
        my $chapters = $self->tc_selected_chapters;
        use Data::Dumper;
        print Dumper($chapters);
        if ( not $chapters or not @{$chapters} ) {
            return "echo 'no chapters selected'";
        }
        push @opts, { c => $_ } foreach @{$chapters};
    }
    else {
        push @opts, { c => 1 };
    }

    my $command = $self->apply_command_template(
        template => $command_tmpl,
        opts     => \@opts,
    );

    return $command;
}

sub get_view_avi_command {
    my $self = shift;
    my %par  = @_;
    my ( $command_tmpl, $file ) = @par{ 'command_tmpl', 'file' };

    my @filenames;
    if ($file) {
        @filenames = ($file);

    }
    elsif ( $self->tc_use_chapter_mode ) {
        my $chapters = $self->get_chapters;
        my $filename;
        foreach my $chapter ( @{$chapters} ) {
            $self->set_actual_chapter($chapter);
            $filename = $self->avi_file;
            push @filenames, $filename if -f $filename;
        }
        $self->set_actual_chapter(undef);

    }
    else {
        my $filename = $self->avi_file;
        my $ext      = $self->get_target_ext;
        $filename =~ s/\.[^.]+$//;
        push @filenames, grep !/dvdrip-info/, glob( "${filename}*" . $ext );
    }

    croak "msg:" . __ "You first have to transcode this title."
        if not @filenames;

    my @opts = ( {} );
    push @opts, { f => $_ } for @filenames;

    my $command = $self->apply_command_template(
        template => $command_tmpl,
        opts     => \@opts,
    );

    return $command;
}

sub get_view_stdin_command {
    my $self           = shift;
    my %par            = @_;
    my ($command_tmpl) = @par{'command_tmpl'};

    my $audio_channel = $self->audio_channel;

    my @opts = ( { a => 0, } );

    my $command = $self->apply_command_template(
        template => $command_tmpl,
        opts     => \@opts,
    );

    my $opts
        = $self->get_frame_grab_options( frame => $self->preview_frame_nr, );

    my $source_options = $self->data_source_options;

    my $T;
    $T = "-T $source_options->{T}" if $source_options->{T};

    $command = "tccat -i $source_options->{i}" . " $T"
        . " -a $audio_channel -S $opts->{L} | $command";

    return $command;
}

sub get_view_vob_image_command {
    my $self           = shift;
    my %par            = @_;
    my ($command_tmpl) = @par{'command_tmpl'};

    my $nr            = $self->nr;
    my $audio_channel = $self->audio_channel;
    my $angle         = $self->tc_viewing_angle;

    my $command = "execflow tccat -i "
        . quotemeta($self->project->dvd_device)
        . " -a $audio_channel -L "
        . " -T $nr,1,$angle | $command_tmpl";

    return $command;
}

#---------------------------------------------------------------------
# CD burning stuff
#---------------------------------------------------------------------

sub get_burn_files {
    my $self = shift;

    my $cd_type = $self->burn_cd_type || 'iso';

    my $ogg_ext = $self->config('ogg_file_ext');

    my $mask =
        $cd_type eq 'iso' ? "*.{avi,$ogg_ext,iso,dvdrip-info,sub,ifo,idx,rar}"
        : $cd_type eq 'vcd' ? "*.{mpg,vcd}"
        : "*.{mpg,svcd}";

    $mask = $self->avi_dir . "/" . $mask;

    my @files = glob($mask);

    my @burn_files;
    my %files_per_group;
    my ($label, $abstract, $base, $group,
        $index, $is_image, $ext,  $chapter
    );

    foreach my $file ( sort @files ) {
        $base = basename($file);

        $base =~ /^(.*?)([_-]\d+)([_-](C?)\d+)?\.([^\.]+)$/;
        $index   = $3;
        $chapter = $4;
        $group   = "$1:$5";

        $base =~ /([^\.]+)$/;
        $ext = $1;

        $index =~ s/C//g;
        $index = $index * -1 if $index < 0;
        ++$files_per_group{$group};

        $is_image = $ext =~ /^(iso|vcd|svcd)$/;
        ++$index
            if $cd_type eq 'iso'
            and not $chapter;    # avi counting begins with 0

        $label = $base;
        $label =~ s/(-C?\d+)*\.[^\.]+$//;

        $abstract = $label;
        $abstract =~ s/_/ /g;
        $abstract =~ s/\b(.)/uc($1)/eg;

        $label .= "_$index" if not $is_image;

        push @burn_files,
            {
            name     => $base,
            label    => $label,
            abstract => $abstract,
            size => ( int( ( -s $file ) / 1024 / 1024 ) || 1 ),
            group    => $group,
            index    => $index,
            path     => $file,
            is_image => $is_image
            };
    }

    foreach my $file (@burn_files) {
        $file->{number}
            = "$file->{index} of " . $files_per_group{ $file->{group} };
    }

    return \@burn_files;
}

sub cd_image_file {
    my $self = shift;

    my $cd_type = $self->burn_cd_type;

    my @labels = map { $_->{label} }
        sort { $a->{label} cmp $b->{label} }
        values %{ $self->burn_files_selected };

    return $self->avi_dir . "/" . $labels[0] . ".$cd_type";
}

sub burning_an_image {
    my $self = shift;

    my $is_image;
    map { $is_image = 1 if $_->{is_image} }
        sort { $a->{path} cmp $b->{path} }
        values %{ $self->burn_files_selected };

    return $is_image;
}

sub get_create_image_command {
    my $self         = shift;
    my %par          = @_;
    my ($on_the_fly) = @par{'on_the_fly'};

    croak "msg:" . __ "No files for image creation selected."
        if not $self->burn_files_selected
        or not keys %{ $self->burn_files_selected };

    my $is_image;
    my @files = map { $is_image = 1 if $_->{is_image}; $_->{path} }
        sort { $a->{path} cmp $b->{path} }
        values %{ $self->burn_files_selected };

    die __ "No burn files selected."      if not @files;
    die __ "File is already an CD image." if $is_image;

    my $cd_type = $self->burn_cd_type;

    if ( $cd_type ne 'iso' and $on_the_fly ) {
        croak __ "Can't burn (S)VCD on the fly";
    }

    my $image_file = $self->cd_image_file;

    my $command;
    if ( $cd_type eq 'iso' ) {
        if ( $on_the_fly and $self->config('burn_estimate_size') ) {
            $command = 'SIZE=$(';
            $command .= $self->config('burn_mkisofs_cmd');
            $command .= " -quiet -print-size"
                . " -r -J -jcharset default -l -D -L" . " -V '"
                . $self->burn_label . "'"
                . " -abstract '"
                . $self->burn_abstract . " "
                . $self->burn_number . "'" . " "
                . join( " ", @files );
            $command .= ") && ";
            $command .= "execflow " . $self->config('burn_mkisofs_cmd');
            $command .= " -quiet";
            $command .= " -r -J -jcharset default -l -D -L" . " -V '"
                . $self->burn_label . "'"
                . " -abstract '"
                . $self->burn_abstract . " "
                . $self->burn_number . "'" . " "
                . join( " ", @files );
        }
        else {
            $command = "execflow " . $self->config('burn_mkisofs_cmd');
            $command .= " -quiet"         if $on_the_fly;
            $command .= " -o $image_file" if not $on_the_fly;
            $command .= " -r -J -jcharset default -l -D -L" . " -V '"
                . $self->burn_label . "'"
                . " -abstract '"
                . $self->burn_abstract . " "
                . $self->burn_number . "'" . " "
                . join( " ", @files );
        }
    }
    else {
        $command = "execflow "
            . $self->config('burn_vcdimager_cmd')
            . ( $cd_type eq 'svcd' ? ' --type=svcd' : ' --type=vcd2' )
            . " --iso-volume-label='"
            . uc( $self->burn_label ) . "'"
            . " --info-album-id='"
            . uc( $self->burn_abstract . " " . $self->burn_number ) . "'"
            . " --cue-file=$image_file.cue"
            . " --bin-file=$image_file" . " "
            . join( " ", @files );
    }

    $command .= " && echo EXECFLOW_OK" if not $on_the_fly;

    return $command;
}

sub get_burn_command {
    my $self = shift;

    croak "msg:" . __ "No files for burning selected."
        if not $self->burn_files_selected
        or not keys %{ $self->burn_files_selected };

    my $cd_type = $self->burn_cd_type;

    my $is_image;
    my @files = map { $is_image = 1 if $_->{is_image}; $_->{path} }
        sort { $a->{path} cmp $b->{path} }
        values %{ $self->burn_files_selected };

    die "msg:" . __ "No burn files selected." if not @files;

    my $command;
    if ( $cd_type eq 'iso' ) {
        if ( not $is_image ) {
            $command = $self->get_create_image_command( on_the_fly => 1 );
            $command .= " | " . $self->config('burn_cdrecord_cmd');
        }
        else {
            $command = "execflow " . $self->config('burn_cdrecord_cmd');
        }

        my $gracetime = $self->config('burn_cdrecord_cmd') =~ /cdrecord/
            ? 'gracetime=5'
            : '';

        $command .= " dev="
            . $self->config('burn_cdrecord_device')
            . " fs=4096k -v -overburn $gracetime"
            . " speed="
            . $self->config('burn_writing_speed')
            . " -eject -pad -overburn";

        $command .= " -dummy" if $self->config('burn_test_mode');

        $command .= ' tsize=${SIZE}s'
            if ( ( not $is_image ) and $self->config('burn_estimate_size') );

        if ( not $is_image ) {
            $command .= " -";
        }
        else {
            $command .= " $files[0]";
        }
    }
    else {
        $command = "rm -f $files[0].bin; ln -s $files[0] $files[0].bin && ";

        $command .= "execflow " . $self->config('burn_cdrdao_cmd');

        if ( $command !~ /\bwrite\b/ ) {
            $command .= " write";
        }

        $command .= " --device "
            . $self->config('burn_cdrecord_device')
            . " --speed "
            . $self->config('burn_writing_speed');

        $command .= " --driver " . $self->config('burn_cdrdao_driver')
            if $self->config('burn_cdrdao_driver');

        $command .= " --buffers " . $self->config('burn_cdrdao_buffers')
            if $self->config('burn_cdrdao_buffers');

        $command .= " --eject"    if $self->config('burn_cdrdao_eject');
        $command .= " --overburn" if $self->config('burn_cdrdao_overburn');
        $command .= " --simulate" if $self->config('burn_test_mode');

        $command .= " $files[0].cue" . " && rm $files[0].bin";
    }

    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub get_erase_cdrw_command {
    my $self = shift;

    my $blank_method = $self->config('burn_blank_method');
    ($blank_method) = $blank_method =~ /^\s*([^\s]+)/;

    my $command = $self->config('burn_cdrecord_cmd') . " dev="
        . $self->config('burn_cdrecord_device')
        . " blank=$blank_method";

    $command .= " -dummy" if $self->config('burn_test_mode');

    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub selected_subtitle {
    my $self = shift;
    return undef if not $self->subtitles;
    return undef if not defined $self->selected_subtitle_id;
    return $self->subtitles->{ $self->selected_subtitle_id };
}

sub get_cat_vob_command {
    my $self = shift;

    my $rip_mode = $self->project->rip_mode;

    my $cat;
    if ( $rip_mode eq 'rip' ) {
        $cat = "cat " . $self->vob_dir . "/*";

    }
    else {
        $cat = "execflow tccat -i "
            . $self->project->rip_data_source . " -T "
            . $self->tc_title_nr;
    }

    return $cat;
}

sub get_subtitle_grab_images_command {
    my $self = shift;

    my $subtitle = $self->selected_subtitle;

    my $timecode = $subtitle->tc_preview_timecode;
    my $cnt      = $subtitle->tc_preview_img_cnt;
    my $sid      = sprintf( "0x%02x", $subtitle->id + 32 );

    my $sub_dir = $self->get_subtitle_preview_dir;
    my $vob_dir = $self->vob_dir;

    if ( $timecode !~ /^\d\d:\d\d:\d\d$/ ) {
        my $frames  = $timecode + 0;
        my $seconds = int( $frames / $self->tc_video_framerate );
        $timecode = $self->format_time( time => $seconds );
    }

    $cnt = 0 + $cnt;
    $cnt ||= 1;

    my $cat = $self->get_cat_vob_command;

    my $command = "mkdir -p $sub_dir && rm -f $sub_dir/*.{pgm,srtx} && "
        . " $cat | tcextract -x ps1 -t vob -a $sid |"
        . " subtitle2pgm -P -C 0 -o $sub_dir/pic -v -e $timecode,$cnt"
        . " 2>&1 | dvdrip-subpng && echo EXECFLOW_OK";

    return $command;
}

sub get_frame_of_sec {
    my $self = shift;
    my ($sec) = @_;

    my $frame = int( $sec * $self->frame_rate );

    $frame = 0 if $frame < 0;
    $frame = $self->frames - 1 if $frame >= $self->frames;

    return $frame;
}

sub get_subtitle_test_frame_range {
    my $self = shift;

    my $subtitle    = $self->selected_subtitle;
    my $image_cnt   = $subtitle->tc_test_image_cnt;
    my $first_entry = $subtitle->get_first_entry;
    my $nth_entry   = $subtitle->get_nth_entry($image_cnt);

    my $time_sec_from = $first_entry->get_time_sec;
    my $time_sec_to   = $nth_entry->get_time_sec;

    my $frame_from = $self->get_frame_of_sec( $time_sec_from - 15 );
    my $frame_to   = $self->get_frame_of_sec( $time_sec_to + 15 );

    $frame_to = $frame_from if $frame_to < $frame_from;

    return ( $frame_from, $frame_to );

}

sub get_subtitle_transcode_options {
    my $self = shift;

    my $subtitle = $self->get_render_subtitle;

    return "" if not $subtitle;

    my $command = " -J extsub="
        . $subtitle->id . ":"
        . ( $subtitle->tc_vertical_offset || 0 ) . ":"
        . ( $subtitle->tc_time_shift      || 0 ) . ":"
        . ( $subtitle->tc_antialias   ? "0" : "1" ) . ":"
        . ( $subtitle->tc_postprocess ? "1" : "0" );

    if ( $subtitle->tc_color_manip ) {
        $command .= ":"
            . ( $subtitle->tc_color_a        || 0 ) . ":"
            . ( $subtitle->tc_color_b        || 0 ) . ":"
            . ( $subtitle->tc_assign_color_a || 0 ) . ":"
            . ( $subtitle->tc_assign_color_b || 0 );
    }

    return $command;
}

sub get_subtitle_preview_dir {
    my $self = shift;
    my ($subtitle_id) = @_;

    $subtitle_id = $self->selected_subtitle_id if !defined $subtitle_id;

    if ( $self->tc_use_chapter_mode ) {
        return sprintf( "%s/subtitles/%03d-C%03d/%02d",
            $self->project->snap_dir, $self->nr,
            ( $self->actual_chapter || $self->get_first_chapter || 1 ),
            $subtitle_id );
    }
    else {
        return sprintf( "%s/subtitles/%03d/%02d",
            $self->project->snap_dir, $self->nr, $subtitle_id );
    }
}

sub get_render_subtitle {
    my $self = shift;

    return undef if not $self->subtitles;

    foreach my $subtitle ( values %{ $self->subtitles } ) {
        return $subtitle if $subtitle->tc_render;
    }

    return undef;
}

sub info_file {
    my $self = shift;

    my $info_file = $self->avi_file;

    $info_file =~ s/\.[^.]+$/.dvdrip-info/;
    $info_file .= ".dvdrip-info" if $info_file !~ /\./;

    return $info_file;
}

sub get_transcoded_video_width_height {
    my $self = shift;

    my $width  = $self->tc_zoom_width;
    my $height = $self->tc_zoom_height;

    $width  -= $self->tc_clip2_left + $self->tc_clip2_right;
    $height -= $self->tc_clip2_top + $self->tc_clip2_bottom;

    return ( $width, $height );
}

sub suggest_subtitle_on_black_bars {
    my $self = shift;

    my $subtitle = $self->get_render_subtitle;
    return 1 if not $subtitle;

    croak "msg:" . __ "No subtitle selected" if not $subtitle;

    my $clip2_top    = 0;
    my $clip2_bottom = 0;

    my $width  = $self->tc_zoom_width;
    my $height = $self->tc_zoom_height;

    my $rest = ( $height - $clip2_bottom - $clip2_top ) % 16;

    if ($rest) {
        if ( $rest % 2 ) {
            $clip2_bottom -= int( $rest / 2 ) + 1;
            $clip2_top    -= int( $rest / 2 );
        }
        else {
            $clip2_bottom -= $rest / 2;
            $clip2_top    -= $rest / 2;
        }
    }

    $self->set_tc_clip2_bottom($clip2_bottom);
    $self->set_tc_clip2_top($clip2_top);

    $subtitle->set_tc_vertical_offset(0);

    return 1;
}

sub suggest_subtitle_on_movie {
    my $self = shift;

    my $subtitle = $self->get_render_subtitle;
    return 1 if not $subtitle;

    croak "msg:" . __ "No subtitle selected" if not $subtitle;

    my $clip2_bottom = $self->tc_clip2_bottom;
    my $zoom_height  = $self->tc_zoom_height || $self->height;
    my $pre_zoom_height
        = $self->height - $self->tc_clip1_top - $self->tc_clip1_bottom;
    my $scale = $pre_zoom_height / $zoom_height;

    my $shift = int( $clip2_bottom * $scale );

    $shift = 0 if $shift < 0;

    $subtitle->set_tc_vertical_offset( $shift + 4 );

    return 1;
}

sub get_extract_ps1_stream_command {
    my $self       = shift;
    my %par        = @_;
    my ($subtitle) = @par{'subtitle'};

    my $vob_size = $self->get_vob_size;
    my $vob_dir  = $self->vob_dir;

    my $sid             = sprintf( "0x%x", 32 + $subtitle->id );
    my $vobsub_ps1_file = $subtitle->ps1_file;
    my $ifo_file        = $subtitle->ifo_file( nr => 0 );

    my $cat = $self->get_cat_vob_command;

    my $command = "$cat | "
        . "dvdrip-progress -m $vob_size -i 5 | "
        . "tcextract -x ps1 -t vob -a $sid > $vobsub_ps1_file && "
        . "echo EXECFLOW_OK";

    return $command;
}

sub get_create_vobsub_command {
    my $self = shift;
    my %par  = @_;
    my ( $subtitle, $start, $end, $file_nr )
        = @par{ 'subtitle', 'start', 'end', 'file_nr' };

    my $avi_dir = $self->avi_dir;

    my $sid = sprintf( "0x%x", 32 + $subtitle->id );
    my $vobsub_prefix   = $subtitle->vobsub_prefix( file_nr => $file_nr );
    my $vobsub_ifo_file = "$vobsub_prefix.ifo";
    my $vobsub_ps1_file = $subtitle->ps1_file;
    my $ifo_file        = $subtitle->ifo_file( nr => 0 );

    my $ps1_size = int( ( -s $vobsub_ps1_file ) / 1024 / 1024 + 1 );

    my $range = "";
    if ( defined $start and defined $end ) {
        $range = "-e $start,$end,0";
        $ps1_size = int( ( $end - $start ) / $self->runtime * $ps1_size + 1 );
        $vobsub_ifo_file = "$vobsub_prefix.ifo";
    }

    my $lang = $subtitle->lang;

    my $command = "mkdir -p $avi_dir && "
        . "cp $ifo_file $avi_dir/$vobsub_ifo_file && "
        . "cd $avi_dir && "
        . "chmod 644 $vobsub_ifo_file && "
        . "execflow cat $vobsub_ps1_file | "
        . "dvdrip-progress -m $ps1_size -i 1 | "
        . "subtitle2vobsub $range"
        . " -i $vobsub_ifo_file "
        . " -o $vobsub_prefix &&"
        . "sed 's/^id: /id: $lang/' < $vobsub_prefix.idx > vobsub$$.tmp && "
        . "mv vobsub$$.tmp $vobsub_prefix.idx && "
        . "echo EXECFLOW_OK";

    if ( $self->has("rar") ) {
        my $rar = $self->config('rar_command');
        $command
            .= " && $rar a $vobsub_prefix $vobsub_prefix.{idx,ifo,sub} && "
            . "rm $vobsub_prefix.{idx,ifo,sub}";
    }

    return $command;
}

sub get_view_vobsub_command {
    my $self       = shift;
    my %par        = @_;
    my ($subtitle) = @par{'subtitle'};

    my $avi_dir = $self->avi_dir;
    my $vob_dir = $self->vob_dir;

    my $vobsub_prefix = $subtitle->vobsub_prefix;

    my $command = "cd $avi_dir && "
        . "mplayer -vobsub $vobsub_prefix -vobsubid 0 $vob_dir/*";

    return $command;
}

sub get_split_files {
    my $self = shift;

    my $mask = $self->avi_file;
    $mask =~ s/\.([^\.]+)$//;
    my $ext = $1;
    $mask .= "-*.$ext";

    my @files = glob($mask);

    return \@files;
}

sub get_count_frames_in_files_command {
    my $self = shift;

    my $files = $self->get_split_files;

    my $command = "echo START";

    foreach my $file ( @{$files} ) {
        if ( $self->is_ogg ) {
            $command .= " && echo 'DVDRIP:OGG:$file' frames=\$(";
            $command .= " ogminfo -v -v $file 2>&1 |"
                . " grep 'v1.*granulepos' | wc -l )";
        }
        else {
            $command .= " && echo 'DVDRIP:AVI:$file' \$(";
            $command .= " tcprobe -H 10 -i $file 2>&1 | grep frames= )";
        }
    }

    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub has_vobsub_subtitles {
    my $self = shift;

    return 0 if not $self->subtitles;

    foreach my $subtitle ( values %{ $self->subtitles } ) {
        return 1 if $subtitle->tc_vobsub;
    }

    return 0;
}

sub get_create_wav_command {
    my $self = shift;

    return "echo 'No audio channel selected'"
        if $self->audio_channel == -1;

    my $audio_wav_file = $self->audio_wav_file;
    my $dir            = dirname($audio_wav_file);
    my $nr             = $self->nr;
    my $source         = $self->transcode_data_source;
    my $audio_nr       = $self->audio_track->tc_nr;

    my $source_options = $self->data_source_options;
    $source_options->{x} = "null";

    my $tc_nice = $self->tc_nice || 0;

    my $command = "mkdir -p $dir &&"
        . " execflow -n $tc_nice transcode -a $audio_nr "
        . $self->get_transcode_status_option(200)
        . " -y null,wav -u 100 -o $audio_wav_file";

    $command .= " -$_ $source_options->{$_}" for keys %{$source_options};

    $command .= " -d"
        if $self->audio_track->type eq 'lpcm'
        and $self->version("transcode") < 613;

    if (   $self->tc_start_frame ne ''
        or $self->tc_end_frame ne '' ) {
        my $start_frame = $self->tc_start_frame;
        my $end_frame   = $self->tc_end_frame;
        $start_frame ||= 0;
        $end_frame   ||= $self->frames;

        if ( $start_frame != 0 ) {
            my $options
                = $self->get_frame_grab_options( frame => $start_frame );
            $options->{c} =~ /(\d+)/;
            my $c1 = $1;
            my $c2 = $c1 + $end_frame - $start_frame;
            $command .= " -c $c1-$c2";
            $command .= " -L $options->{L}"
                if $options->{L} ne '';

        }
        else {
            $command .= " -c $start_frame-$end_frame";
        }
    }

    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub check_svcd_geometry {
    my $self = shift;

    return if not $self->tc_container eq 'vcd';

    my $codec = $self->tc_video_codec;
    my $mode  = $self->video_mode;

    return if $codec =~ /^XS?VCD$/;

    my $width
        = ( $self->tc_zoom_width || $self->width ) - $self->tc_clip2_left
        - $self->tc_clip2_right;

    my $height
        = ( $self->tc_zoom_height || $self->height ) - $self->tc_clip2_top
        - $self->tc_clip2_bottom;

    my %valid_values = (
        "VCD:pal:width"  => 352,
        "VCD:pal:height" => 288,

        "VCD:ntsc:width"  => 352,
        "VCD:ntsc:height" => 240,

        "SVCD:pal:width"  => 480,
        "SVCD:pal:height" => 576,

        "SVCD:ntsc:width"  => 480,
        "SVCD:ntsc:height" => 480,

        "CVD:pal:width"  => 352,
        "CVD:pal:height" => 576,

        "CVD:ntsc:width"  => 352,
        "CVD:ntsc:height" => 480,
    );

    my $should_width  = $valid_values{"$codec:$mode:width"};
    my $should_height = $valid_values{"$codec:$mode:height"};

    $mode = uc($mode);

    if ( $width != $should_width or $height != $should_height ) {
        return __x(
            "Your frame size isn't conform to the standard,\n"
                . "which is {should_width}x{should_height} for {codec}/{mode}, "
                . "but you configured {width}x{height}.",
            should_width  => $should_width,
            should_height => $should_height,
            codec         => $codec,
            mode          => $mode,
            width         => $width,
            height        => $height
        );
    }

    return;
}

sub move_clip2_to_clip1 {
    my $self = shift;

    my $clip1_top    = $self->tc_clip1_top;
    my $clip1_bottom = $self->tc_clip1_bottom;
    my $clip1_left   = $self->tc_clip1_left;
    my $clip1_right  = $self->tc_clip1_right;

    if ( $clip1_top or $clip1_bottom or $clip1_left or $clip1_right ) {
        die "msg:"
            . __ "2nd clipping parameters can only be\nmoved to 1st "
            . "clipping parameters, if\n1st clipping is not defined.";
        return 1;
    }

    my $width  = $self->width;
    my $height = $self->height || 1;

    my $zoom_width  = $self->tc_zoom_width  || $self->width;
    my $zoom_height = $self->tc_zoom_height || $self->height;

    my $x_factor = $zoom_width / $width;
    my $y_factor = $zoom_height / $height;

    my $clip2_top    = $self->tc_clip2_top;
    my $clip2_bottom = $self->tc_clip2_bottom;
    my $clip2_left   = $self->tc_clip2_left;
    my $clip2_right  = $self->tc_clip2_right;

    my $clip1_top    = $clip2_top / $y_factor;
    my $clip1_bottom = $clip2_bottom / $y_factor;
    my $clip1_left   = $clip2_left / $x_factor;
    my $clip1_right  = $clip2_right / $x_factor;

    $width  = $width - $clip1_left - $clip1_right;
    $height = $height - $clip1_top - $clip1_bottom;

    $zoom_width  = $width * $x_factor;
    $zoom_height = $height * $y_factor;

    # no odd clip values
    if ( $clip1_left % 2 and $clip1_right % 2 ) {
        if ( $clip1_left > $clip1_right ) {
            --$clip1_left;
            ++$clip1_right;
        }
        else {
            ++$clip1_left;
            --$clip1_right;
        }
    }
    else {
        --$clip1_left  if $clip1_left % 2;
        --$clip1_right if $clip1_right % 2;
    }

    if ( $clip1_top % 2 and $clip1_bottom % 2 ) {
        if ( $clip1_left > $clip1_bottom ) {
            --$clip1_top;
            ++$clip1_bottom;
        }
        else {
            ++$clip1_top;
            --$clip1_bottom;
        }
    }
    else {
        --$clip1_top    if $clip1_top % 2;
        --$clip1_bottom if $clip1_bottom % 2;
    }

    $self->set_tc_clip1_top( int($clip1_top) );
    $self->set_tc_clip1_bottom( int($clip1_bottom) );
    $self->set_tc_clip1_left( int($clip1_left) );
    $self->set_tc_clip1_right( int($clip1_right) );
    $self->set_tc_zoom_width( int($zoom_width) );
    $self->set_tc_zoom_height( int($zoom_height) );
    $self->set_tc_clip2_top(0);
    $self->set_tc_clip2_bottom(0);
    $self->set_tc_clip2_left(0);
    $self->set_tc_clip2_right(0);

    1;
}

1;
