# $Id: Transcode.pm 2344 2007-08-09 21:37:41Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Transcode;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->get_context->set_object( "transcode" => $self );

    return $self;
}

sub build_factory {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::VBox->new(
        $self->get_optimum_screen_size_options("page"),
        object      => "title",
        title       => '[gtk-convert]'.__ "Transcode",
        active_cond => sub {
            $self->selected_title
                && $self->project
                && $self->project->created;
        },
        active_depends => "project.created",
        no_frame       => 1,
        content        => [
            Video::DVDRip::GUI::Main->build_selected_title_factory,
            Gtk2::Ex::FormFactory::Table->new(
                expand => 1,
                layout => "
+>>>>>>>>>>>>>>>>>>>>>+>>>>>>>>>>>>>>>>>>>>>+
| Video & Bitrate     ^ Audio & General     |
+---------------------+---------------------|
^ Calculated Storage  | Operate             |
+---------------------+---------------------+
",
                content => [
                    Gtk2::Ex::FormFactory::VBox->new(
                        content => [
                            $self->build_container_factory,
                            $self->build_video_factory,
                            $self->build_video_bitrate_factory,
                        ],
                    ),
                    Gtk2::Ex::FormFactory::VBox->new(
                        content => [
                            $self->build_audio_factory,
                            $self->build_general_options_factory,
                        ],
                    ),
                    $self->build_calc_storage_factory,
                    $self->build_operate_factory,
                ],
            ),
        ],
    );
}

sub build_container_factory {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Form->new(
        title   => __ "Container options",
        content => [
            Gtk2::Ex::FormFactory::Popup->new(
                label       => __ "Select container",
                label_group => "video_labels",
                attr        => "title.tc_container",
                expand_h    => 0,
                width       => 70,
            ),
        ],
    );
}

