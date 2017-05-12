# $Id: ClipZoom.pm 2344 2007-08-09 21:37:41Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::ClipZoom;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;
use Video::DVDRip::GUI::FormFactory::ClipImage;

sub get_preview_hbox_width      { shift->{preview_hbox_width}           }
sub get_preview_hbox_height     { shift->{preview_hbox_height}          }
sub get_preview_image_sizes     { shift->{preview_image_sizes}          }

sub set_preview_hbox_width      { shift->{preview_hbox_width}   = $_[1] }
sub set_preview_hbox_height     { shift->{preview_hbox_height}  = $_[1] }
sub set_preview_image_sizes     { shift->{preview_image_sizes}  = $_[1] }

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{preview_hbox_width}  => undef;
    $self->{preview_hbox_height} => undef;
    $self->{preview_image_sizes} => {};

    # { clip1 => { mtime => $mtime, width => $width, height => $height } }

    $self->get_context->set_object( "clip_zoom" => $self );

    return $self;
}

sub build_factory {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::VBox->new(
        $self->get_optimum_screen_size_options("page"),
        title       => '[gtk-zoom-in]'.__ "Clip & Zoom",
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
            $self->build_preview_images,
            $self->build_adjust_form,
        ],
    );
}

sub build_preview_images {
    my $self = shift;

    my $update_timeout;
    my $preview_image_hbox;
    return Gtk2::Ex::FormFactory::VBox->new(
        expand  => 1,
        title   => __ "Preview images",
        object  => "title",
        content => [
            Gtk2::Ex::FormFactory::HBox->new(
                spacing => 5,
                content => [
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr  => "title.preview_frame_nr",
                        label => __ "Grab preview frame #",
                        rules => "integer",
                        width => 80,
                        rules => [ "positive-integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::CheckButton->new(
                        attr  => "title.tc_force_slow_grabbing",
                        label => __ "Force slow grabbing",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        object       => "title",
                        label        => __ "Grab frame",
                        stock        => "gtk-redo",
                        clicked_hook => sub { $self->grab_preview_frame },
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        object       => "title",
                        label        => __ "Show video from here",
                        stock        => "dvdrip-play-movie",
                        clicked_hook => sub { $self->preview_video },
                        active_cond  => sub {
                            return unless $self->project;
                            return 0 if $self->project->rip_mode ne 'rip';
                            return !$self->progress_is_active;
                        },
                        active_depends => [ "project.rip_mode", "progress.is_active" ],
                    ),
                ],
            ),
            $preview_image_hbox = Gtk2::Ex::FormFactory::HBox->new(
                homogenous => 1,
                expand     => 1,
                content    => [
                    Gtk2::Ex::FormFactory::VBox->new(
                        content => [
                            Gtk2::Ex::FormFactory::Image->new(
                                name       => "preview_image_clip1",
                                expand     => 1,
                                attr       => "title.preview_filename_clip1",
                                bgcolor    => "#ffffff",
                                scale_hook =>
                                    sub { $self->get_preview_image_scale },
                                properties => { xalign => 0, yalign => 0 },
                                with_frame => 1,
                                signal_connect => {
                                    button_release_event => sub {
                                        $self->open_preview(
                                            type => "clip1" );
                                    },
                                    size_allocate => sub {
                                        return
                                            if $self->get_preview_hbox_width
                                            == $_[1]->width * 3
                                            and $self->get_preview_hbox_height
                                            == $_[1]->height;
                                        $self->set_preview_hbox_width(
                                            $_[1]->width * 3 );
                                        $self->set_preview_hbox_height(
                                            $_[1]->height );
                                        Glib::Source->remove($update_timeout)
                                            if $update_timeout;
                                        $update_timeout = Glib::Timeout->add(
                                            500,
                                            sub {
                                                $_->get_content->[0]->update
                                                    for @{ $preview_image_hbox
                                                        ->get_content };
                                                $update_timeout = undef;
                                                0;
                                            }
                                        );
                                        0;
                                    },
                                    realize => sub {
                                        $_[0]->window->set_cursor(
                                            Gtk2::Gdk::Cursor->new(
                                                'GDK_HAND1')
                                        );
                                        1;
                                    },
                                },
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                name        => "preview_label_clip1",
                                attr        => "title.preview_label_clip1",
                                with_markup => 1,
                            ),
                        ],
                    ),
                    Gtk2::Ex::FormFactory::VBox->new(
                        content => [
                            Gtk2::Ex::FormFactory::Image->new(
                                name       => "preview_image_zoom",
                                expand     => 1,
                                attr       => "title.preview_filename_zoom",
                                bgcolor    => "#ffffff",
                                scale_hook =>
                                    sub { $self->get_preview_image_scale },
                                properties => { xalign => 0, yalign => 0 },
                                with_frame => 1,
                                signal_connect => {
                                    button_release_event => sub {
                                        $self->open_preview( type => "zoom" );
                                    },
                                    realize => sub {
                                        $_[0]->window->set_cursor(
                                            Gtk2::Gdk::Cursor->new(
                                                'GDK_HAND1')
                                        );
                                        1;
                                    },
                                },
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                name        => "preview_label_zoom",
                                attr        => "title.preview_label_zoom",
                                with_markup => 1,
                            ),
                        ],
                    ),
                    Gtk2::Ex::FormFactory::VBox->new(
                        content => [
                            Gtk2::Ex::FormFactory::Image->new(
                                name       => "preview_image_clip2",
                                expand     => 1,
                                attr       => "title.preview_filename_clip2",
                                bgcolor    => "#ffffff",
                                scale_hook =>
                                    sub { $self->get_preview_image_scale },
                                properties => { xalign => 0, yalign => 0 },
                                with_frame => 1,
                                signal_connect => {
                                    button_release_event => sub {
                                        $self->open_preview(
                                            type => "clip2" );
                                    },
                                    realize => sub {
                                        $_[0]->window->set_cursor(
                                            Gtk2::Gdk::Cursor->new(
                                                'GDK_HAND1')
                                        );
                                        1;
                                    },
                                },
                            ),
                            Gtk2::Ex::FormFactory::Label->new(
                                name        => "preview_label_clip2",
                                attr        => "title.preview_label_clip2",
                                with_markup => 1,
                            ),
                        ],
                    ),
                ],
            ),
        ],
    );
}

