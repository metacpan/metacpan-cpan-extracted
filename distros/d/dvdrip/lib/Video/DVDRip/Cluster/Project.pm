# $Id: Project.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Project;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Project;

use Video::DVDRip::Cluster::Title;
use Video::DVDRip::Cluster::PSU;
use Video::DVDRip::Cluster::JobPlanner;

use Carp;
use strict;

sub id                          { shift->{id}                           }
sub title                       { shift->{title}                        }
sub jobs                        { shift->{jobs}                         }
sub assigned_job                { shift->{assigned_job}                 }
sub start_time                  { shift->{start_time}                   }
sub end_time                    { shift->{end_time}                     }
sub runtime                     { shift->{runtime}                      }
sub job                         { shift->{job}                          }
sub cancel_in_progress          { shift->{cancel_in_progress}           }
sub state                       { shift->{state}                        }

sub set_id                      { shift->{id}                   = $_[1] }
sub set_title                   { shift->{title}                = $_[1] }
sub set_jobs                    { shift->{jobs}                 = $_[1] }
sub set_assigned_job            { shift->{assigned_job}         = $_[1] }
sub set_start_time              { shift->{start_time}           = $_[1] }
sub set_end_time                { shift->{end_time}             = $_[1] }
sub set_runtime                 { shift->{runtime}              = $_[1] }
sub set_job                     { shift->{job}                  = $_[1] }
sub set_cancel_in_progress      { shift->{cancel_in_progress}   = $_[1] }

sub set_state {
    my $self = shift;
    my ($new_state) = @_;

    my $old_state = $self->state;
    $self->{state} = $new_state;

    if ( $new_state eq 'running' and not $self->start_time ) {
        $self->set_start_time(time);
    }

    if ( $new_state eq 'finished' and $old_state ne 'finished' ) {
        $self->set_end_time(time);
        my $runtime = $self->format_time(
            time => $self->end_time - $self->start_time );
        $self->set_runtime($runtime);
    }

    Video::DVDRip::Cluster::Master->get_master->emit_event( "PROJECT_UPDATE",
        $self->id );

    $new_state;
}

sub load {
    my $self = shift;

    $self->SUPER::load(@_);

    # extract job state
    my $job_state = $self->job;
    
    # recreate job plan
    if ( $self->state ne 'not scheduled' ) {
        $self->create_job_plan;
        $self->job->restore_state($job_state);
        my $scheduler = Video::DVDRip::Cluster::Master->get_master->scheduler;
        $scheduler->add_project($self);
    }

    # assign project references to contained objects
    $self->title->set_project($self);

    1;
}

sub save {
    my $self = shift;

    $self->SUPER::save(@_);

    Video::DVDRip::Cluster::Master->get_master->emit_event( "PROJECT_UPDATE",
        $self->id );

    1;
}

sub get_save_data_text {
    my $self = shift;

    if ( !$self->job || ref $self->job eq "HASH" ) {
        #-- nothing special if job's state is already serialized
        return $self->SUPER::get_save_data_text();
    }
    else {
        #-- preserve job execution state
        my $job = $self->job;
    
        my $job_state = $job->backup_state;
        $self->set_job($job_state);

        # get save data by calling super method
        my $data = $self->SUPER::get_save_data_text();

        # restore job
        $self->set_job($job);
        
        return $data;
    }
}

sub vob_dir {
    my $self = shift;

    my $job = $Event::ExecFlow::JOB;

    return $job->get_node->data_base_dir . "/" . $self->name . "/vob";
}

sub avi_dir {
    my $self = shift;

    my $job  = $Event::ExecFlow::JOB;
    my $node = $job->get_node;

    return $node->data_base_dir . "/"
        . $self->name
        . "/cluster/"
        . $node->name;
}

sub final_avi_dir {
    my $self = shift;

    my $job  = $Event::ExecFlow::JOB;
    my $node = $job->get_node;

    return $node->data_base_dir . "/" . $self->name . "/avi";
}

sub snap_dir {
    my $self = shift;

    my $job  = $Event::ExecFlow::JOB;
    return $self->SUPER::snap_dir() if !$job;
    my $node = $job->get_node;

    return $node->data_base_dir . "/" . $self->name . "/tmp";
}