sub build_video_factory {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Table->new(
        title      => __ "Video options",
        properties => { column_spacing => 5, },
        layout     => "
+>------------+[>--------------+[>--------------------+
| Codec Label | VC Popup       | Cfg Button           |
+-------------+[---------------+--------------+-------+
| ffmpeg Label| ffmpeg Entry   | KFI Label    | KFI   |
+-------------+[---------------+--------------+-------+
| FRate Label | Frame-Rate     |                      |
+-------------+[---------------+----------------------+
| 2pass Label | 2pass Yes/No   | Reuse log            | 
+-------------+----------------+----------------------+
| Deint Label | Deinterlacing                         |
+-------------+---------------------------------------+
| Filt Label  | Filters Button                        |
+-------------+---------------------------------------+
",
        content => [

            #-- 1st row
            Gtk2::Ex::FormFactory::Label->new(
                label       => __ "Video codec",
                label_group => "video_labels",
            ),
            Gtk2::Ex::FormFactory::Combo->new(
                attr  => "title.tc_video_codec",
                width => 80,
                tip   => __ "Choose a video codec here. If you don't "
                    . "find the codec you want in the list, just "
                    . "enter its transcode name by hand",
            ),
            Gtk2::Ex::FormFactory::Button->new(
                object => "title",
                label  => __ "Configure...",
                stock  => "gtk-preferences",
                tip => __ "The xvid4 video codec may be configured in detail "
                    . "if you have the xvid4conf utility installed",
                clicked_hook => sub {
                    $self->open_video_configure_window;
                },
                active_cond => sub {
                    $_[0] ? $_[0]->tc_video_codec =~ /^(xvid|xvid4)$/ : 0;
                },
                active_depends => ["title.tc_video_codec"],
            ),

            #-- 2nd row
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "ffmpeg/af6 codec",
                for   => "sibling(1)"
            ),
            Gtk2::Ex::FormFactory::Combo->new(
                attr  => "title.tc_video_af6_codec",
                width => 80,
                tip   => __ "Some transcode video export modules support "
                    . "multiple video codecs, e.g. the ffmpeg module. "
                    . "Enter the name of the video codec the module "
                    . "should use here"
            ),
            Gtk2::Ex::FormFactory::Label->new( label => __ "Keyframes", ),
            Gtk2::Ex::FormFactory::Combo->new(
                attr  => "title.tc_keyframe_interval",
                width => 50,
                tip   => __ "This setting controls the number of frames "
                    . "after which a keyframe should be inserted "
                    . "into the video stream. The lower this value "
                    . "the better the quality, but filesize may "
                    . "increase as well",
                rules => ["positive-integer"],
            ),

            #-- 3rd row
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Video framerate",
            ),
            Gtk2::Ex::FormFactory::Combo->new(
                attr  => "title.tc_video_framerate",
                width => 80,
                tip   => __ "This is the video framerate of this movie. "
                    . "Only change this if transcode detected the "
                    . "framerate wrong, which may happen sometimes. "
                    . "If you want true framerate conversion check "
                    . "out the Filters dialog, which provides some "
                    . "video filters for this task",
                rules => ["positive-float"],
            ),

            #-- 4th row
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "2-pass encoding",
            ),
            Gtk2::Ex::FormFactory::YesNo->new(
                attr => "title.tc_multipass",
                tip  => __ "2-pass encoding increases video quality and "
                    . "video bitrate accuracy significantly. But the "
                    . "whole transcoding needs nearly twice the time. "
                    . "It's strongly recommended to use 2-pass encoding "
                    . "whenever possible.",
                true_label => __"Yes",
                false_label  => __"No",
            ),
            Gtk2::Ex::FormFactory::CheckButton->new(
                label => __ "Reuse log",
                attr  => "title.tc_multipass_reuse_log",
                tip   => __ "During the first pass of a 2-pass transcoding "
                    . "a logfile with statistic information about the "
                    . "movie is written. If you didn't change any "
                    . "parameters affecting the video you may reuse "
                    . "this logfile for subsequent transcodings "
                    . "by activating this button. dvd::rip "
                    . "will skip the first pass saving much time."
            ),

            #-- 5th row
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Deinterlace mode",
            ),
            Gtk2::Ex::FormFactory::Popup->new(
                attr     => "title.tc_deinterlace",
                expand_h => 0,
                width    => 160,
                tip      => __ "Choose a deinterlacer algorithm here if the "
                    . "movie is interlaced, otherwise the transcoded "
                    . "movie is likely to have many artefacts. The "
                    . "'Smart deinterlacing' setting is recommended."
            ),

            #-- 5th row
            Gtk2::Ex::FormFactory::Label->new( label => __ "Filters", ),
            Gtk2::Ex::FormFactory::Button->new(
                object => "title",
                label => __ "Configure filters & preview...",
                tip   => __ "This opens a dialog which gives you access "
                    . "all filters transcode supports.",
                clicked_hook => sub {
                    $self->open_filters_window;
                },
            ),

        ],
    );
}

sub build_audio_factory {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Table->new(
        title  => __ "Audio options",
        object => "audio_track",
        layout => "
+-----------+>------------+-------+
| DVD Track | Popup       | Multi |
+---------------------------------+
| Settings Notebook               |
|                                 |
+---------------------------------+
",
        content => [
            Gtk2::Ex::FormFactory::Label->new( label => __ "Select track", ),
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "title.audio_channel",
                width => 120
            ),
            Gtk2::Ex::FormFactory::Button->new(
                label        => __ "Multi...",
                stock        => "dvdrip-audio-matrix",
                clicked_hook => sub {
                    $self->open_multi_audio_window;
                },
                tip => __ "Manage multiple audio tracks"
            ),
            Gtk2::Ex::FormFactory::Notebook->new(
                attr    => "audio_track.tc_audio_codec",
                changed_hook_after => sub {
                    my $audio_track = $self->get_context->get_object("audio_track");
                    return if ! $audio_track;
                    if ( $audio_track->tc_audio_codec =~ /^(?:ac3|pcm)$/ ) {
                        $self->detect_audio_bitrate
                            unless $audio_track->bitrate;
                    }
                },
                content => [
                    $self->build_audio_codec_settings( type => "mp3" ),
                    $self->build_audio_codec_settings( type => "mp2" ),
                    $self->build_audio_codec_settings( type => "vorbis" ),
                    $self->build_audio_codec_settings( type => "ac3" ),
                    $self->build_audio_codec_settings( type => "pcm" ),
                ],
            ),
        ],
    );
}