sub build_adjust_form {
    my $self = shift;

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Adjust clip and zoom parameters",
        object  => "title",
        content => [
            Gtk2::Ex::FormFactory::Table->new(
                layout => "
+--------+---------------+--+-----------------+
| Preset | Popup         |XX| Apply           |
+--------+---------------+--+-----------------+
|        | Separator     |  |                 |
+--------+---+---+---+---+--+-----------------+
|        | T | B | L | R |  |                 |
+--------+---+---+---+---+--+-----------------+
| 1stCl  | X | X | X | X |  | Generate        |
+--------+---+---+---+---+--+-----------------+
| 2ndCl  | X | X | X | X |  | 2nd to 1st      |
+--------+---+---+---+---+--+-----------------+
|        | Separator     |  |                 |
+--------+---+---+---+---+--+-----------------+
|        | W | H | V | B |  |                 |
+--------+---+---+---+---+--+--------+--------+
| Zoom   | X | X | X | X |  | CalcW  | CalcH  |
+--------+---+---+---+---+--+--------+--------+
| FastR  | X             |  | ZoomCalculator  |
+--------+---------------+--+-----------------+
",

               #		    properties => { column_spacing => 5, row_spacing => 5 },
                content => [

                    #-- Presets
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "Presets",
                        widget_group => "clip_zoom_widgets",
                    ),
                    Gtk2::Ex::FormFactory::Popup->new(
                        attr => "title.preset",
                    ),
                    Gtk2::Ex::FormFactory::Label->new( label => "   ", ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Apply preset values",
                        stock        => "gtk-apply",
                        clicked_hook => sub { $self->apply_preset_values },
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                        tip            => __"Overwrites all Clip & Zoom settings from the selected ".
                                            "preset and regenerates the preview images.",
                    ),

                    #-- Separator
                    Gtk2::Ex::FormFactory::HSeparator->new(),

                    #-- Clipping labels
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "Top",
                        widget_group => "clip_zoom_widgets",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "Bottom",
                        widget_group => "clip_zoom_widgets",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "Left",
                        widget_group => "clip_zoom_widgets",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "Right",
                        widget_group => "clip_zoom_widgets",
                    ),

                    #-- 1st Clipping
                    Gtk2::Ex::FormFactory::Label->new(
                        label       => __ "1st clipping",
                        label_group => "clip_zoom_labels",
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip1_top",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip1_bottom",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip1_left",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip1_right",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),

                    #-- Generate preview images button
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Generate preview images",
                        stock        => "gtk-refresh",
                        clicked_hook => sub { $self->make_previews },
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                        tip          => __"Generates new preview images based ".
                                          "on the actual settings",
                    ),

                    #-- 2nd Clipping
                    Gtk2::Ex::FormFactory::Label->new(
                        label       => __ "2nd clipping",
                        label_group => "clip_zoom_labels",
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip2_top",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip2_bottom",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip2_left",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_clip2_right",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "integer", "or-empty" ],
                    ),

                    #-- Move clipping values button
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Move 2nd clipping to 1st",
                        stock        => "dvdrip-clip-move",
                        clicked_hook => sub { $self->move_clip2_to_clip1 },
                        tip          => __"Turns second clipping into first clipping. ".
                                          "This is possible only with high quality scaling."
                    ),

                    #-- Separator
                    Gtk2::Ex::FormFactory::HSeparator->new(),

                    #-- Zoom titles
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "Width",
                        widget_group => "clip_zoom_widgets",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "Height",
                        widget_group => "clip_zoom_widgets",
                    ),

                    #-- V-Bitrate / BPP Titles
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "V-Rate",
                        widget_group => "clip_zoom_widgets",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label        => __ "BPP",
                        widget_group => "clip_zoom_widgets",
                    ),

                    #-- Zoom widgets
                    Gtk2::Ex::FormFactory::Label->new(
                        label       => __ "Zoom",
                        label_group => "clip_zoom_labels",
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_zoom_width",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "positive-integer", "or-empty" ],
                    ),
                    Gtk2::Ex::FormFactory::Entry->new(
                        attr         => "title.tc_zoom_height",
                        widget_group => "clip_zoom_widgets",
                        width        => 10,
                        rules        => [ "positive-integer", "or-empty" ],
                    ),

                    Gtk2::Ex::FormFactory::Label->new(
                        attr => "title.tc_video_bitrate",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr => "title.tc_video_bpp",
                    ),

                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Calc height",
                        stock        => "dvdrip-calc-height",
                        clicked_hook =>
                            sub { $self->calc_zoom( height => 1 ) },
                        tip          => __"Calculates the height based on the given width ".
                                          "with correct aspect ratio",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Calc width",
                        stock        => "dvdrip-calc-width",
                        clicked_hook => sub { $self->calc_zoom( width => 1 ) },
                        tip          => __"Calculates the width based on the given height ".
                                          "with correct aspect ratio",
                    ),

                    #-- Fast resizing
                    Gtk2::Ex::FormFactory::Label->new(
                        label       => __ "Use fast resizing",
                        label_group => "clip_zoom_labels",
                    ),
                    Gtk2::Ex::FormFactory::YesNo->new(
                        attr => "title.tc_fast_resize",
                        true_label => __"Yes",
                        false_label  => __"No",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Open zoom calculator",
                        stock        => "gtk-zoom-in",
                        clicked_hook => sub {
                            $self->open_zoom_calculator;
                        },
                    ),
                ],
            ),
        ],
    );
}

