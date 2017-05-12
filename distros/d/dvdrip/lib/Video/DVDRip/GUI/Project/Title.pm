# $Id: Title.pm 2344 2007-08-09 21:37:41Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Title;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

use File::Path;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->get_context->set_object( "toc_gui" => $self );

    return $self;
}


sub build_factory {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::VBox->new(
        $self->get_optimum_screen_size_options("page"),
        title       => '[gtk-cdrom]'.__"RIP Title",
        object      => "project",
        active_cond => sub {
            $self->project
                && $self->project->created;
        },
        active_depends => "project.created",
        no_frame       => 1,
        content        => [
            Gtk2::Ex::FormFactory::HBox->new(
                name    => "dvd_toc_buttons",
                title   => __ "Read content",
                content => [
                    Gtk2::Ex::FormFactory::Button->new(
                        object => "project",
                        label  => __ "Read DVD table of contents",
                        tip    => __ "Scan the DVD for all available titles "
                            . "and setup the table of contents",
                        stock        => "gtk-find",
                        clicked_hook => sub { $self->ask_read_dvd_toc },
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        object => "project",
                        label  => __ "Open DVD tray",
                        tip    => __
                            "Open the tray of your configured DVD device",
                        stock        => "gtk-open",
                        clicked_hook => sub { $self->eject_dvd },
                        active_cond    => sub {
                            $self->project 
                            && !-d $self->project->dvd_device
                            && !$self->progress_is_active
                        },
                        active_depends => [
                            "project.dvd_device",
                            "progress.is_active",
                        ],
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        object => "project",
                        label  => __ "Close DVD tray",
                        tip    => __
                            "Close the tray of your configuried DVD device",
                        stock        => "gtk-close",
                        clicked_hook => sub { $self->insert_dvd },
                        active_cond    => sub {
                            $self->project 
                            && !-d $self->project->dvd_device
                            && !$self->progress_is_active
                        },
                        active_depends => [
                            "project.dvd_device",
                            "progress.is_active",
                        ],
                    ),
                ]
            ),
            Gtk2::Ex::FormFactory::VBox->new(
                title   => __ "DVD table of contents",
                expand  => 1,
                object  => "content",
                content => [
                    Gtk2::Ex::FormFactory::HBox->new(
                        expand  => 1,
                        content => [
                            Gtk2::Ex::FormFactory::List->new(
                                name        => "content_list",
                                attr        => "content.titles",
                                attr_select => "content.selected_titles",
                                attr_select_column => 0,
                                tip => __"Select title for further operation",
                                expand     => 1,
                                scrollbars => [ "never", "automatic" ],
                                columns    => [
                                    "idx",
                                    __ "Title",
                                    __ "Runtime",
                                    __ "Norm",
                                    __ "Chp",
                                    __ "Audio",
                                    __ "Framerate",
                                    __ "Aspect",
                                    __ "Frames",
                                    __ "Resolution"
                                ],
                                selection_mode => "multiple",
                                customize_hook => sub {
                                    my ($gtk_simple_list) = @_;
                                    ( $gtk_simple_list->get_columns )[0]
                                        ->set( visible => 0 );
                                    1;
                                },
                            ),
                            $self->build_audio_viewing_chapter_factory,
                        ]
                    ),
                    Gtk2::Ex::FormFactory::HBox->new(
                        object  => "title",
                        content => [
                            Gtk2::Ex::FormFactory::Button->new(
                                label => __ "View selected title/chapter(s)",
                                stock => "gtk-media-play",
                                clicked_hook => sub { $self->view_title },
                                active_cond    => sub { !$self->progress_is_active },
                                active_depends => "progress.is_active",
                            ),
                            Gtk2::Ex::FormFactory::Button->new(
                                label => __
                                    "RIP selected title(s)/chapter(s)",
                                stock        => "gtk-harddisk",
                                clicked_hook => sub { $self->rip_title },
                                active_cond  => sub {
                                    return 1 unless $self->project;
                                    return 0 if $self->project->rip_mode ne 'rip';
                                    return !$self->progress_is_active;
                                },
                                active_depends => [ "project.rip_mode", "progress.is_active" ],
                            ),

                        ],
                    ),
                ],
            ),
        ],
    );
}