sub build_audio_codec_settings {
    my $self   = shift;
    my %par    = @_;
    my ($type) = @par{'type'};

    my ( $title, @additional_widgets );

    my $bitrate_entry_class    = "Gtk2::Ex::FormFactory::Combo";
    my $samplerate_entry_class = "Gtk2::Ex::FormFactory::Combo";
    my $bitrate_attr           = "tc_${type}_bitrate";
    my $samplerate_attr        = "tc_${type}_samplerate";
    my $changed_hook;

    if ( $type eq 'mp3' ) {
        $title = "MP3";
        push @additional_widgets,
            Gtk2::Ex::FormFactory::Popup->new(
            attr  => "audio_track.tc_mp3_quality",
            label => __ "Quality",
            ),
            ;
    }
    elsif ( $type eq 'mp2' ) {
        $title                  = "MP2";
        $samplerate_entry_class = "Gtk2::Ex::FormFactory::Entry";

    }
    elsif ( $type eq 'vorbis' ) {
        $title = "Vorbis";
        push @additional_widgets,
            Gtk2::Ex::FormFactory::HBox->new(
            label     => __ "Quality",
            label_for => "tc_vorbis_quality",
            content   => [
                Gtk2::Ex::FormFactory::Combo->new(
                    name  => "tc_vorbis_quality",
                    attr  => "audio_track.tc_vorbis_quality",
                    width => 70,
                    rules => ["positive-integer"],
                ),
                Gtk2::Ex::FormFactory::CheckButton->new(
                    attr  => "audio_track.tc_vorbis_quality_enable",
                    label => __ "Use quality mode",
                ),
            ],
            ),
            ;
    }
    else {
        my $codec = $type eq 'ac3' ? "AC3" : "PCM";
        my $bitrate_attr_method = $bitrate_attr;
        $title = $codec;
        push @additional_widgets,
            Gtk2::Ex::FormFactory::Label->new(
                label => __x(
                    "{ac3_or_pcm} sound is passed through. Bit- and\n"
                        . "samplerate are detected from source,\n"
                        . "so you can't change them here.",
                    ac3_or_pcm => $codec
                ),
            );
        $bitrate_entry_class    = "Gtk2::Ex::FormFactory::Entry";
        $samplerate_entry_class = "Gtk2::Ex::FormFactory::Entry";
        $bitrate_attr           = "bitrate";
        $samplerate_attr        = "sample_rate";
    }

    if ( $type ne 'ac3' and $type ne 'pcm' ) {
        push @additional_widgets, (
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "audio_track.tc_audio_filter",
                label => __ "Filter",
            ),
            Gtk2::Ex::FormFactory::HBox->new(
                label   => __ "Volume rescale",
                content => [
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "audio_track.tc_volume_rescale",
                        width => 70,
                        rules => [ "positive-float", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Scan value",
                        stock        => "dvdrip-scan-volume",
                        clicked_hook => sub {
                            $self->scan_rescale_volume;
                        },
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    ),
                ],
            ),
            ),
            ;
    }

    return Gtk2::Ex::FormFactory::Form->new(
        attr         => "audio_track.audio_codec_${type}_form",
        inactive     => "invisible",
        title        => $title,
        content      => [
            Gtk2::Ex::FormFactory::HBox->new(
                label   => __ "Bit-/Samplerate",
                content => [
                    $bitrate_entry_class->new(
                        name  => "bit_samplerate_$type",
                        attr  => "audio_track.$bitrate_attr",
                        width => 70,
                        rules => ["positive-integer"],
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "kbit/s",
                        for   => "bit_samplerate_$type",
                    ),
                    $samplerate_entry_class->new(
                        name  => $type . $samplerate_attr,
                        attr  => "audio_track.$samplerate_attr",
                        width => 70,
                        rules => ["positive-integer"],
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "hz",
                        for   => $type . $samplerate_attr,
                    ),
                ],
            ),
            @additional_widgets,
        ],
    );
}

