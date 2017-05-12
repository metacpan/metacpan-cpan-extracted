# $Id: ExecFlowFrontend.pm 2187 2006-08-16 19:34:38Z joern $
#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::ExecFlowFrontend;

use base qw(Event::ExecFlow::Frontend);

use strict;
use Locale::TextDomain qw (video.dvdrip);

sub get_master { Video::DVDRip::Cluster::Master->get_master }

sub log {
    my $self = shift;
    my ($msg) = @_;

    $self->get_master->log($msg);

    1; 
}

sub report_job_added {
    my $self = shift;
    my ($job) = @_;

    $self->get_master->emit_event("JOB_ADDED", $job->get_id);

    1;
}

sub report_job_removed {
    my $self = shift;
    my ($job) = @_;

    $self->get_master->emit_event("JOB_REMOVED", $job->get_id);

    1;
}

sub report_job_start {
    my $self = shift;
    my ($job) = @_;

    $self->log(__x("Start job '{name}'", name => $job->get_info));

    1;
}

sub report_job_progress {
    my $self = shift;
    my ($job) = @_;

    $self->get_master->emit_event(
        "JOB_UPDATE",
        $job->get_id
    );

    if ( $job->get_type eq 'command' && $job->get_node ) {
        $self->get_master->emit_event(
            "NODE_PROGRESS_UPDATE",
            $job->get_node->name,
            $job->get_info,
            $job->get_progress_stats,
        );
    }

    1;
}

sub report_job_error {
    my $self = shift;
    my ($job) = @_;

    return if $job->get_type eq 'group';

    $self->log(
        __x("Job '{name}' exited with error: {error}",
            name  => $job->get_info,
            error => $job->get_error_message )
    );

    1;
}

sub report_job_warning {
    my $self = shift;
    my ($job, $warning) = @_;
    
    return if $job->get_group;

    $warning ||= $job->get_warning_message;

    $self->log(
        __x("Job '{name}' warning: {warning}",
            name    => $job->get_info,
            warning => $warning )
    );

    1;
}

sub report_job_finished {
    my $self = shift;
    my ($job) = @_;

    if ( $job->get_cancelled ) {
        $self->log(__x("Job '{name}' cancelled", name => $job->get_info));
    }
    else {
        $self->log(__x("Job '{name}' finished", name => $job->get_info));
    }

    my $master    = $self->get_master;
    my $scheduler = $master->scheduler;
    my $project   = $scheduler->get_projects_by_job_id->{$job->get_id};

    return unless $project;
    $master->emit_event("PROJECT_UPDATE", $project->id);

    1;
}

sub signal_video_bitrate_changed {
    1;
}

1;