sub get_max_preview_image_size {
    my $self = shift;

    my $context = $self->get_context;
    my $title   = $context->get_object("title");

    my $preview_image_sizes = $self->get_preview_image_sizes;

    my ( $max_width, $max_height ) = ( -999999, -999999 );

    foreach my $type ( "clip1", "zoom", "clip2" ) {
        my $filename = $title->preview_filename( type => $type );
        my $mtime = ( stat $filename )[9];
        my ( $width, $height );
        if (   not $preview_image_sizes->{$type}
            or not $preview_image_sizes->{$type}->{$filename}
            or $preview_image_sizes->{$type}->{$filename}->{mtime} <= $mtime )
        {
            my $gtk_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($filename);
            $preview_image_sizes->{$type}->{$filename} = {
                mtime  => $mtime,
                width  => ( $width = $gtk_pixbuf->get_width ),
                height => ( $height = $gtk_pixbuf->get_height ),
            };
        }
        else {
            $width  = $preview_image_sizes->{$type}->{$filename}->{width};
            $height = $preview_image_sizes->{$type}->{$filename}->{height};
        }
        $max_width  = $width  if $width > $max_width;
        $max_height = $height if $height > $max_height;
    }

    return ( $max_width, $max_height );
}

sub get_preview_image_scale {
    my $self = shift;

    my ( $max_image_width, $max_image_height )
        = $self->get_max_preview_image_size;

    my $widget_width  = int( $self->get_preview_hbox_width / 3 ) - 5;
    my $widget_height = $self->get_preview_hbox_height - 5;

    my $width_scale  = $widget_width / $max_image_width;
    my $height_scale = $widget_height / $max_image_height;

    my $scale = $width_scale < $height_scale ? $width_scale : $height_scale;

    return $scale;
}

