# $Id: Subtitle.pm 2344 2007-08-09 21:37:41Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Subtitle;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

use Video::DVDRip::GUI::FormFactory::SubtitlePreviews;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    return $self;
}

sub build_factory {
    my $self = shift;

    my $context = $self->get_context;

    $context->set_object( subtitle_gui => $self );

    return Gtk2::Ex::FormFactory::VBox->new(
        $self->get_optimum_screen_size_options("page"),
        title       => '[gtk-underline]'.__ "Subtitles",
        object      => "title",
        active_cond => sub {
            $self->selected_title
                && $self->project
                && $self->project->created;
        },
        active_depends => "project.created",
        no_frame       => 1,
        content        => [
            Video::DVDRip::GUI::Main->build_selected_title_factory,
            Gtk2::Ex::FormFactory::VBox->new(
                object   => "subtitle",
                inactive => "invisible",
                expand   => 1,
                content  => [
                    $self->build_select_box, $self->build_preview_box,
                    $self->build_render_box, $self->build_vobsub_box,
                ],
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label => "\n<b>" . __("This title has no subtitles") . "</b>",
                with_markup => 1,
                inactive    => "invisible",
                active_cond => sub {
                    !( $self->selected_title && $self->selected_title->has_subtitles )
                },
                active_depends => "title",
            ),
        ],
    );
}

sub build_select_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new(
        title   => __ "Subtitle selection",
        content => [
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "title.selected_subtitle_id",
                label => __ "Select subtitle",
            ),
            Gtk2::Ex::FormFactory::Label->new(
                attr  => "title.subtitles_activated",
                label => __ "Activated:",
            ),
        ],
    );
}

sub build_preview_box {
    my $self = shift;

    my $preview_event_box = Gtk2::EventBox->new;
    $preview_event_box->modify_bg( "normal",
        Gtk2::Gdk::Color->parse("#ffffff") );

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Preview",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::HBox->new(
                content => [
                    Gtk2::Ex::FormFactory::Button->new(
                        name         => "subtitle_grab_button",
                        object       => "subtitle",
                        label        => __ "Grab",
                        stock        => "gtk-copy",
                        clicked_hook => sub {
                            $self->grab_subtitle_preview_images;
                        },
                        inactive    => "invisible",
                        active_cond => sub {
                            my ($subtitle) = @_;
                            return 0 unless $subtitle;
                            return 0 if     $subtitle->is_ripped;
                            return $self->progress_is_active ?
                                'insensitive' : 'sensitive';
                        },
                        active_depends => ["subtitle.is_ripped", "progress.is_active" ],
                    ),
                    Gtk2::Ex::FormFactory::Combo->new(
                        attr    => "subtitle.tc_preview_img_cnt",
                        presets => [ 1, 3, 5, 10, 20, 30, 50, 100 ],
                        width   => 60,
                        rules   => "positive-integer",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "image(s)",
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "subtitle.tc_preview_timecode",
                        label => __ "starting at",
                        width => 60,
                        rules => sub {
                            my ($value) = @_;
                            my $frames = $self->selected_title->frames;
                            return
                                if $value =~ /^\d+$/
                                and $value <= $frames;
                            return if $value =~ /^\d\d:\d\d:\d\d$/;
                            return __x( "Movie has only {cnt} frames",
                                cnt => $frames )
                                if $value =~ /^\d+$/
                                and $value > $frames;
                            return __ "Invalid time/frame number format";
                        },
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "(timecode nn:nn:nn or frame number)",
                    ),
                ],
            ),
            Video::DVDRip::GUI::FormFactory::SubtitlePreviews->new(
                attr            => "subtitle.preview_dir",
                attr_image_cnt  => "subtitle.tc_preview_img_cnt",
                attr_start_time => "subtitle.tc_preview_timecode",
                expand          => 1,
            ),
        ],
    );
}

