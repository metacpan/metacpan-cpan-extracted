# $Id: Context.pm 2365 2009-02-22 10:18:53Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Context;

use base Video::DVDRip::GUI::Base;

use Locale::TextDomain qw (video.dvdrip);
use File::Basename;
use Text::Wrap;

use strict;
use Carp;

my @BITRATE_PARAMS = (
    "title.tc_container",                   "title.tc_video_codec",
    "title.tc_video_bitrate_mode",          "title.tc_disc_cnt",
    "title.tc_disc_size",                   "title.tc_target_size",
    "title.tc_video_bitrate_range",         "title.tc_video_bpp_manual",
    "title.tc_video_bitrate_manual",        "title.tc_clip1_top",
    "title.tc_clip1_bottom",                "title.tc_clip1_left",
    "title.tc_clip1_right",                 "title.tc_zoom_width",
    "title.tc_zoom_height",                 "title.tc_clip2_top",
    "title.tc_clip2_bottom",                "title.tc_clip2_left",
    "title.tc_clip2_right",                 "title.tc_start_frame",
    "title.tc_end_frame",                   "audio_track.tc_audio_codec",
    "audio_track.tc_mp3_bitrate",           "audio_track.tc_mp2_bitrate",
    "audio_track.tc_ac3_bitrate",           "audio_track.tc_pcm_bitrate",
    "audio_track.tc_vorbis_bitrate",        "audio_track.tc_vorbis_quality",
    "audio_track.tc_vorbis_quality_enable", "multi_audio.matrix",
    "audio_track.bitrate",
);

my $NO_SUB_ACTIVE = __ "No subtitles activated.";

