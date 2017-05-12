# $Id: Progress.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Progress;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use strict;
use Carp;
use Data::Dumper;
use Cwd;

use POSIX qw(:errno_h);

sub cb_cancel                   { shift->{cb_cancel}                    }
sub is_active                   { shift->{is_active}                    }
sub progress_state              { shift->{progress_state}               }
sub gtk_progress                { shift->{gtk_progress}                 }
sub max_value                   { shift->{max_value}                    }
sub details_ff                  { shift->{details_ff}                   }
sub paused                      { shift->{paused}                       }
sub show_details                { shift->{show_details}                 }

sub set_cb_cancel               { shift->{cb_cancel}            = $_[1] }
sub set_is_active               { shift->{is_active}            = $_[1] }
sub set_progress_state          { shift->{progress_state}       = $_[1] }
sub set_gtk_progress            { shift->{gtk_progress}         = $_[1] }
sub set_max_value               { shift->{max_value}            = $_[1] }
sub set_details_ff              { shift->{details_ff}           = $_[1] }
sub set_paused                  { shift->{paused}               = $_[1] }
sub set_show_details            { shift->{show_details}         = $_[1] }

sub build_factory {
    my $self = shift;

    $self->get_context->set_object( "progress" => $self );

    my $progress = Gtk2::Ex::FormFactory::Form->new(
        title   => __ "Status",
        object  => "project",
        content => [
            Gtk2::Ex::FormFactory::HBox->new(
                active_cond    => sub { $self->is_active },
                active_depends => "progress.is_active",
                content        => [
                    Gtk2::Ex::FormFactory::ProgressBar->new(
                        name   => "progress",
                        attr   => "progress.progress_state",
                        expand => 1,
                    ),
                    Gtk2::Ex::FormFactory::ToggleButton->new(
                        attr       => "progress.show_details",
                        tip        => __ "Show job plan and progress details",
                        active     => 0,
                        true_label => "",
                        false_label        => "",
                        stock              => "gtk-zoom-in",
                        changed_hook_after => sub {
                            $self->toggle_details_window;
                            1;
                        },
                    ),
                    Gtk2::Ex::FormFactory::ToggleButton->new(
                        attr         => "progress.paused",
                        name         => "progress_pause",
                        stock        => "gtk-media-pause",
                        tip          => __ "Pause and resume processing",
                        label        => "",
                        false_label  => "",
                        true_label   => "",
                        changed_hook => sub {
                            my $job = $self->get_context->get_object_attr(
                                "exec_flow_gui.job");
                            $job->pause;
                            1;
                        },
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        name         => "progress_cancel",
                        stock        => "gtk-cancel",
                        tip          => __ "Cancel processing",
                        label        => "",
                        clicked_hook => sub {
                            my $cb_cancel = $self->cb_cancel;
                            &$cb_cancel() if $cb_cancel;
                            1;
                        },
                    ),
                ],
            ),
        ],
    );

    return $progress;
}

sub open {
    my $self = shift;
    my %par = @_;
    my ( $max_value, $label, $cb_cancel )
        = @par{ 'max_value', 'label', 'cb_cancel' };

    $self->set_gtk_progress(
        $self->get_form_factory->get_widget("progress")->get_gtk_widget,
    );

    $self->set_is_active(1);
    $self->set_max_value($max_value);
    $self->set_cb_cancel($cb_cancel);
    $self->set_paused(0);

    $self->get_context->update_object_attr_widgets("progress.is_active");
    $self->get_context->update_object_attr_widgets("progress.paused");

    $self->details_ff->update if $self->details_ff;

    1;
}

sub update {
    my $self = shift;
    my %par  = @_;
    my ( $value, $label ) = @par{ 'value', 'label' };

    $value = 0 if $value < 0;
    $value = 1 if $value > 1;

    $self->gtk_progress->set_text($label);
    $self->gtk_progress->set_fraction($value);

    1;
}