sub build_render_box {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::Table->new(
        object      => "subtitle",
        active_cond =>
            sub { $context->get_object_attr("title.subtitle_render_ok") },
        active_depends => "subtitle.tc_vobsub",
        title          => __ "Render subtitle on movie",
        layout         => "
                +--------+------------+>>>+--------+-----------+>>>+-----------+-------+
                | ActLab | RendCheckb | S | Colors | ColCheckB | S | PrevImCnt | Entry |
                +--------+-------+----+   +--------+-----+-----+   +-----------+-------+
                | VOff   | Entry | Un |   | Gray   | Ent | Ent |   | PrevWin   | Open  |
                +--------+-------+----+   +--------+-----+-----+   +-----------+-------+
                | TimeS  | Entry | Un |   | Index  | Pop | Pop |   |                   |
                +--------+-------+----+   +--------+-----+-----+---+-------------------+
                | PostPr | Antiaalias |   | Suggst | Letterbox |   | Full Size Movie   |
                +--------+-------+----+---+--------+-----------+---+-------------------+
	    ",
        content => [

            #-- Row #1
            Gtk2::Ex::FormFactory::Label->new(
                label       => __ "Activate this subtitle" . " ",
                label_group => "subtitle1",
            ),
            Gtk2::Ex::FormFactory::CheckButton->new(
                attr  => "subtitle.tc_render",
                label => __ "for rendering",
            ),
            Gtk2::Ex::FormFactory::VSeparator->new,
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Colors" . " ",
                for   => "subtitle.tc_color_manip",
            ),
            Gtk2::Ex::FormFactory::CheckButton->new(
                attr  => "subtitle.tc_color_manip",
                label => __ "Enable manipulation",
            ),
            Gtk2::Ex::FormFactory::VSeparator->new,
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Preview image count" . " ",
                for   => "subtitle.tc_test_image_cnt",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "subtitle.tc_test_image_cnt",
                width => 50,
                rules => "positive-integer",
            ),

            #-- Row #2
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Vertical offset" . " ",
                for   => "subtitle.tc_vertical_offset",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "subtitle.tc_vertical_offset",
                width => 50,
                rules => "integer",
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label       => __ "rows",
                active_cond =>
                    sub { $context->get_object_attr("subtitle.tc_render") },
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Gray A/B" . " ",
                for   => "subtitle.tc_color_a",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "subtitle.tc_color_a",
                width => 50,
                rules => sub {
                    $_[0] =~ /^\d+$/ && $_[0] >= 0 && $_[0] <= 255
                        ? undef
                        : __ "Value not between 0 and 255";
                },
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "subtitle.tc_color_b",
                width => 50,
                rules => sub {
                    $_[0] =~ /^\d+$/ && $_[0] >= 0 && $_[0] <= 255
                        ? undef
                        : __ "Value not between 0 and 255";
                },
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Preview window" . " ",
                active_cond => sub {
                    return 0 unless $context->get_object_attr("subtitle.tc_render");
                    return !$self->progress_is_active;
                },
                active_depends => [ "subtitle.tc_render", "progress.is_active" ],
            ),
            Gtk2::Ex::FormFactory::Button->new(
                stock       => "gtk-media-play",
                label       => __ "Open",
                object      => "subtitle",
                clicked_hook   => sub { $self->subtitle_preview_window },
                active_cond => sub {
                    return 0 unless $context->get_object_attr("subtitle.tc_render");
                    return !$self->progress_is_active;
                },
                active_depends => [ "subtitle.tc_render", "progress.is_active" ],
            ),

            #-- Row #3
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Time shift" . " ",
                for   => "subtitle.tc_time_shift",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "subtitle.tc_time_shift",
                width => 50,
                rules => "positive-zero-integer",
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label       => __ "ms",
                active_cond =>
                    sub { $context->get_object_attr("subtitle.tc_render") },
                active_depends => "subtitle.tc_render",
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label => __ "Index A/B" . " ",
                for   => "subtitle.tc_assign_color_a",
            ),
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "subtitle.tc_assign_color_a",
                width => 50,
            ),
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "subtitle.tc_assign_color_b",
                width => 50,
            ),

            #-- Row #4
            Gtk2::Ex::FormFactory::CheckButton->new(
                attr  => "subtitle.tc_postprocess",
                label => __ "Postprocessing" . " ",
            ),
            Gtk2::Ex::FormFactory::CheckButton->new(
                attr  => "subtitle.tc_antialias",
                label => __ "Antialiasing",
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label       => __ "Suggest" . " ",
                active_cond =>
                    sub { $context->get_object_attr("subtitle.tc_render") },
                active_depends => "subtitle.tc_render",
            ),
            Gtk2::Ex::FormFactory::Button->new(
                label       => __ "Values for letterbox",
                object      => "subtitle",
                active_cond =>
                    sub { $context->get_object_attr("subtitle.tc_render") },
                active_depends => "subtitle.tc_render",
                clicked_hook   => sub {
                    $self->suggest_render_black_bars;
                },
            ),
            Gtk2::Ex::FormFactory::Button->new(
                label       => __ "Values for full size movie",
                object      => "subtitle",
                active_cond =>
                    sub { $context->get_object_attr("subtitle.tc_render") },
                active_depends => "subtitle.tc_render",
                clicked_hook   => sub {
                    $self->suggest_render_full_size;
                },
            ),
        ],
    );
}