sub label {
    my $self = shift;
    return $self->name . " (#" . $self->title->nr . ")";
}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $project, $title_nr ) = @par{ 'project', 'title_nr' };

    # bless instance with this class
    bless $project, $class;

    # remove content and save only the selected title
    my $title = $project->content->titles->{$title_nr};

    bless $title, "Video::DVDRip::Cluster::Title";
    $project->set_title($title);
    $project->content->set_titles( { $title_nr => $title } );

    # rebless psu
    my $psu_selected;
    foreach my $psu ( @{ $title->program_stream_units } ) {
        bless $psu, "Video::DVDRip::Cluster::PSU";

        # PSU selection is currently DISABLED,
        # so all PSUs are always selected
        if ( 1 or $psu->frames >= 1000 ) {
            $psu->set_selected(1);
            $psu_selected = 1;
        }
    }

    # select all psu if none was selected
    if ( not $psu_selected ) {
        $_->set_selected(1) for @{ $title->program_stream_units };
    }

    # initialize project title parameters
    $project->title->set_with_cleanup(1);
    $project->title->set_frames_per_chunk(10000);

    return $project;
}

sub create_job_plan {
    my $self = shift;

    $self->log("Setting up job plan");
    
    my $scheduler = Video::DVDRip::Cluster::Master->get_master->scheduler;

    my $job_planner = Video::DVDRip::Cluster::JobPlanner->new (
        project => $self,
    );
    
    my $job = $job_planner->build_cluster_transcode_job();
    $job->set_scheduler($scheduler);

    $self->set_job($job);

    1;
}

#============================================================================

sub progress {
    my $self = shift;

    my $scheduler = Video::DVDRip::Cluster::Master->get_master->scheduler;
    my $job       = $scheduler->get_jobs_by_project_id->{$self->id};
    
    # maybe undef if not scheduled yet
    return "" unless $job;

    return $job->get_progress_text;
}

sub jobs_list {
    my $self = shift;

    my @jobs;
    foreach my $job ( @{ $self->jobs } ) {
        push @jobs,
            [
            $job->id,            $job->nr,    $job->info,
            $job->dep_as_string, $job->state, $job->progress,
            ];
    }

    return \@jobs;
}

sub get_job_by_id {
    my $self = shift;
    my ($job_id) = @_;

    foreach my $job ( @{ $self->jobs } ) {
        return $job if $job->id == $job_id;
    }

    croak "Can't find job with id=$job_id";
}

sub get_dependent_jobs {
    my $self = shift;
    my %par = @_;
    my ($job) = @par{'job'};

    # get direct dependent jobs
    my @dep_jobs;
    foreach my $j ( @{ $self->jobs } ) {
        foreach my $dj ( @{ $j->depends_on_jobs } ) {
            if ( $dj->id == $job->id ) {
                push @dep_jobs, $j;
                last;
            }
        }
    }

    # go into recursion to find the jobs, which
    # depend on the direct dependend jobs
    foreach my $j (@dep_jobs) {
        my $j_dep_jobs = $self->get_dependent_jobs( job => $j );
        push @dep_jobs, @{$j_dep_jobs};
    }

    return \@dep_jobs;
}

sub reset_job {
    my $self = shift;
    my %par = @_;
    my ($job_id) = @par{'job_id'};

    my $job = $self->get_job_by_id($job_id);
    return
        if $job->state  ne 'finished'
        and $job->state ne 'aborted';

    my $dep_jobs = $self->get_dependent_jobs( job => $job );

    # check if all dependent jobs aren't running
    foreach my $dep_job ( @{$dep_jobs} ) {
        return if $dep_job->state eq 'running';
    }

    # now reset all dependent jobs after resetting the
    # parent job
    $job->set_state('waiting');

    foreach my $dep_job ( @{$dep_jobs} ) {
        $dep_job->set_state('waiting');
    }

    # determine project state
    $self->determine_state;

    $self->save;

    Video::DVDRip::Cluster::Master->get_master->job_control;

    1;
}

1;