sub close {
    my $self = shift;

    $self->gtk_progress->set_fraction(0);

    $self->set_is_active(0);
    $self->set_idle_label;

    $self->get_context->update_object_attr_widgets("progress.is_active");

    if ( $self->details_ff ) {
        $self->details_ff->get_widget("progress_detail_buttons")->update_all;
    }

    1;
}

sub cancel {
    my $self = shift;

    my $cb_cancel = $self->cb_cancel;

    &$cb_cancel() if $cb_cancel;

    $self->close;

    1;
}

sub set_idle_label {
    my $self = shift;

    my $project = eval { $self->project };

    my $label;
    if ($project) {
        my $free = $project->get_free_diskspace;
        $label = __x( "Free diskspace: {free} MB", free => $free );
    }
    else {
        $label = "";
    }

    $self->gtk_progress->set_text($label);

    1;
}

sub toggle_details_window {
    my $self = shift;

    $self->build_details_ff if $self->show_details && !$self->details_ff;

    1;
}

sub build_details_ff {
    my $self = shift;

    my $gtk_window = $self->get_form_factory->get_form_factory_gtk_window;

    my $ff = Gtk2::Ex::FormFactory->new(
        context => $self->get_context,
        content => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => __"dvd::rip - Job plan and progress details",
                inactive       => "invisible",
                active_cond    => sub { $self->show_details },
                active_depends => "progress.show_details",
                content        => [
                    Gtk2::Ex::FormFactory::ExecFlow->new(
                        name       => "exec_flow",
                        attr       => "exec_flow_gui.job",
                        scrollbars => [ 'automatic', 'automatic' ],
                        width      => 640,
                        height     => 300,
                        expand     => 1,
                        # add_columns => [ "diskspace_consumed", "diskspace_freed" ],
                    ),
                    Gtk2::Ex::FormFactory::HBox->new(
                        name       => "progress_detail_buttons",
                        properties => { homogeneous => 1 },
                        content    => [
                            Gtk2::Ex::FormFactory::Label->new(
                                label  => " ",
                                expand => 1,
                            ),
                            Gtk2::Ex::FormFactory::Button->new(
                                stock        => "gtk-zoom-out",
                                label        => __ "Hide window",
                                tip          => __ "Hide details window",
                                clicked_hook => sub {
                                    $self->get_context->set_object_attr(
                                        "progress.show_details", 0 );
                                },
                            ),
                            Gtk2::Ex::FormFactory::ToggleButton->new(
                                attr        => "progress.paused",
                                name        => "details_progress_pause",
                                stock       => "gtk-media-pause",
                                false_label => __ "Pause jobs",
                                true_label  => __ "Resume",
                                tip => __ "Pause and resume processing",
                                changed_hook => sub {
                                    my $job
                                        = $self->get_context->get_object_attr(
                                        "exec_flow_gui.job");
                                    $job->pause;
                                    1;
                                },
                                active_cond => sub { $self->is_active },
                                active_depends => "progress.is_active",
                            ),
                            Gtk2::Ex::FormFactory::Button->new(
                                name         => "details_progress_cancel",
                                stock        => "gtk-cancel",
                                label        => __ "Cancel jobs",
                                tip          => __ "Cancel all running jobs",
                                clicked_hook => sub {
                                    my $cb_cancel = $self->cb_cancel;
                                    &$cb_cancel() if $cb_cancel;
                                    1;
                                },
                                active_cond => sub { $self->is_active },
                                active_depends => "progress.is_active",
                            ),
                        ],
                    ),
                ],
                closed_hook => sub {
                    $self->get_context->set_object_attr(
                        "progress.show_details", 0 );
                    $self->set_details_ff(undef);
                },
            ),
        ],
    );

    $ff->build;
    $ff->update;
    $ff->show;

    $self->set_details_ff($ff);

    1;
}

1;