sub build_video_bitrate_factory {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::Notebook->new(
        attr           => "title.tc_video_bitrate_mode",
        title          => __ "Video bitrate calculation",
        expand         => 1,
        active_cond    => sub { $_[0] ? $_[0]->tc_video_codec ne 'VCD' : 1 },
        active_depends => "title.tc_video_codec",
        content        => [
            Gtk2::Ex::FormFactory::Form->new(
                title   => __ "By target size",
                content => [
                    Gtk2::Ex::FormFactory::HBox->new(
                        label       => __ "Target media",
                        label_group => "vbr_calc_group",
                        content     => [
                            Gtk2::Ex::FormFactory::Popup->new(
                                attr  => "title.tc_disc_cnt",
                                width => 70,
                                tip   => __
                                    "Choose the desired number of discs here. "
                                    . "dvd::rip computes the target size from it "
                                    . "and optionally splits the result file accordingly.",
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                label => "x",
                            ),
                            Gtk2::Ex::FormFactory::Combo->new(
                                width => 60,
                                attr  => "title.tc_disc_size",
                                tip   => __
                                    "Select the size of your media here (several "
                                    . "CD and DVD form factors). The unit is a true "
                                    . "megabyte (1024KB). You may enter an arbitrary "
                                    . "value if the preset don't fit your needs.",
                                rules => [ "positive-integer", "not-zero" ],
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                label => __ "MB",
                            ),
                        ],
                    ),
                    Gtk2::Ex::FormFactory::HBox->new(
                        label       => __ "Target size",
                        label_group => "vbr_calc_group",
                        content     => [
                            Gtk2::Ex::FormFactory::Entry->new(
                                attr  => "title.tc_target_size",
                                width => 50,
                                tip   => __
                                    "This entry is computed based on the settings above, "
                                    . "but you may enter an arbitrary value as well.",
                                rules => [ "positive-integer", "not-zero" ],
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                label => __ "MB",
                            ),
                            Gtk2::Ex::FormFactory::CheckButton->new(
                                attr  => "title.tc_video_bitrate_range",
                                label => __ "Consider frame range",
                                tip   => __
                                    "If you specified a frame range in the 'General options' "
                                    . "section activate this checkbutton if the video bitrate "
                                    . "calculation should be based on this frame range, and not on "
                                    . "the full title length. You need this if you entered the frame "
                                    . "range not just for testing purposes but also for the final "
                                    . "transcoding, e.g. for cutting off credits."
                            ),
                        ],
                    ),
                ],
            ),
            Gtk2::Ex::FormFactory::Form->new(
                title   => __ "By quality",
                content => [
                    Gtk2::Ex::FormFactory::Combo->new(
                        attr        => "title.tc_video_bpp_manual",
                        label       => __ "BPP value",
                        label_group => "vbr_calc_group",
                        width       => 80,
                        expand_h    => 0,
                        tip         => __
                            "BPP stands for Bits Per Pixel and is a measure for "
                            . "the video quality. Values around 0.25 give fair results "
                            . "(VHS quality), 0.4-0.5 very good quality near DVD.",
                        rules => [ "positive-float", "not-zero" ],
                    ),
                ],
            ),
            Gtk2::Ex::FormFactory::Form->new(
                title   => __ "Manually",
                content => [
                    Gtk2::Ex::FormFactory::HBox->new(
                        label       => __ "Video bitrate",
                        label_group => "vbr_calc_group",
                        content     => [
                            Gtk2::Ex::FormFactory::Entry->new(
                                attr     => "title.tc_video_bitrate_manual",
                                width    => 60,
                                expand_h => 0,
                                tip      => __
                                    "If you don't want a calculated video bitrate "
                                    . "just enter an arbitrary value here.",
                                rules => [ "positive-integer", "not-zero" ],
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                label => __ "kbit/s",
                            ),
                        ],
                    ),
                ],
            ),
        ],
    );
}

sub build_general_options_factory {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::Form->new(
        title   => __ "General options",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::HBox->new(
                label   => __ "Frame range",
                content => [
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "title.tc_start_frame",
                        width => 60,
                        rules => [
                            "positive-integer",
                            "or-empty",
                            sub {
                                my ($start) = @_;
                                my $title   = $self->selected_title;
                                my $end     = $title->tc_end_frame;
                                return __x( "Movie has only {number} frames",
                                    number => $title->frames )
                                    if $start > $title->frames;
                                $end ne ''
                                    && $start >= $end
                                    ? __
                                    "Start frame number must be smaller than end frame number"
                                    : "";
                            },
                        ],
                    ),
                    Gtk2::Ex::FormFactory::Label->new( label => " - ", ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "title.tc_end_frame",
                        width => 60,
                        rules => [
                            "positive-integer",
                            "or-empty",
                            sub {
                                my ($end) = @_;
                                my $title = $self->selected_title;
                                my $start = $title->tc_start_frame;
                                return __x( "Movie has only {number} frames",
                                    number => $title->frames )
                                    if $end > $title->frames;
                                $start ne ''
                                    && $start >= $end
                                    ? __
                                    "End frame number must be greated than start frame number"
                                    : "";
                            },
                        ],
                    ),
                ],
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "title.tc_options",
                label => __ "transcode options",
                width => 20,
            ),
            Gtk2::Ex::FormFactory::Combo->new(
                attr     => "title.tc_nice",
                label    => __ "Process nice level",
                width    => 60,
                expand_h => 0,
                rules    => [ "integer", "or-empty" ],
            ),
            Gtk2::Ex::FormFactory::YesNo->new(
                attr  => "title.tc_preview",
                label => __ "Preview window",
                true_label => __"Yes",
                false_label  => __"No",
            ),
            Gtk2::Ex::FormFactory::YesNo->new(
                attr  => "title.tc_psu_core",
                label => __ "Use PSU core",
                true_label => __"Yes",
                false_label  => __"No",
            ),
            Gtk2::Ex::FormFactory::HBox->new(
                label   => __ "Execute afterwards",
                content => [
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr   => "title.tc_execute_afterwards",
                        expand => 1,
                        width  => 20,
                    ),
                    Gtk2::Ex::FormFactory::CheckButton->new(
                        attr  => "title.tc_exit_afterwards",
                        label => __ "and exit",
                    ),
                ],
            ),
        ],
    );
}