sub build_vobsub_box {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::Table->new(
        object      => "subtitle",
        active_cond =>
            sub { !$context->get_object_attr("subtitle.tc_render") },
        active_depends => "subtitle.tc_render",
        title          => __ "Create vobsub file",
        layout         => "
                +---------+---------+---------+---------------+
                | Now     | Button  | Button  | Info          |
                +---------+---------+---------+---------------+
                | Later   | after transcoding | Info          |
                +---------+-------------------+---------------+
	    ",
        content => [

            #-- Row #1
            Gtk2::Ex::FormFactory::Label->new(
                label       => __ "Create now",
                label_group => "subtitle1",
            ),
            Gtk2::Ex::FormFactory::Button->new(
                label          => __ "Create now",
                clicked_hook   => sub { $self->create_vobsub_now },
                active_cond    => sub { !$self->progress_is_active },
                active_depends => "progress.is_active",
            ),
            Gtk2::Ex::FormFactory::Button->new(
                label        => __ "View vobsub",
                clicked_hook => sub { $self->view_vobsub },
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label => "      " . __ "Only useful for single-CD-rips or after transcoding",
            ),

            #-- Row #2
            Gtk2::Ex::FormFactory::Label->new( label => __ "Create later", ),
            Gtk2::Ex::FormFactory::CheckButton->new(
                attr  => "subtitle.tc_vobsub",
                label => __ "after transcoding",
            ),
            Gtk2::Ex::FormFactory::Label->new(
                      label => "      "
                    . __ "This considers splitted files automaticly",
            ),
        ],
    );
}

sub suggest_render_black_bars {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    $title->suggest_subtitle_on_black_bars;

    $self->get_context->get_object("clip_zoom")->make_previews;
    $self->get_context->update_object_widgets("title");
    $self->get_context->update_object_widgets("bitrate_calc");
    $self->get_context->update_object_attr_widgets(
        "subtitle.tc_vertical_offset");

    1;
}

sub suggest_render_full_size {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    $title->suggest_subtitle_on_movie;

    $self->get_context->get_object("clip_zoom")->make_previews;
    $self->get_context->update_object_widgets("title");
    $self->get_context->update_object_widgets("bitrate_calc");
    $self->get_context->update_object_attr_widgets(
        "subtitle.tc_vertical_offset");

    1;
}

sub create_vobsub_now {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    my $subtitle = $title->selected_subtitle;
    return 1 if not $subtitle;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_vobsub_job($title, $subtitle);

    $exec_flow_gui->start_job($job);

    1;
}

sub view_vobsub {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    my $subtitle = $title->selected_subtitle;
    return 1 if not $subtitle;

    if ( not $self->has("mplayer") ) {
        $self->message_window(
            message => __ "You need Mplayer to view vobsub files." );
        return 1;
    }

    if ( $title->project->rip_mode ne 'rip' ) {
        $self->message_window(
            message => __ "This is only supported for ripped movies." );
        return 1;
    }

    if ( not $subtitle->vobsub_file_exists ) {
        $self->message_window(
            message => __ "What about creating the vobsub file first?" );
        return 1;
    }

    my $command = $title->get_view_vobsub_command( subtitle => $subtitle );

    $self->log( __ "Executing command: " . $command );

    system("$command &");

    1;
}

sub subtitle_preview_window {
    my $self = shift;

    my $title = $self->selected_title;

    my $orig_preview_start_frame = $title->tc_preview_start_frame;
    my $orig_preview_end_frame   = $title->tc_preview_end_frame;

    my ( $from, $to ) = $title->get_subtitle_test_frame_range;

    $title->set_tc_preview_start_frame($from);
    $title->set_tc_preview_end_frame($to);

    my $restore_cb = sub {
        $title->set_tc_preview_start_frame($orig_preview_start_frame);
        $title->set_tc_preview_end_frame($orig_preview_end_frame);
    };

    require Video::DVDRip::GUI::Preview;

    my $preview = Video::DVDRip::GUI::Preview->new(
        form_factory => $self->get_form_factory,
        closed_cb    => $restore_cb,
        eof_cb       => $restore_cb,
    );

    $preview->open;

    1;
}

sub grab_subtitle_preview_images {
    my $self    = shift;
    my %par     = @_;
    my ($force) = @par{'force'};

    my $title = $self->selected_title;
    return 1 if not $title;
    return 1 if $self->progress_is_active;
    my $selected_subtitle = $title->selected_subtitle;
    return 1 if not $selected_subtitle;

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 1;
    }

    if ( not $self->has("subtitle2pgm") ) {
        $self->message_window(
            message => __ "Sorry, you need subtitle2pgm for this to work." );
        return 1;
    }

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_grab_subtitle_images_job($title);

    $job->get_post_callbacks->add(
        sub {
            $self->get_context->update_object_attr_widgets(
                "title.selected_subtitle_id");
            $self->get_context->update_object_attr_widgets(
                "subtitle.preview_dir");
        }
    );

    $exec_flow_gui->start_job($job);

    1;
}

1;