sub build_audio_viewing_chapter_factory {
    my $self = shift;

    return Gtk2::Ex::FormFactory::VBox->new(
        object  => "title",
        content => [
            Gtk2::Ex::FormFactory::Popup->new(
                name => "audio_selection", # Title->audio_channel_list requires this
                attr  => "title.audio_channel",
                label => __ "Select audio track",
                tip   => __ "All audio tracks are ripped, but this "
                    . "track is also scanned for volume while "
                    . "ripping",
                active_cond => sub {
                    $self->get_context_object("title")
                        && $self->get_context_object("title")->audio_channel
                        != -1;
                },
                active_depends => ["title.audio_channel"],
            ),
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "title.tc_viewing_angle",
                label => "\n" . __ "Select viewing angle",
                tip   => __ "This selection affects ripping, so you "
                          . "must rip again if you change this later",
                active_cond => sub {
                    $self->get_context_object("title")
                        && $self->get_context_object("title")->viewing_angles
                        > 1;
                },
                active_depends => ["title.viewing_angles"],
            ),
            Gtk2::Ex::FormFactory::HBox->new(
                object  => "subtitle",
                label   => "\n" . __ "Grab subtitle preview images",
                content => [
                    Gtk2::Ex::FormFactory::RadioButton->new(
                        attr  => "title.tc_rip_subtitle_mode",
                        value => "0",
                        label => __ "No",
                        tip   => __
                            "No subitle images are created while ripping "
                            . "but can be grabbed later on demand. This is "
                            . "the fastest ripping mode.",
                    ),
                    Gtk2::Ex::FormFactory::RadioButton->new(
                        attr  => "title.tc_rip_subtitle_mode",
                        value => "all",
                        label => __ "All",
                        tip   => __
                            "Images of all subtitle streams are created "
                            . "during ripping and available for preview "
                            . "immediately. Note that this will slow down "
                            . "the ripping process significantly.",
                    ),
                    Gtk2::Ex::FormFactory::RadioButton->new(
                        attr  => "title.tc_rip_subtitle_mode",
                        value => "lang",
                        label => __ "By language",
                        tip   => __
                            "Grab subtitle images of specific languages only. "
                            . "Note that this will slow down the ripping process "
                            . "significantly.",
                    ),
                ],

              #		    active_cond => sub { $self->version("spuunmux") >= 611 },
              #		    inactive    => "invisible",
            ),
            Gtk2::Ex::FormFactory::List->new(
                name               => "sub_lang_selection",
                attr               => "title.subtitle_languages",
                attr_select        => "title.tc_rip_subtitle_lang",
                attr_select_column => 0,
                expand             => 0,
                height             => 75,
                scrollbars         => [ "never", "always" ],
                tip                => __ "Select one or more languages",
                columns            => [ __ "Language selection" ],
                selection_mode     => "multiple",
                inactive           => "invisible",
            ),
            Gtk2::Ex::FormFactory::HBox->new(
                object  => "title",
                label   => "\n" . __ "Specify chapter mode",
                content => [
                    Gtk2::Ex::FormFactory::RadioButton->new(
                        attr  => "title.tc_use_chapter_mode",
                        value => "0",
                        label => __ "None",
                        tip   => __ "The title is handled as a whole "
                            . "ignoring all chapter marks",
                    ),
                    Gtk2::Ex::FormFactory::RadioButton->new(
                        attr  => "title.tc_use_chapter_mode",
                        value => "all",
                        label => __ "All",
                        tip   => __ "Processing is divided into "
                            . "chapters. You get one file per "
                            . "chapter for all chapters of this title",
                    ),
                    Gtk2::Ex::FormFactory::RadioButton->new(
                        attr  => "title.tc_use_chapter_mode",
                        value => "select",
                        label => __ "Selection",
                        tip   => __ "Processing is divided into "
                            . "chapters. You get one file per "
                            . "chapter for a specific selection "
                            . "of chapters",
                    ),
                ],
            ),
            Gtk2::Ex::FormFactory::List->new(
                name               => "chapter_selection",
                attr               => "title.chapter_list",
                attr_select        => "title.tc_selected_chapters",
                attr_select_column => 0,
                expand             => 1,
                scrollbars         => [ "never", "always" ],
                tip                => __ "Select one or more chapters",
                columns            => [ "nr", __ "Chapter selection" ],
                visible            => [ 0, 1 ],
                selection_mode     => "multiple",
                inactive           => "invisible",
            ),
        ],
    );
}