sub build_operate_factory {
    my $self = shift;

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Operate",
        content => [
            Gtk2::Ex::FormFactory::HBox->new(
                content => [
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Transcode",
                        stock        => "gtk-convert",
                        widget_group => "operate_buttons",
                        expand       => 1,
                        clicked_hook => sub {
                            $self->transcode;
                        },
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "View",
                        stock        => "gtk-media-play",
                        widget_group => "operate_buttons",
                        expand       => 1,
                        clicked_hook => sub {
                            $self->view_avi,;
                        },
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Add to cluster",
                        stock        => "gtk-network",
                        widget_group => "operate_buttons",
                        expand       => 1,
                        clicked_hook => sub {
                            $self->add_to_cluster;
                        },
                        active_cond    => sub {
                            my $title = $self->selected_title;
                            return 0 if not $title;
                            return $title->tc_container ne 'vcd';
                        },
                        active_depends => "title.tc_container",
                    ),
                ],
            ),
            Gtk2::Ex::FormFactory::CheckButton->new(
                attr  => "title.tc_split",
                label => __ "Split files on transcoding",
            ),

        ],
    );
}

sub build_calc_storage_factory {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Table->new(
        title  => __ "Calculated storage",
        layout => "
+>---------------+>--------]+>--+>---------------+>---------]+-----+
| V-Rate         | Value    | X | Video Size     |     Value | MB  |
+----------------+---------]+---+----------------+----------]+-----+
| BPP            | Value    |   | Audio Size     |     Value | MB  |
+----------------+----------+---+----------------+----------]+-----+
|                           |   | Other Size     |     Value | MB  |
+[---------------+----------+---+----------------+-----------+-----+
|                           |   | Separator                        |
|                           +---+----------------+----------]+-----+
_ Details                   |   | Total Size     |     Value | MB  |
+----------------+----------+---+----------------+-----------+-----+
",
        content => [

            #-- 1st row
            Gtk2::Ex::FormFactory::Label->new( label => __ "V-Rate:", ),
            Gtk2::Ex::FormFactory::Label->new(
                attr => "title.tc_video_bitrate",
            ),
            Gtk2::Ex::FormFactory::Label->new( label => "    " ),
            Gtk2::Ex::FormFactory::Label->new( label => __ "Video size:", ),
            Gtk2::Ex::FormFactory::Label->new(
                attr => "title.storage_video_size",
            ),
            Gtk2::Ex::FormFactory::Label->new( label => __ "MB", ),

            #		Gtk2::Ex::FormFactory::Label->new ( label => " " ),

            #-- 2nd row
            Gtk2::Ex::FormFactory::Label->new( label => __ "BPP:", ),
            Gtk2::Ex::FormFactory::Label->new(
                attr => "title.tc_video_bpp",
            ),
            Gtk2::Ex::FormFactory::Label->new( label => __ "Audio size:", ),
            Gtk2::Ex::FormFactory::Label->new(
                attr => "title.storage_audio_size",
            ),
            Gtk2::Ex::FormFactory::Label->new( label => __ "MB", ),

            #-- 3rd row
            Gtk2::Ex::FormFactory::Label->new( label => __ "Other size:", ),
            Gtk2::Ex::FormFactory::Label->new(
                attr => "title.storage_other_size",
            ),
            Gtk2::Ex::FormFactory::Label->new( label => __ "MB", ),

            #-- 4th row
            Gtk2::Ex::FormFactory::Button->new(
                label        => __ "Details...",
                stock        => "gtk-zoom-in",
                clicked_hook => sub {
                    $self->open_bitrate_calc_details;
                },
            ),
            Gtk2::Ex::FormFactory::HSeparator->new,

            #-- 5th row
            Gtk2::Ex::FormFactory::Label->new(
                label       => "<b>" . __("Total size:") . "</b>",
                with_markup => 1,
            ),
            Gtk2::Ex::FormFactory::Label->new(
                attr => "title.storage_total_size",
                bold => 1,
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label       => "<b>" . __("MB") . "</b>",
                with_markup => 1,
            ),
        ],
    );
}

