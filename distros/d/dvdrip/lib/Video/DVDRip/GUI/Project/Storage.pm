# $Id: Storage.pm 2344 2007-08-09 21:37:41Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Storage;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub build_factory {
    my $self = shift;

    my $dvd_device_popup;
    if ( $self->has("hal") ) {
        $dvd_device_popup =
            Gtk2::Ex::FormFactory::Popup->new (
                attr     => "project.selected_dvd_device",
                expand_h => 0,
                changed_hook_after => sub {
                    $self->get_context->set_object_attr (
                        "project", "dvd_device",
                        $self->get_context->get_object_attr (
                            "project.selected_dvd_device",
                        ),
                    ),
                },
                tip => __"This is a list of connected DVD drives "
                        ."found in your system"
            );
    }
    else {
        $dvd_device_popup =
            Gtk2::Ex::FormFactory::Button->new (
                label    => __"Choose DVD device file",
                expand_h => 0,
                clicked_hook => sub {
                    $self->choose_dvd_device_file;
                },
                tip => __"Press this button to open a file chooser dialog"
            );
    }

    return Gtk2::Ex::FormFactory::VBox->new(
        $self->get_optimum_screen_size_options("page"),
        title    => '[gtk-harddisk]'.__ "Storage",
        object   => "project",
        no_frame => 1,
        content  => [
            Gtk2::Ex::FormFactory::Form->new(
                title   => __ "Storage path information",
                content => [
                    Gtk2::Ex::FormFactory::Entry->new(
                        name  => "project_name",
                        attr  => "project.name",
                        label => __ "Project name",
                        tip   => __ "This is a short name for "
                            . "the project. All generated files "
                            . "are named like this.",
                        rules => "project-name",
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "project.vob_dir",
                        label => __ "VOB directory",
                        tip   => __ "DVD VOB files are stored here.",
                        rules => "project-path",
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "project.avi_dir",
                        label => __ "AVI directory",
                        tip   => __ "For transcoded AVI, MPEG and OGM files.",
                        rules => "project-path",
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "project.snap_dir",
                        label => __ "Temporary directory",
                        tip   => __ "For temporary files",
                        rules => "project-path",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label  => __ "Create project",
                        stock  => "gtk-add",
                        expand => 0,
                        tip    => __
                            "This asks for a project filename and creates the "
                            . "neccessary filesystem structure",
                        clicked_hook => sub {
                            $self->get_context_object("main")->save_project;
                        },
                        inactive    => "invisible",
                        active_cond => sub {
                            return 1 unless $self->project;
                            return !$self->project->created;
                        },
                        active_depends => "project",
                    ),
                ]
            ),
            Gtk2::Ex::FormFactory::VBox->new(
                title       => __ "Data source selection",
                object      => "project",
                active_cond => sub {
                    $self->project
                        && $self->project->created;
                },
                active_depends => "project.created",
                content        => [
                    Gtk2::Ex::FormFactory::Label->new (
                        label   => __"Select a DVD device or an image directory for input",
                    ),
                    Gtk2::Ex::FormFactory::Form->new (
                        content => [
                            Gtk2::Ex::FormFactory::HBox->new (
                                label    => __"Choose DVD device",
                                expand_h => 0,
                                content => [
                                    $dvd_device_popup,
                                    Gtk2::Ex::FormFactory::Label->new (
                                        label    => __"or",
                                    ),
                                    Gtk2::Ex::FormFactory::Button->new (
                                        label    => __"Choose DVD image directory",
                                        expand_h => 0,
                                        clicked_hook => sub {
                                            $self->choose_dvd_image_directory;
                                        },
                                        tip => __"Press this button to open a file chooser dialog"
                                    ),
                                ],
                            ),
                            Gtk2::Ex::FormFactory::Entry->new(
                                label   => __"Or enter by hand",
                                attr    => "project.dvd_device",
                                expand  => 1,
                                tip     => __"dvd::rip uses this location for DVD input. "
                                            ."Either it's the filename of a physical DVD "
                                            ."device or the path of a full DVD image copy."
                            ),
                        ],
                    ),
                ],
            ),
            Gtk2::Ex::FormFactory::HBox->new (
                title   => __ "Choose a ripping mode",
                object  => "project",
                active_cond => sub {
                    $self->project
                        && $self->project->created;
                },
                content => [
                    Gtk2::Ex::FormFactory::VBox->new(
                        content     => [
                            Gtk2::Ex::FormFactory::RadioButton->new(
                                attr  => "project.rip_mode",
                                value => "rip",
                                expand_h => 0,
                                label => __ "Copy data from DVD to harddisk "
                                    . "before encoding",
                                tip => __ "Use this mode if you have enough "
                                    . "diskspace for a complete copy of "
                                    . "the DVD contents. It's the fastest "
                                    . "and most flexible DVD mode.",
                            ),
                            Gtk2::Ex::FormFactory::RadioButton->new(
                                attr  => "project.rip_mode",
                                value => "dvd",
                                expand_h => 0,
                                label => __ "Encode DVD on the fly",
                                tip   => __ "No DVD contents are copied to harddisk.",
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                label =>
                                    __"Copying DVD(-image) data to harddisk before encoding is\n"
                                     ."the recommended mode, because it's faster and doesn't\n"
                                     ."stress your DVD reader that much. Additionally some\n"
                                     ."interesting features are available only with this mode,\n"
                                     ."due to internal transcode restrictions:\n\n"
                                     ."- Cluster transcoding\n"
                                     ."- Subtitle rendering\n"
                                     ."- Faster preview grabbing and frame range transcoding\n"
                                     ."- transcode's PSU core for optimized A/V sync with NTSC video\n"
                            ),
                        ]
                    ),
                ],
            ),
        ],
    );
}

sub choose_dvd_device_file {
    my $self = shift;
    
    my $form_factory = $self->get_form_factory;
    my $gtk_window   =
          $form_factory
        ? $form_factory->get_form_factory_gtk_window
        : undef;

    my $dialog = Gtk2::FileChooserDialog->new(
        __"Choose DVD device file",
        $gtk_window,
        "open",
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok'
    );

    $dialog->set_current_folder("/dev");

    my $response = $dialog->run;
    my $dir = $dialog->get_filename;
    $dialog->destroy;
    
    return if $response ne 'ok';

    $self->get_context->set_object_attr (
        "project", "dvd_device", $dir,
    );

    1;
}

sub choose_dvd_image_directory {
    my $self = shift;
    
    my $form_factory = $self->get_form_factory;
    my $gtk_window   =
          $form_factory
        ? $form_factory->get_form_factory_gtk_window
        : undef;

    my $dialog = Gtk2::FileChooserDialog->new(
        __"Choose DVD image directory",
        $gtk_window,
        "select-folder",
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok'
    );

    $dialog->set_current_folder($self->config("base_project_dir"));

    my $response = $dialog->run;
    my $dir = $dialog->get_filename;
    $dialog->destroy;
    
    return if $response ne 'ok';

    if ( ! -d "$dir/VIDEO_TS" && ! -d "$dir/video_ts" ) {
        $self->error_window (
            message => __"Selected directory is no DVD image directory. ".
                         "It has no VIDEO_TS folder."
        );
        return;
    }

    $self->get_context->set_object_attr (
        "project", "dvd_device", $dir,
    );

    1;
}

1;
