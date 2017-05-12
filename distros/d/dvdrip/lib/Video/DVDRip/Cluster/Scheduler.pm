# $Id: Scheduler.pm 2301 2007-04-13 11:20:43Z joern $
#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Scheduler;

use strict;

use base qw(Event::ExecFlow::Scheduler::SimpleMax);

use Locale::TextDomain qw (video.dvdrip);

use Video::DVDRip::Cluster::ExecFlowFrontend;

my $DEBUG = 0;

sub is_exclusive { 1 }

sub get_exec_flow_group         { shift->{exec_flow_group}              }
sub get_max                     { shift->{max}                          }
sub get_cnt                     { shift->{cnt}                          }
sub get_jobs_by_id              { shift->{jobs_by_id}                   }
sub get_jobs_by_project_id      { shift->{jobs_by_project_id}           }
sub get_projects_by_job_id      { shift->{projects_by_job_id}           }

sub set_exec_flow_group         { shift->{exec_flow_group}      = $_[1] }
sub set_max                     { shift->{max}                  = $_[1] }
sub set_cnt                     { shift->{cnt}                  = $_[1] }
sub set_jobs_by_id              { shift->{jobs_by_id}           = $_[1] }
sub set_jobs_by_project_id      { shift->{jobs_by_project_id}   = $_[1] }
sub set_projects_by_job_id      { shift->{projects_by_job_id}   = $_[1] }

sub get_master { Video::DVDRip::Cluster::Master->get_master }

sub new {
    my $class = shift;
    my %par = @_;
    my ($max) = @par{'max'};

    $max ||= 3;

    my $self = bless {
        max                 => $max,
        cnt                 => 0,
        jobs_by_id          => {},
        jobs_by_project_id  => {},
        projects_by_job_id  => {},
    }, $class;

    my $exec_flow_group = Event::ExecFlow::Job::Group->new (
        name                => "all_projects",
        title               => __"All running cluster projects",
        parallel            => 1,
        scheduler           => $self,
        frontend            => Video::DVDRip::Cluster::ExecFlowFrontend->new(),
        fail_with_members   => 0,
        stop_on_failure     => 0,
    );
    
    $self->set_exec_flow_group($exec_flow_group);

    $self->set_jobs_by_id ({
        $exec_flow_group->get_id => $exec_flow_group,
    });

    return $self;
}

sub add_project {
    my $self = shift;
    my ($project) = @_;
    
    my $job = $project->job;
    
    $self->get_exec_flow_group->add_job($job);
    $job->set_group_in_all_childs;
    $job->traverse_all_jobs(sub {
        $_[0]->set_fail_with_members(0)
            if $_[0]->get_type eq 'group';
    });
    
    $self->register_all_jobs($project);

    $self->get_jobs_by_project_id->{$project->id} = $job;

    $job->get_member_finished_callbacks->add(sub {
        $self->get_master->emit_event(
            "PROJECT_UPDATE", $project->id
        );
    });

    $job->get_pre_callbacks->add(sub {
        $project->set_state("running");
        $self->get_master->emit_event(
            "PROJECT_UPDATE", $project->id
        );
    });

    $job->get_post_callbacks->add(sub {
        $project->set_state($job->get_state);
        $self->get_master->emit_event(
            "PROJECT_UPDATE", $project->id
        );
        $project->save;
    });

    $self->get_master->emit_event(
        "JOB_UPDATE", $self->get_exec_flow_group->get_id
    );

    1;
}

sub cancel_project {
    my $self = shift;
    my ($project) = @_;
    
    return unless $self->get_jobs_by_project_id->{$project->id};

    $project->set_cancel_in_progress(1);
    $project->job->cancel;
    $project->set_state("cancelled");
    $project->save;
    $project->set_cancel_in_progress(0);

    1;
}

sub restart_project {
    my $self = shift;
    my ($project) = @_;
    
    return unless $self->get_jobs_by_project_id->{$project->id};

    $project->job->reset_non_finished_jobs;
    $project->set_state("waiting");
    $project->save;

    my $exec_flow_group = $self->get_exec_flow_group;

    $exec_flow_group->set_state("waiting")
        unless $exec_flow_group->get_state eq 'running';

    $exec_flow_group->init_progress_state();

    1;
}