sub ask_read_dvd_toc {
    my $self = shift;

    if ( $self->project->content->titles ) {
        $self->get_form_factory->open_confirm_window(
            message => __ "If you re-read the TOC, all settings in\n"
                . "this project get lost. Probably you want\n"
                . "to save the project to another file before\n"
                . "you proceeed.\n\n"
                . "Do you want to re-read the TOC now?",
            yes_callback => sub { $self->read_dvd_toc },
            yes_label    => __ "Yes",

        );
    }
    else {
        return $self->read_dvd_toc;
    }
}

sub read_dvd_toc {
    my $self = shift;

    return if $self->progress_is_active;

    $self->clear_content_list;
    $self->get_context->set_object( "title", undef );

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    
    my $job = $job_planner->build_read_toc_job();

    $job->get_post_callbacks->add (sub{
        $self->project->content->select_longest_title;
        $self->get_context->update_object_widgets("content");
        $self->get_context->update_object_attr_widgets("content.selected_titles");
        $self->get_context->get_proxy("project")->set_object_changed(1);
    });

    $exec_flow_gui->start_job($job);

    1;
}

sub clear_content_list {
    my $self = shift;

    my $content = $self->project->content;

    $content->set_titles( {} );
    $content->set_selected_titles( [] );

    $self->get_context->update_object_widgets("content");
    $self->get_context->update_object_widgets("title");

    1;
}

sub append_content_list {
    my $self = shift;
    my %par = @_;
    my ($title) = @par{'title'};

    my $list = $self->get_form_factory->get_widget("content_list");

    push @{ $list->get_gtk_widget->{data} },
        [
        ( $title->nr - 1 ),
        $title->nr,
        $self->format_time( time => $title->runtime ),
        uc( $title->video_mode ),
        $title->chapters,
        scalar( @{ $title->audio_tracks } ),
        $title->frame_rate,
        $title->aspect_ratio,
        $title->frames,
        $title->width . "x" . $title->height
        ];

    1;
}

sub rip_title {
    my $self = shift;

    return if $self->progress_is_active;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    
    my $rip_job = $job_planner->build_rip_job();
    
    $rip_job->get_post_callbacks->add (sub{
        $self->get_context->update_object_widgets("title");
        $self->get_context->update_object_widgets("audio_track");
        $self->get_context->update_object_widgets("subtitle");
        $self->get_context->get_proxy("project")->set_object_changed(1);
    });
    
    $exec_flow_gui->start_job($rip_job);

    1;
}

sub view_title {
    my $self = shift;

    my $title = $self->selected_title;

    if ( not $title ) {
        $self->message_window( message => __ "Please select a title." );
        return;
    }

    if ( $title->tc_use_chapter_mode eq 'select' ) {
        my $chapters = $title->tc_selected_chapters;
        if ( not $chapters or not @{$chapters} ) {
            $self->message_window( message => __ "No chapters selected." );
            return;
        }
    }

    my $command = $title->get_view_dvd_command(
        command_tmpl => $self->config('play_dvd_command') );

    $self->log("Executing view command: $command");

    system( $command. " &" );

    1;
}

sub eject_dvd {
    my $self = shift;

    my $title = $self->selected_title;

    my $command
        = $self->config('eject_command') . " " .
            $title->project->dvd_device;

    system("$command &");

    1;
}

sub insert_dvd {
    my $self = shift;

    my $title = $self->selected_title;

    my $command = $self->config('eject_command') . " -t "
        . $title->project->dvd_device;

    system("$command &");

    1;
}

1;
