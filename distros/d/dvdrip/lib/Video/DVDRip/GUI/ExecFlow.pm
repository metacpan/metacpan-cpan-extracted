# $Id: ExecFlow.pm 2390 2009-12-19 13:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::ExecFlow;

$Event::ExecFlow::DEBUG = 0;

use strict;
use Event::ExecFlow::Scheduler::SimpleMax;

sub job                         { shift->{job}                          }
sub set_job                     { shift->{job}                  = $_[1] }

use base qw(
    Video::DVDRip::GUI::Base
    Event::ExecFlow::Frontend
);

use Locale::TextDomain qw (video.dvdrip);

sub start_job {
    my $self = shift;
    my ($job, $no_diskspace_check) = @_;

    return if $self->job;
    return unless $no_diskspace_check || $self->diskspace_ok($job);

    if ( $job->get_type eq 'group' ) {
        my $scheduler = Event::ExecFlow::Scheduler::SimpleMax->new (
            max => 1,
        );
        $job->set_scheduler($scheduler);
    }

    $self->set_job($job);
    
    $self->get_context->get_object("progress")->open (
        cb_cancel => sub { $job->cancel },
    );

    return $self->SUPER::start_job($job);
}

sub diskspace_ok {
    my $self = shift;
    my ($job) = @_;

    my $max_diskspace_consumed = $job->get_max_diskspace_consumed;
    my $free = $self->project->get_free_diskspace ( kb => 1 );

    $max_diskspace_consumed = int ($max_diskspace_consumed/1024);
    $free                   = int($free/1024);

    return 1 if $max_diskspace_consumed < $free;

    $self->log (
        __x("This task needs about {needed} MB, {free} MB are free.",
            needed => $max_diskspace_consumed,
            free   => $free)
    );

    $self->confirm_window (
	message =>
	    __x("Warning: diskspace is low. This task needs\n".
                "about {needed} MB, but only {free} MB are available.\n".
                "Do you want to continue anyway?",
                needed => $max_diskspace_consumed,
                free => $free),
	yes_callback => sub {
            $self->start_job($job, 1);
	},
	yes_label   => __"Yes",
	no_label    => __"No",
	omit_cancel => 1,
    );

    return 0
}

sub report_job_start {
    my $self = shift;
    my ($job) = @_;

    #-- change mouse cursor for synchronous jobs
    if ( $job->get_exec_type eq 'sync' ) {
        $self->get_form_factory->change_mouse_cursor("watch");
        Gtk2->main_iteration while Gtk2->events_pending;
    }

    $self->log(__x("Start job '{name}'", name => $job->get_info));
    
    1;
}

sub report_job_progress {
    my $self = shift;
    my ($job) = @_;

    my $details_ff = $self->get_context->get_object("progress")->details_ff;

    if ( $details_ff ) {
        $details_ff->get_widget("exec_flow")->update_job($job);
    }

    if ( ! $job->isa("Event::ExecFlow::Job::Group") &&
         ! $job->get_stash->{hide_progress} ||
           $job->get_stash->{show_progress} ) {
        $self->get_context->get_object("progress")->update (
            value   => $job->get_progress_fraction,
            label   => $job->get_progress_text,
        );
        if ( $job->get_exec_type eq 'sync' ) {
            Gtk2->main_iteration while Gtk2->events_pending;
        }
    }

    1;
}

sub report_job_error {
    my $self = shift;
    my ($job) = @_;

    #-- No report for jobs which are member of a group. The
    #-- toplevel group will report the error as well and
    #-- we don't want to see the same error multiple times
    return if $job->get_group;

    $self->log(
        __x("Job '{name}' exited with error: {error}",
            name  => $job->get_info,
            error => $job->get_error_message )
    );

    $self->error_window (
        message => $job->get_error_message
    );
    
    $self->job->cancel if $self->job;

    $self->get_context->get_object("progress")->close;
    $self->set_job();

    1;
}

sub report_job_warning {
    my $self = shift;
    my ($job, $warning) = @_;

    return if $job->get_type eq 'group';


    $warning ||= $job->get_warning_message;

    $self->log(
        __x("Job '{name}' warning: {warning}",
            name    => $job->get_info,
            warning => $warning )
    );

    $self->message_window ( message => $warning );

    1;    
}

sub report_job_finished {
    my $self = shift;
    my ($job) = @_;

# print "FINISHED: ".$job->get_progress_text." -- ".$job->get_group."\n";

    if ( $job->get_cancelled ) {
        $self->log(__x("Job '{name}' cancelled", name => $job->get_info));
    }
    else {
        $self->log(__x("Job '{name}' finished", name => $job->get_info));
    }

    #-- don't close if this is not the most top-level job
    if ( !$job->get_group ) {
        $self->get_context->get_object("progress")->close;
        $self->set_job();
    }

    #-- change back mouse cursor if job was synchronous
    if ( $job->get_exec_type eq 'sync' ) {
        $self->get_form_factory->change_mouse_cursor();
        Gtk2->main_iteration while Gtk2->events_pending;
    }

    1;
}

sub report_job_added {
    my $self = shift;
    my ($job) = @_;
    
    my $details_ff = $self->get_context->get_object("progress")->details_ff;
    if ( $details_ff ) {
        $details_ff->get_widget("exec_flow")->add_job($job);
    }

    1;
}

sub log {
    my $self = shift;
    return $self->SUPER::log(@_);
}

sub signal_title_probed {
    my $self = shift;
    my ($title) = @_;
    
    my $toc_gui = $self->get_context->get_object("toc_gui");
    $toc_gui->append_content_list( title => $title );

    1;    
}

sub signal_program_exit {
    my $self = shift;

    $self->get_context->get_object("main")->exit_program (force => 1);
    
    1;    
}

sub signal_video_bitrate_changed {
    my $self = shift;
    my ($title) = @_;

    return if $title->nr != $self->selected_title->nr;

    $self->get_context->update_object_attr_widgets("title.tc_video_bitrate");

    1;    
}

sub signal_audio_bitrate_changed {
    my $self = shift;
    my ($title, $codec_attr) = @_;

    return if $title->nr != $self->selected_title->nr;

    $self->get_context->update_object_attr_widgets("audio_track","bitrate");

    1;    
}

sub signal_toc_info_changed {
    my $self = shift;
    
    $self->get_context->update_object_attr_widgets("content","titles");
    
    1;
}

1;
           
 