sub create {
    my $class = shift;

    my $config = $class->config_object;
    my $depend = $class->depend_object;

    #-- Create the Context
    my $context = Gtk2::Ex::FormFactory::Context->new(
        default_get_prefix => "",
        default_set_prefix => "set_",
    );

    #-- Add preferences Config object to Context
    $context->add_object(
        name     => "config",
        object   => undef,
        accessor => sub {
            my ( $config, $attr, $value ) = @_;
            if ( @_ == 2 ) {

                # getter
                return $config->get_value($attr);
            }
            else {

                # setter
                return $config->set_value( $attr, $value );
            }
        },
        attr_activity_href => {
            nptl_ld_assume_kernel => sub {
                $_[0]->get_value("workaround_nptl_bugs");
            },
        },
        attr_depends_href =>
            { nptl_ld_assume_kernel => "config.workaround_nptl_bugs", }
    );

    #-- Add depend object to Context
    $context->add_object(
        name                => "depend",
        object              => $depend,
        attr_accessors_href => {
            tools => sub {
                my $self = shift;
                my @data;
                my $tools = $self->tools;
                foreach my $tool (
                    sort { $tools->{$a}->{order} <=> $tools->{$b}->{order} }
                    keys %{$tools}
                    ) {
                    my $def = $tools->{$tool};
                    push @data,
                        [
                        $tool,
                        $def->{comment},
                        ( $def->{optional} ? __ "No" : __ "Yes" ),
                        $def->{suggested},
                        $def->{min},
                        ( $def->{max} || "-" ),
                        $def->{installed},
                        ( $def->{installed_ok} ? __ "Yes" : __ "No" ),
                        $def->{installed_ok}
                        ];
                }
                return \@data;
            },
        },
    );

    #-- Add JobPlanner Objects to the Contect
    $context->add_object(
        name              => "job_planner",
        object            => undef,
    );
    $context->add_object(
        name              => "exec_flow_gui",
        object            => undef,
    );

    #-- Add main GUI object to the Context
    $context->add_object(
        name              => "main",
        object            => "undef",
        attr_depends_href => { window_name => "project.name", },
    );

    #-- Add TOC GUI object to the Context
    $context->add_object(
        name   => "toc_gui",
        object => undef,
    );

    #-- Add progress GUI object to the Context
    $context->add_object(
        name   => "progress",
        object => undef,
    );

    #-- Add Clip & Zoom GUI object to the Context
    $context->add_object(
        name   => "clip_zoom",
        object => undef,
    );

    #-- Add Logging GUI object to the Context
    $context->add_object(
        name   => "logging",
        object => undef,
    );

    #-- Add Transcode GUI object to the Context
    $context->add_object(
        name   => "transcode",
        object => undef,
    );

    #-- Add Subtitle GUI object to the Context
    $context->add_object(
        name   => "subtitle_gui",
        object => undef,
    );

    #-- Add Zoom Calculator GUI object to the Context
    $context->add_object(
        name              => "zoom_calc",
        object            => undef,
        attr_depends_href => {
            result_list => [
                "zoom_calc.fast_resize_align",
                "zoom_calc.result_frame_align",
                "zoom_calc.achieve_result_align",
                "zoom_calc.auto_clip",
                @BITRATE_PARAMS,
            ],
        },
    );

    #-- Once the project directory is created, the project
    #-- name and directories must kept unchanged.
    my $project_dirs_unlocked = sub {
        $_[0]->name eq 'unnamed'
            || !-d $_[0]->snap_dir;
    };

    #-- Add !project object to Context (set to 1 if no project
    #-- is open, splash screen is associated with it)
    $context->add_object(
        name   => "!project",
        object => 1,
    );

    #-- Add project object to Context
    $context->add_object(
        name   => "project",
        object => undef,

        changes_attr_filter => qr[^last_selected_nb_page$],

        attr_depends_href => {
            vob_dir       => "project.name",
            avi_dir       => "project.name",
            snap_dir      => "project.name",
        },
        attr_activity_href => {
            name          => $project_dirs_unlocked,
            vob_dir       => $project_dirs_unlocked,
            avi_dir       => $project_dirs_unlocked,
            snap_dir      => $project_dirs_unlocked,
        },
    );

    #-- Add content to Context
    $context->add_object(
        name          => "content",
        aggregated_by => "project.content",

        #-- We override some attribute accessors here, which need
        #-- some transformation before being displayed.
        attr_accessors_href => {

            #-- This builds the table of contents on the Title page
            titles => sub {
                my $self = shift;
                my ( @slist_data, $t );
                return [] unless $self->titles;
                foreach my $nr ( sort { $a <=> $b } keys %{ $self->titles } )
                {
                    $t = $self->titles->{$nr};
                    push @slist_data,
                        [
                        $nr - 1,
                        $nr,
                        $class->format_time( time => $t->runtime ),
                        uc( $t->video_mode ),
                        $t->chapters,
                        scalar( @{ $t->audio_tracks } ),
                        $t->frame_rate,
                        $t->aspect_ratio,
                        $t->frames,
                        $t->width . "x" . $t->height
                        ];
                }
                return \@slist_data;
            },
            selected_title_nr_list => sub {
                my $self = shift;
                return [] unless $self->titles;
                my @titles;
                foreach my $nr ( sort { $a <=> $b } keys %{ $self->titles } )
                {
                    push @titles,
                        [ $nr, __x( "DVD title #{nr}", nr => $nr ) ];
                }
                return \@titles;
            },
        },
        attr_depends_href => {
            selected_title =>
                [ "content.selected_titles", "content.selected_title_nr" ],
            selected_title_nr => "content.selected_titles",
            titles            => "content.selected_title_nr",
        },
    );

    #-- Add selected title to Context
    $context->add_object(
        name          => "title",
        aggregated_by => "content.selected_title",

        #-- We override some attribute accessors here, which need
        #-- some transformation before being displayed.
        attr_accessors_href => {

            #-- Audio channel list - for the audio selection popups
            #-- If not used for the widget on the Title/Ripping page,
            #-- the selected target track is added to each entry.
            audio_channel_list => sub {
                my $self = shift;
                my ($widget) = @_;

                my $audio_tracks      = $self->audio_tracks;
                my $with_target_track = $widget !~ /^audio_selection/;

                my @audio_list;
                my $i = 0;
                foreach my $audio ( @{$audio_tracks} ) {
                    push @audio_list, ($i+1).": "
                        . $audio->info( with_target => $with_target_track );
                    ++$i;
                }

                return \@audio_list;
            },

            #-- List of available viewing angles.
            tc_viewing_angle_list => sub {
                my $self = shift;
                my @viewing_angle_list;
                foreach my $angle ( 1 .. $self->viewing_angles ) {
                    push @viewing_angle_list,
                        [$angle, __x( "Angle {angle}", angle => $angle )];
                }
                return \@viewing_angle_list;
            },

            #-- List of available chapters for chapter selection.
            chapter_list => sub {
                my $self = shift;
                my @chapters_list;
                for ( my $i = 1; $i <= $self->chapters; ++$i ) {
                    my $len = $self->format_time(
                        time => int(
                            $self->chapter_frames->{$i} / $self->frame_rate
                        )
                    );
                    push @chapters_list,
                        [
                            $i, 
                            __x("#{chapter} [{len}]",
                                chapter => $i,
                                len     => $len
                            )
                        ];
                }
                return \@chapters_list;
            },

            #-- List of subtitle languages
            subtitle_languages => sub {
                my $self            = shift;
                my $title_sub_langs = $self->get_subtitle_languages;
                my @lang            = sort keys %{$title_sub_langs};
                my @lang_list;
                push @lang_list, [$_] for grep !/\?\?/, @lang;
                return \@lang_list;
            },

            #-- List of available subtitles for subtitle selection
            selected_subtitle_id_list => sub {
                my $self = shift;
                my %subtitles;
                foreach my $subtitle ( values %{ $self->subtitles } ) {
                    $subtitles{ $subtitle->id } = $subtitle->info;
                }
                foreach my $id ( 0 .. 31 ) {
                    next if $subtitles{$id};
                    $subtitles{$id} = __x(
                        "{id} - ?? - probably unused",
                        id => sprintf( "%02d", $id )
                    );
                }
                return \%subtitles;
            },

            #-- Create Subtitle object on the fly if not yet there
            set_selected_subtitle_id => sub {
                my $self = shift;
                my ($id) = @_;

                if ( !$self->subtitles->{$id} ) {
                    $self->subtitles->{$id} = Video::DVDRip::Subtitle->new(
                        id    => $id,
                        lang  => "??",
                        title => $self,
                    );
                }

                $self->set_selected_subtitle_id($id);
                return $id;
            },

            #-- List of available Clip & Zoom Presets
            preset_list => sub {
                my $presets = $config->presets;
                my @presets;
                push @presets, $_->{title} for @{$presets};
                return \@presets;
            },

            #-- Get current selected preset
            preset => sub {
                my ($title) = @_;
                my $preset = $title->preset;
                my $i;
                for ( $i = 0; $i < @{ $config->presets }; ++$i ) {
                    last if $config->presets->[$i]->{name} eq $preset;
                }
                return $i;
            },

            #-- Set selected preset
            set_preset => sub {
                my ( $title, $idx ) = @_;
                $title->set_preset( $config->presets->[$idx]->{name} );
            },

            #-- List of available containers
            tc_container_list =>
                [ [ "avi", "AVI", ], [ "ogg", "OGG", ], [ "vcd", "MPEG", ], ],

            #-- Video Codec presets
            tc_video_codec_presets => sub {
                my ($title) = @_;
                return [ "SVCD", "VCD", "XSVCD", "XVCD", "CVD" ]
                    if $title->tc_container eq 'vcd';
                return [
                    "divx4", "divx5",  "xvid", "xvid2", "xvid3",
                    "xvid4", "ffmpeg", "fame", "af6"
                ];
            },

            #-- Button for xvid4conf
            video_codec_details => "",

            #-- Keyframe Interval presets
            tc_keyframe_interval_presets => [ 25, 50, 100, 150, 250 ],

            #-- Video framerate presets
            tc_video_af6_codec_presets => [ "mpeg4", "h264" ],

            #-- ffmpeg video codec presets
            tc_video_framerate_presets => [ "25", "23.976", "29.97" ],

            #-- List of deinterlacers
            tc_deinterlace_list => [
                [ 0 => __ "No deinterlacing" ],
                [ 1 => __ "Interpolate scanlines (fast)" ],
                [ 3 => __ "Zoom to full frame (slow)" ],
                [ 5 => __ "Interpolate scanlines / blend frames (pp=lb)" ],
                [   '32detect' => __
                        "Automatic deinterlacing of single frames"
                ],
                [ 'smart' => __ "Smart deinterlacing" ],
                [ 'ivtc'  => __ "Inverse telecine" ],
            ],

            #-- Video bitrate calculation mode
            tc_video_bitrate_mode => sub {
                my $mode = shift->tc_video_bitrate_mode;
                return 0 if $mode eq 'size';
                return 1 if $mode eq 'bpp';
                return 2 if $mode eq 'manual';
                return 0;
            },

            #-- Video bitrate calculation mode
            set_tc_video_bitrate_mode => sub {
                my ( $title, $notebook_page ) = @_;
                my $mode;
                $mode = 'size'   if $notebook_page == 0;
                $mode = 'bpp'    if $notebook_page == 1;
                $mode = 'manual' if $notebook_page == 2;
                $title->set_tc_video_bitrate_mode($mode);
                return $mode;
            },

            #-- Target media count popup
            tc_disc_cnt_list => [
                [ 1, __ "One" ],
                [ 2, __ "Two" ],
                [ 3, __ "Three" ],
                [ 4, __ "Four" ]
            ],

            #-- Target media size combo presets
            tc_disc_size_presets => [
                "650", "700", "800", "850", "2290", "4580", "6870", "9160"
            ],

            #-- BPP presets
            tc_video_bpp_manual_presets => [
                reverse qw(
                    0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50
                    0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00
                    )
            ],

            #-- Nice level presets
            tc_nice_presets => [
                qw(
                    0  1  2  3  4  5  6
                    7  8  9 10 11 12 13
                    14 15 16 17 18 19
                    )
            ],

            #-- Make storage_total_size bold
            storage_total_size => sub {
                "<b>" . $_[0]->storage_total_size . "</b>";
            },

            #-- Label listing all activated subtitles
            subtitles_activated => sub {
                my $self      = shift;
                my $subtitles = $self->subtitles;
                return __ "No subtitles available"
                    unless scalar( keys %{$subtitles} );
                my $selected_label;
                foreach my $subtitle ( sort { $a->id <=> $b->id }
                    values %{$subtitles} ) {
                    if ( $subtitle->tc_render ) {
                        $selected_label
                            .= $subtitle->info . " (" . __("render") . ") | ";
                    }
                    elsif ( $subtitle->tc_vobsub ) {
                        $selected_label
                            .= $subtitle->info . " (" . __("vobsub") . ") | ";
                    }
                }
                $selected_label =~ s/\| $//;
                $selected_label ||= $NO_SUB_ACTIVE;
                return $selected_label;
            },

            #-- Checks whether a subtitle may be activated for rendering
            subtitle_render_ok => sub {
                my $self = shift;
                my $subtitle = $self->selected_subtitle or return 0;
                return 0 if $subtitle->tc_vobsub;
                return 1 if $subtitle->tc_render;
                for ( values %{ $self->subtitles } ) {
                    return 0 if $_->tc_render;
                }
                return 1;
                1;
            },
        },

        attr_activity_href => {

            #-- Chapter list is active only for the 'select'
            #-- chapter mode.
            chapter_list => sub {
                $_[0]->tc_use_chapter_mode eq 'select';
            },

            #-- Subtitle languages list is active only for the 'lang'
            #-- subtitle mode.
            subtitle_languages => sub {
                $_[0]->has_subtitles &&
                $_[0]->tc_rip_subtitle_mode eq 'lang';
            },

            #-- ffmpeg/af6 codec depends on Video codec
            tc_video_af6_codec => sub {
                $_[0]->tc_video_codec =~ /ffmpeg|af6/;
            },

            #-- Button for xvid4conf
            video_codec_details => sub {
                $_[0]->tc_video_codec =~ /xvid4/;
            },

            #-- Preview Images
            preview_filename_clip1 => sub { -f $_[0]->preview_filename_orig },
            preview_filename_zoom => sub { -f $_[0]->preview_filename_clip1 },
            preview_filename_clip2 => sub { -f $_[0]->preview_filename_zoom },

            #-- multipass only with non MPEG files
            tc_multipass => sub { ! $_[0]->is_mpeg }, # &&
#                                    $_[0]->tc_video_af6_codec ne 'h264' },

            #-- reuse log active only with 2pass encoding
            tc_multipass_reuse_log => sub { $_[0]->tc_multipass &&
                                            ! $_[0]->is_mpeg }, #  &&
#                                              $_[0]->tc_video_af6_codec ne 'h264' },

            #-- fast resizing
            tc_fast_resize => sub { $_[0]->fast_resize_possible },
        },
        attr_depends_href => {

            #-- So the chapter_list attribute depends
            #-- on the current chapter mode, same
            #-- for subtitle languages
            chapter_list       => "title.tc_use_chapter_mode",
            subtitle_languages => "title.tc_rip_subtitle_mode",

            #-- The preview lables depend on the
            #-- corresponding clip/zoom values
            preview_label_clip1 => [
                "title.tc_clip1_top",  "title.tc_clip1_bottom",
                "title.tc_clip1_left", "title.tc_clip1_right",
            ],
            preview_label_zoom => [
                "title.tc_clip1_top",  "title.tc_clip1_bottom",
                "title.tc_clip1_left", "title.tc_clip1_right",
                "title.tc_zoom_width", "title.tc_zoom_height",
            ],
            preview_label_clip2 => [
                "title.tc_clip1_top",  "title.tc_clip1_bottom",
                "title.tc_clip1_left", "title.tc_clip1_right",
                "title.tc_zoom_width", "title.tc_zoom_height",
                "title.tc_clip2_top",  "title.tc_clip2_bottom",
                "title.tc_clip2_left", "title.tc_clip2_right",
            ],

            #-- audio_track depends on audio_channel setting
            audio_track => "title.audio_channel",

            #-- audio_channel_list depends on audio matrix
            audio_channel => "multi_audio.matrix",

            #-- Video codec changes when container changes
            tc_video_codec => "title.tc_container",

            #-- ffmpeg/af6 codec depends on Video codec
            tc_video_af6_codec => ["title.tc_video_codec"],

            #-- Button for xvid4conf depends on Video codec
            video_codec_details => ["title.tc_video_codec"],

            #-- Target size depends on media cnt and size
            tc_target_size => [ "title.tc_disc_cnt", "title.tc_disc_size" ],

            #-- Video bitrate, bpp and storage depend on several
            #-- input parameters
            tc_video_bitrate        => \@BITRATE_PARAMS,
            tc_video_bpp            => \@BITRATE_PARAMS,
            storage_video_size      => \@BITRATE_PARAMS,
            storage_audio_size      => \@BITRATE_PARAMS,
            storage_other_size      => \@BITRATE_PARAMS,
            storage_total_size      => \@BITRATE_PARAMS,
            tc_video_bitrate_manual => "tc_video_codec",

            #-- multipass depends on container
            tc_multipass => [ "tc_container", "tc_video_af6_codec" ],
            
            #-- reuse log active only with 2pass encoding
            tc_multipass_reuse_log => [ "tc_container", "tc_multipass", "tc_video_af6_codec" ],

            #-- fast resizing depends on a bunch of parameters
            tc_fast_resize => [
                "tc_clip1_left", "tc_clip1_right",
                "tc_clip1_top",  "tc_clip1_bottom",
                "tc_zoom_width", "tc_zoom_height"
            ],

            #-- Selected subtitles depends on the selected ID
            selected_subtitle => "selected_subtitle_id",

            #-- Info of activated subtitles
            subtitles_activated =>
                [ "subtitle.tc_render", "subtitle.tc_vobsub" ],
        },
    );

    my %audio_codecs = (
        0      => "mp3",
        1      => "mp2",
        2      => "vorbis",
        3      => "ac3",
        4      => "pcm",
        mp3    => 0,
        mp2    => 1,
        vorbis => 2,
        ac3    => 3,
        pcm    => 4,
    );

    $context->add_object(
        name                => "audio_track",
        aggregated_by       => "title.audio_track",
        attr_accessors_href => {
            tc_mp3_bitrate_presets =>
                [ 64, 96, 128, 160, 192, 224, 256, 320, 384 ],
            tc_mp2_bitrate_presets =>
                [ 64, 96, 128, 160, 192, 224, 256, 320, 384 ],
            tc_mp3_samplerate_presets => [ 24000, 44100, 48000, ],
            tc_vorbis_bitrate_presets =>
                [ 64, 96, 128, 160, 192, 224, 256, 320, 384 ],
            tc_vorbis_samplerate_presets => [ 24000, 44100, 48000, ],
            tc_audio_codec => sub { $audio_codecs{ shift->tc_audio_codec } },
            set_tc_audio_codec =>
                sub { $_[0]->set_tc_audio_codec( $audio_codecs{ $_[1] } ) },
            tc_audio_filter_list => {
                'rescale'   => __ "None, volume rescale only",
                'a52drc'    => __ "Range compression (liba52 filter)",
                'normalize' => __ "Normalizing (mplayer filter)",
            },
            tc_mp3_quality_list => {
                0 => "0 - " . __ "best but slower",
                1 => "1",
                2 => "2",
                3 => "3",
                4 => "4",
                5 => "5 - " . __ "medium",
                6 => "6",
                7 => "7",
                8 => "8",
                9 => "9 - " . __ "low but faster",
            },
            tc_vorbis_quality_presets => [
                -1,   0,    1.00, 2.00, 3.00, 4.00,
                5.00, 6.00, 7.00, 8.00, 9.00, 10.00
            ],
        },
        attr_activity_href => {
            audio_codec_mp3_form => sub {
                $context->get_object("title")->tc_container ne 'vcd';
            },
            audio_codec_mp2_form => sub {
                $context->get_object("title")->tc_container eq 'vcd';
            },
            audio_codec_vorbis_form => sub {
                $context->get_object("title")->tc_container eq 'ogg';
            },
            audio_codec_ac3_form => sub {
                $context->get_object("title")->tc_container ne 'vcd'
            },
            audio_codec_pcm_form => sub {
                $context->get_object("title")->tc_container ne 'vcd'
                    && shift->pcm_ok;
            },
            bitrate           => 0,
            sample_rate       => 0,
            tc_vorbis_bitrate => sub {
                !$context->get_object("audio_track")
                    ->tc_vorbis_quality_enable;
            },
            tc_vorbis_quality => sub {
                $context->get_object("audio_track")->tc_vorbis_quality_enable;
            },
            tc_mp2_samplerate => 0,
        },
        attr_depends_href => {
            audio_codec_mp3_form    => ["title.tc_container"],
            audio_codec_mp2_form    => ["title.tc_container"],
            audio_codec_vorbis_form => ["title.tc_container"],
            audio_codec_ac3_form    => ["title.tc_container"],
            audio_codec_pcm_form    => ["title.tc_container"],
            tc_vorbis_bitrate => ["audio_track.tc_vorbis_quality_enable"],
            tc_vorbis_quality => ["audio_track.tc_vorbis_quality_enable"],
            tc_volume_rescale => ["audio_track.tc_audio_filter"],
        },
    );

    #-- Add Bitrate Calculation object to the Context
    $context->add_object(
        name   => "bitrate_calc",
        object => sub { $context->get_object("title")->bitrate_calc },
        attr_accessors_href => {
            sheet => sub {
                my $bc    = shift;
                my $sheet = $bc->sheet;
                my @data;
                push @data,
                    [ $_->{label}, $_->{operator}, $_->{value}, $_->{unit} ]
                    for @{$sheet};
                return \@data;
                }
        },
        attr_depends_href => {
            sheet => [
                "title",
                "content.selected_title_nr", "content.selected_titles",
                "content.selected_title",    "title.tc_container",
                @BITRATE_PARAMS,
            ],
        },
    );

    #-- Add Multi Audio Matrix GUI object to the Context
    $context->add_object(
        name              => "multi_audio",
        object            => undef,
        attr_depends_href => {
            matrix => [
                "content.selected_title_nr", "content.selected_titles",
                "content.selected_title",
            ],
        },
    );

    #-- Add selected subtitle to the Context
    my $render_active_sub = sub { $_[0]->tc_render };
    my $color_active_sub  = sub { $_[0]->tc_render && $_[0]->tc_color_manip };

    $context->add_object(
        name                => "subtitle",
        object              => undef,
        aggregated_by       => "title.selected_subtitle",
        attr_accessors_href => {
            tc_assign_color_a_list => [ 0, 1, 2, 3 ],
            tc_assign_color_b_list => [ 0, 1, 2, 3 ],
            grab_button_label      => sub  {
                $_[0]->is_ripped ? __ "Show" : __ "Grab";
            },
        },
        attr_activity_href => {
            tc_vertical_offset => $render_active_sub,
            tc_time_shift      => $render_active_sub,
            tc_postprocess     => $render_active_sub,
            tc_antialias       => $render_active_sub,
            tc_color_manip     => $render_active_sub,
            tc_color_a         => $color_active_sub,
            tc_color_b         => $color_active_sub,
            tc_assign_color_a  => $color_active_sub,
            tc_assign_color_b  => $color_active_sub,
            tc_test_image_cnt  => $render_active_sub,

        },
        attr_depends_href => {
            tc_vertical_offset => "tc_render",
            tc_time_shift      => "tc_render",
            tc_postprocess     => "tc_render",
            tc_antialias       => "tc_render",
            tc_color_manip     => "tc_render",
            tc_color_a         => [ "tc_render", "tc_color_manip" ],
            tc_color_b         => [ "tc_render", "tc_color_manip" ],
            tc_assign_color_a  => [ "tc_render", "tc_color_manip" ],
            tc_assign_color_b  => [ "tc_render", "tc_color_manip" ],
            tc_test_image_cnt  => "tc_render",
        },
    );

    #-- Add FilterList object to Context
    $context->add_object(
        name   => "avail_filter_list",
        object => Video::DVDRip::FilterList->get_filter_list,
        attr_accessors_href => {
            filters => sub {
                my $filter_list = shift;
                my $filter_settings = $context->get_object("filter_settings");
                my @filters;
                my $filters_href = $filter_list->filters;
                foreach my $filter_name ( sort keys %{$filters_href} ) {
                    push @filters, [
                        $filter_name,
                        $filters_href->{$filter_name}->desc,
                        $filter_settings->filter_used( filter_name => $filter_name)
                            && !$filters_href->{$filter_name}->can_multiple,
                    ];
                }
                return \@filters;
            },
        },
    );

    #-- Filter Settings
    $context->add_object (
        name            => "filter_settings",
        object          => undef,
        aggregated_by   => "title.tc_filter_settings",
        attr_accessors_href => {
            filters => sub {
                my $tc_filter_settings = shift;

                my $selected_filters = $tc_filter_settings->get_selected_filters;

                my @filters;
	        foreach my $queue ( 'pre', 'post' ) {
		    my $filter;
                    push @filters, [
                        $queue, "-----------", uc($queue)
                    ];
		    foreach my $filter_instance ( @{$selected_filters} ) {
			eval { $filter = $filter_instance->get_filter };
			next if $@;	# if a filter doesn't exist anymore
			next if $filter_instance->queue ne $queue;
                        push @filters, [
			    $filter_instance->id,
			    $filter->filter_name,
			    $filter->desc,
                        ],
		    }
	        }
                
                return \@filters;
            },
        },
    );

    #-- Add preview window to context
    $context->add_object (
        name   => "filter_window",
        object => undef,
        attr_depends_href => {
            selected_avail_filter         => [ "selected_avail_filter_name"       ],
            selected_used_filter_instance => [ "selected_used_filter_instance_id" ],

            current_filter                => [ "selected_avail_filter_name",
                                               "selected_used_filter_instance_id" ],
#
#            current_filter_settings       => [ "selected_avail_filter_name",
#                                               "selected_used_filter_instance_id" ],
        },
        attr_accessors_href => {
            set_selected_avail_filter_name => sub {
                my $self = shift;
                my ($value) = @_;
                $self->set_selected_avail_filter_name($value);
                my $filter = $self->selected_avail_filter;
                $self->set_current_filter($filter);
                my $instance = $filter ? $filter->get_dummy_instance : undef;
                $self->set_current_filter_settings($instance);
#                $self->build_filter_settings_form;
                return $value;
            },
            set_selected_used_filter_instance_id => sub {
                my $self = shift;
                my ($value) = @_;
                $self->set_selected_used_filter_instance_id($value);
                my $instance = $self->selected_used_filter_instance;
                $self->set_current_filter_settings($instance);
#                $self->build_filter_settings_form;
                my $filter = $instance ? $instance->get_filter : undef;
                $self->set_current_filter($filter);
                return $value;
            },
        },
    );

    #-- Add selected filter instance to context
    $context->add_object (
        name          => "current_filter",
        object        => undef,
        aggregated_by => "filter_window.current_filter",
        attr_accessors_href => {
            desc => sub {
                my $self = shift;
                local $Text::Wrap::columns = 32;
                return wrap("","",$self->desc);
            },
            author => sub {
                my $self = shift;
                local $Text::Wrap::columns = 32;
                return wrap("","",$self->author);
            },
        },
    );

    #-- Add selected filter to context
    $context->add_object (
        name          => "current_filter_settings",
        object        => undef,
#        aggregated_by => "filter_window.current_filter_settings",
        accessor      => sub {
            my $self = shift;
            my ($attr, $value) = @_;
            if ( @_ == 2 ) {
                #-- setter
                my $setter = "set_$attr";
                return $self->$setter($value) if $self->can($setter);
                #-- filter setting?
                if ( $attr =~ /^filter_option_(.*)_(\d+)$/ ) {
                    return $self->set_value(
                        option_name => $1,
                        idx         => $2,
                        value       => $value
                    );
                }
                croak "Unknown FilterSettingsInstance attribute: $attr";
            }
            else {
                #-- getter
                my $getter = $attr;
                return $self->$getter() if $self->can($getter);
                #-- filter setting?
                if ( $attr =~ /^filter_option_(.*)_(\d+)$/ ) {
                    return $self->get_value(
                        option_name => $1,
                        idx         => $2,
                    );
                }
                croak "Unknown FilterSettingsInstance attribute: $attr";
            }
        },
    );

    #-- Add cluster control daemon object to Context
    $context->add_object(
        name   => "cluster",
        object => undef,
    );

    #-- Add cluster control daemon object to Context
    $context->add_object(
        name   => "!cluster",
        object => 1,
    );

    #-- Add cluster control GUI object to Context
    $context->add_object(
        name              => "cluster_gui",
        object            => undef,
        attr_depends_href => {
            selected_node    => "selected_node_name",
            selected_project => "selected_project_id",
            selected_job     => "selected_job_id",
            jobs_list        => "selected_project_id",
        },
    );

    #-- Add cluster node object to Context
    $context->add_object(
        name          => "cluster_node",
        aggregated_by => "cluster_gui.selected_node",
    );

    #-- Add cluster node object to Context
    $context->add_object(
        name          => "cluster_project",
        aggregated_by => "cluster_gui.selected_project",
    );

    #-- Add cluster node object to Context
    $context->add_object(
        name          => "cluster_job",
        aggregated_by => "cluster_gui.selected_job",
    );

    #-- Add currently edited cluster node object to Context
    $context->add_object(
        name               => "cluster_node_edited",
        buffered           => 1,
        attr_activity_href => {
            username => sub {
                !$context->get_object_attr("cluster_node_edited.is_master");
            },
            ssh_cmd => sub {
                !$context->get_object_attr("cluster_node_edited.is_master");
            },
        },
        attr_depends_href => {
            username => "is_master",
            ssh_cmd  => "is_master",
        },
    );

    #-- Add currently cluster node GUI object to Context
    $context->add_object(
        name     => "cluster_node_gui",
        buffered => 1,
    );

    #-- Add currently cluster title GUI object to Context
    $context->add_object(
        name     => "cluster_title_gui",
#        buffered => 1,
    );

    #-- Add currently edited cluster title object to Context
    $context->add_object( name => "cluster_title_edited", );

    #-- Add Preview Window to context
    $context->add_object (
        name => "preview_window",
        attr_accessors_href => {
            set_paused => sub { 1 },
        },
    );

    return $context;
}

1;