sub remove_project {
    my $self = shift;
    my ($project) = @_;
    
    return unless $self->get_jobs_by_project_id->{$project->id};

    my $job             = $project->job;
    my $exec_flow_group = $self->get_exec_flow_group;

    my $cnt = $job->get_type eq 'group' ? $job->get_progress_cnt : 1;
    $exec_flow_group->decrease_progress_cnt($cnt);

    $exec_flow_group->remove_job($job);

    $self->deregister_all_jobs($job);

    delete $self->get_jobs_by_project_id->{$project->id};
    
    $self->get_master->emit_event(
        "JOB_UPDATE", $self->get_exec_flow_group->get_id
    );

    1;
}

sub register_all_jobs {
    my $self = shift;
    my ($project, $job) = @_;
    
    $job ||= $project->job;
    
    $self->get_jobs_by_id->{$job->get_id} = $job;
    $self->get_projects_by_job_id->{$job->get_id} = $project;
    
    if ( $job->get_type eq 'group' ) {
        foreach my $child ( @{$job->get_jobs} ) {
            $self->register_all_jobs($project, $child);
        }
    }
    
    1;
}

sub deregister_all_jobs {
    my $self = shift;
    my ($job) = @_;
    
    delete $self->get_jobs_by_id->{$job->get_id};
    delete $self->get_projects_by_job_id->{$job->get_id};

    if ( $job->get_type eq 'group' ) {
        foreach my $child ( @{$job->get_jobs} ) {
            $self->deregister_all_jobs($child);
        }
    }
    
    1;
}

sub init {
    my $self = shift;
    
    $self->get_exec_flow_group->set_group_in_all_childs;
    $self->get_exec_flow_group->init_progress_state();

    1;
}

sub job_finished {
    my $self = shift;
    my ($job) = @_;
    
    return if $job->get_type ne 'command';
    
    my $node = $job->get_node;
    $node->set_assigned_job(undef);
    $job->set_node(undef);

    $node->set_state("idle")
        if $node->state ne 'stopped';

    $job->reset if $job->get_cancelled;
    
    $self->run;

    1;
}

#---------------------------------------------------------------------

sub run {
    my $self = shift;
    
    #-- get idle nodes
    my ($local_nodes_lref, $remote_nodes_lref) = $self->get_idle_nodes;

    #-- nothing to do if no node is idle
    return 1 if @{$local_nodes_lref} + @{$remote_nodes_lref} == 0;

    #-- collect jobs, separate local from remote capable jobs
    my (@local_jobs, @remote_jobs);
    $self->traverse_job_tree(
        $self->get_exec_flow_group,
        \@local_jobs,
        \@remote_jobs,
        scalar(@{$local_nodes_lref}),
        scalar(@{$remote_nodes_lref}),
    );

    if ( @local_jobs == 0 && @remote_jobs == 0 ) {
        #-- no jobs found. check if a project has jobs with errors
        #-- obviously have jobs executed with errors
        foreach my $project_job ( @{$self->get_exec_flow_group->get_jobs} ) {
            if ( $project_job->get_state eq 'running' &&
                 $project_job->get_error_message eq '' ) {
                my $has_errors;
                $project_job->traverse_all_jobs (sub {
                    my ($job) = @_;
                    if ( $job->get_error_message ) {
                        $has_errors = 1;
                        $project_job->add_job_error_message($job);
                    }
                });
                $project_job->execution_finished if $has_errors;
            }
        }
        return;
    }

    #-- start local jobs on local nodes first
$DEBUG && print "-"x80,"\n";
$DEBUG && print "local jobs   = ".join("\n               ", map {$_->get_info} @local_jobs)."\n";
$DEBUG && print "local nodes  = ".join("\n               ", map {$_->name}     @{$local_nodes_lref})."\n";
    if ( @local_jobs && @{$local_nodes_lref} ) {
        $self->start_jobs_on_nodes(\@local_jobs, $local_nodes_lref);
    }
    
    #-- start remote jobs on remote nodes next
$DEBUG && print "-"x80,"\n";
$DEBUG && print "remote jobs  = ".join("\n               ", map {$_->get_info} @remote_jobs)."\n";
$DEBUG && print "remote nodes = ".join("\n               ", map {$_->name}     @{$remote_nodes_lref})."\n";
    if ( @remote_jobs && @{$remote_nodes_lref} ) {
        $self->start_jobs_on_nodes(\@remote_jobs, $remote_nodes_lref);
    }

    #-- do we have remote jobs left and local nodes?
$DEBUG && print "-"x80,"\n";
$DEBUG && print "remote jobs  = ".join("\n               ", map {$_->get_info} @remote_jobs)."\n";
$DEBUG && print "local nodes  = ".join("\n               ", map {$_->name}     @{$local_nodes_lref})."\n";
    if ( @remote_jobs && @{$local_nodes_lref} ) {
        $self->start_jobs_on_nodes(\@remote_jobs, $local_nodes_lref);
    }

    #-- do we have local jobs left and remote nodes?
$DEBUG && print "-"x80,"\n";
$DEBUG && print "local jobs   = ".join("\n               ", map {$_->get_info} @local_jobs)."\n";
$DEBUG && print "remote nodes = ".join("\n               ", map {$_->name}     @{$remote_nodes_lref})."\n";
    if ( @local_jobs && @{$remote_nodes_lref} ) {
        $self->start_jobs_on_nodes(\@local_jobs, $remote_nodes_lref);
    }
$DEBUG && print "-"x80,"\n";

    1;
}