sub open_bitrate_calc_details {
    my $self = shift;

    require Video::DVDRip::GUI::BitrateCalc;

    my $bc = Video::DVDRip::GUI::BitrateCalc->new(
        form_factory => $self->get_form_factory );

    $bc->open_window;

    1;

}

sub open_filters_window {
    my $self = shift;

    require Video::DVDRip::GUI::Filters;

    my $filters = Video::DVDRip::GUI::Filters->new(
        form_factory => $self->get_form_factory );

    $filters->open_window;

    1;

}

sub open_multi_audio_window {
    my $self = shift;

    require Video::DVDRip::GUI::MultiAudio;

    my $maudio = Video::DVDRip::GUI::MultiAudio->new(
        form_factory => $self->get_form_factory );

    $maudio->open_window;

    1;
}

sub transcode {
    my $self            = shift;
    my %par             = @_;
    my ($subtitle_test) = @par{'subtitle_test'};

    return 1 if $self->progress_is_active;
    my $title = $self->selected_title;
    return 1 if not $title;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_transcode_job();

    $exec_flow_gui->start_job($job);

    1;
}

sub view_avi {
    my $self    = shift;
    my %par     = @_;
    my ($title) = @par{'title'};

    $title ||= $self->selected_title;
    return 1 if not $title;

    my $command = $title->get_view_avi_command(
        command_tmpl => $self->config('play_file_command'), );

    system( $command. " &" );
}

sub scan_rescale_volume {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if $self->progress_is_active;
    return 1 if not $title;

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 1;
    }

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_scan_volume_job($title);

    $job->get_post_callbacks->add(sub {
        $self->get_context->update_object_attr_widgets(
            "audio_track.tc_volume_rescale", );
        1;
    });

    $exec_flow_gui->start_job($job);

    1;
}

sub add_to_cluster {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    if ( $title->tc_use_chapter_mode ) {
        $self->message_window(
            message => __ "Titles in chapter mode are not supported" );
        return 1;
    }

    if ( $title->tc_psu_core ) {
        $self->message_window(
            message => __ "PSU core mode currently not supported" );
        return 1;
    }

    if ( $title->project->rip_mode ne 'rip' ) {
        $self->message_window( message => __
                "Cluster mode is only supported\nfor ripped DVD's." );
        return 1;
    }

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 1;
    }

    if ( $title->tc_container eq 'vcd' ) {
        $self->message_window( message => __
                "MPEG processing is not supported for cluster mode." );
        return 1;
    }

    if ( not $title->has_target_audio_tracks and $title->is_ogg ) {
        $self->message_window( message => __
                "Transcoding without audio in an OGG container isn't ".
                "supported in cluster mode." );
        return 1;
    }

    if (   $title->tc_start_frame ne ''
        or $title->tc_end_frame ne '' ) {
        $self->message_window(
            message => __ "WARNING: your frame range setting\n"
                . "is ignored in cluster mode" );
    }

    # calculate program stream units, if not already done
    $title->calc_program_stream_units
        if not $title->program_stream_units
        or not @{ $title->program_stream_units };

    $self->get_context_object("main")->cluster_control;

    my $cluster_gui = eval { $self->get_context_object('cluster_gui') };
    return if not $cluster_gui;
    return if not $cluster_gui->master;

    $cluster_gui->add_project(
        project => $self->project,
        title   => $title,
    );

    1;
}

sub create_wav {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_create_wav_job($title);

    $exec_flow_gui->start_job($job);

    1;
}

sub detect_audio_bitrate {
    my $self = shift;
    my ($codec_attr) = @_;

    my $title = $self->selected_title;
    return 1 if not $title;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_detect_audio_bitrate_job($title, $codec_attr);

    $exec_flow_gui->start_job($job);

    1;
}

sub open_video_configure_window {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    my $in_filename  = $title->multipass_log_dir . "/xvid4.cfg";
    my $out_filename = $in_filename;

    if ( not -f $in_filename ) {
        system(
            "xvid4conf '$out_filename' '$ENV{HOME}/.transcode/xvid4.cfg' &");
    }
    else {
        system("xvid4conf '$out_filename' '$in_filename' &");
    }

    1;
}

1;