sub open_preview {
    my $self   = shift;
    my %par    = @_;
    my ($type) = @par{'type'};

    my $image;
    if ( $type =~ /clip/ ) {
        my $file_type = $type eq 'clip1' ? "orig" : "zoom";
        $image = Video::DVDRip::GUI::FormFactory::ClipImage->new(
            attr        => "title.preview_filename_$file_type",
            attr_left   => "tc_${type}_left",
            attr_right  => "tc_${type}_right",
            attr_top    => "tc_${type}_top",
            attr_bottom => "tc_${type}_bottom",
            image_type  => $type,
        );
    }
    else {
        $image = Video::DVDRip::GUI::FormFactory::ClipImage->new(
            attr    => "title.preview_filename_$type",
            no_clip => 1
        );
    }

    my $ff;
    my $images_generated = 0;

    $ff = Gtk2::Ex::FormFactory->new(
        sync    => 1,
        context => $self->get_context,
        content => [
            Gtk2::Ex::FormFactory::Window->new(
                title => "dvd::rip "
                    . __x( "Preview image: {type}", type => $type ),
                customize_hook => sub {
                    $_[0]->parent->set_resizable(0);
                },
                signal_connect_after => {
                    "destroy" => sub {
                        my ($widget) = @_;
                        $self->make_previews
                            if $type ne 'zoom'
                               && !$images_generated
                               && $image->get_clipping_changed;
                        }
                },
                content => [
                    $image,
                    Gtk2::Ex::FormFactory::DialogButtons->new(
                        clicked_hook => sub {
                            my ($widget) = @_;
                            $ff->change_mouse_cursor("watch");
                            $self->make_previews
                                if $type ne 'zoom' &&
                                   $image->get_clipping_changed;
                            $images_generated = 1;
                            1;
                        },
                    ),
                ],
            ),
        ],
    );

    $ff->open;
    $ff->update;

    1;
}

sub show_preview_images {
    my $self = shift;
    my %par = @_;
    my ($type) = @par{'type'};

    my $title = $self->selected_title;
    return 1 if not $title;

    my ( $image, @types, $filename );

    if ($type) {
        push @types, $type;
    }
    else {
        @types = qw ( clip1 zoom clip2 );
    }

    my $form_factory = $self->get_form_factory;

    foreach $type (@types) {
        $form_factory->get_widget("preview_image_$type")->update;
        $form_factory->get_widget("preview_label_$type")->update;
    }

    1;
}

sub make_previews {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;
    return 1 if $self->progress_is_active;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_make_previews_job($title);

    $job->get_post_callbacks->add(sub {
        $self->get_context->update_object_widgets("title");
        $self->get_context->update_object_widgets("bitrate_calc");
    });

    $exec_flow_gui->start_job($job);

    1;
}

sub grab_preview_frame {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;
    return 1 if $self->progress_is_active;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_grab_preview_frame_job($title);

    $job->get_post_callbacks->add(sub {
        $self->get_context->update_object_widgets("title");
        $self->get_context->update_object_widgets("bitrate_calc");
    });

    $exec_flow_gui->start_job($job);

    1;
}

sub apply_preset_values {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;
    return 1 if not $title->is_ripped;

    my $job_planner   = $self->get_context->get_object("job_planner");
    my $exec_flow_gui = $self->get_context->get_object("exec_flow_gui");
    my $job           = $job_planner->build_apply_preset_job($title);

    $job->get_post_callbacks->add(sub {
        $self->get_context->update_object_widgets("title");
        $self->get_context->update_object_widgets("bitrate_calc");
    });

    $exec_flow_gui->start_job($job);

    1;
}

sub preview_video {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    my $frame_nr = $title->preview_frame_nr;
    my $filename = $title->preview_filename( type => 'orig' );

    return 1 if not defined $frame_nr;

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 1;
    }

    if ( $title->project->rip_mode ne 'rip' ) {
        $self->message_window( message => __
                "This function is only avaiable for ripped DVD's." );
        return 1;
    }

    if ( $frame_nr > $title->frames or $frame_nr !~ /^\d+/ ) {
        $self->message_window(
            message => __ "Illegal frame number. Maximum is "
                . ( $title->frames - 1 ) );
        return 1;
    }

    my $command = $title->get_view_stdin_command(
        command_tmpl => $self->config('play_stdin_command'), );

    $self->log(
        __x("Executing command for video preview: {command}",
            command => $command
        )
    );

    system("$command &");

    1;
}

sub move_clip2_to_clip1 {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 1;
    }

    if ( $title->tc_fast_resize ) {
        $self->message_window( message => __
                "This is not possible because\nfast resizing is enabled." );
        return 1;
    }

    $title->move_clip2_to_clip1;

    $self->make_previews;

    1;
}

sub calc_zoom {
    my $self = shift;
    my %par  = @_;
    my ( $width, $height ) = @par{ 'width', 'height' };

    my $title = $self->selected_title;
    return 1 if not $title;

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 1;
    }

    $title->calc_zoom(
        width  => $width,
        height => $height,
    );

    $self->make_previews;

    1;
}

sub open_zoom_calculator {
    my $self = shift;

    my $title = $self->selected_title;
    return 1 if not $title;

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 1;
    }

    require Video::DVDRip::GUI::ZoomCalculator;

    my $calculator = Video::DVDRip::GUI::ZoomCalculator->new(
        form_factory => $self->get_form_factory, );
    $calculator->open_window;

    1;
}

1;