sub get_idle_nodes {
    my $self = shift;
    
    my $master = $self->get_master;
    my (@local_nodes, @remote_nodes) = @_;
    
    foreach my $node ( sort { $b->speed_index <=> $a->speed_index }
                       @{$master->nodes} ) {
        next if $node->state ne 'idle';
        if ( $node->data_is_local ) {
            push @local_nodes, $node;
        }
        else {
            push @remote_nodes, $node
        }
    }
    
    return (\@local_nodes, \@remote_nodes);
}

sub traverse_job_tree {
    my $self = shift;
    my ($job, $local_jobs_lref, $remote_jobs_lref, $local_cnt, $remote_cnt) = @_;
    
    return if @{$local_jobs_lref}  >= $local_cnt &&
              @{$remote_jobs_lref} >= $remote_cnt;

    if ( $job->get_type eq 'group' ) {
        if ( $job->get_state =~ /^(?:waiting|running)$/ &&
             ( !$job->get_group ||
               $job->get_group->dependencies_ok($job)
             ) ) {
            foreach my $child ( @{$job->get_jobs} ) {
                $self->traverse_job_tree(
                    $child, $local_jobs_lref, $remote_jobs_lref,
                    $local_cnt, $remote_cnt
                );
                return if @{$local_jobs_lref}  >= $local_cnt &&
                          @{$remote_jobs_lref} >= $remote_cnt;
            }
        }
    }
    else {
        if ( $job->get_state eq 'waiting' &&
             $job->get_group->dependencies_ok($job) ) {
            if ( $job->get_stash->{prefer_local_access} ) {
                push @{$local_jobs_lref}, $job;
            }
            else {
                push @{$remote_jobs_lref}, $job;
            }
        }
    }
}

sub start_jobs_on_nodes {
    my $self = shift;
    my ($jobs, $nodes) = @_;
    
    while ( my $job = shift @{$jobs} ) {
        my $node = shift @{$nodes};
        last if !$node;
        $job->set_node($node);
        $self->start_job($job);
    }

    1;
}

sub start_job {
    my $self = shift;
    my ($job) = @_;
    
    #-- start all parent groups if not yet started
    my $group = $job->get_group;
    while ( $group ) {
        if ( $group->get_state eq 'waiting' ) {
            $group->start;
        }
        $group = $group->get_group;
    }

    #-- start job via group
    $job->get_node->set_state("running");
    $job->get_node->set_assigned_job($job);
    $job->get_group->start_child_job($job);
    
    1;    
}

1;
