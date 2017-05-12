# $Id: JobPlanner.pm 2368 2009-02-22 18:26:44Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::JobPlanner;

use base qw(Video::DVDRip::JobPlanner);

use Carp;
use strict;

use Locale::TextDomain qw (video.dvdrip);
use Event::ExecFlow qw (video.dvdrip);


sub build_cluster_transcode_job {
    my $self = shift;

    my $project = $self->get_project;
    my $title   = $project->title,

    my @title_jobs;
    my ($job, $last_job);

    #-- work has to be done per PSU. Jobs for all PSU's
    #-- are collected here
    my @all_psu_jobs;
    foreach my $psu ( @{ $title->program_stream_units } ) {
        next if not $psu->selected;
        push @all_psu_jobs, $self->build_cluster_psu_jobs($title, $psu);
    }

    #-- build a group for all PSU jobs
    push @title_jobs, $job = Event::ExecFlow::Job::Group->new (
        title    => __x("Process all PSU's - title #{nr}", nr => $title->nr),
        jobs     => \@all_psu_jobs,
        parallel => 1,
    );
    $last_job = $job;

    if ( @all_psu_jobs > 1 ) {
        #-- merge all PSU's
        push @title_jobs, $job = $self->build_cluster_merge_psu_files_job($title);
        $job->set_depends_on([$last_job]);
        $last_job = $job;
    }
    else {
        #-- move PSU 0 file to final destination
        push @title_jobs, $job = Event::ExecFlow::Job::Command->new (
            title       => __"Move PSU #0 file to final destination",
            command     => sub {
                "mv ".
                 $title->audio_video_psu_file." ".
                 $title->target_avi_file,
            },
            stash       => { psu => 0 },
            depends_on  => [ $last_job ],
        );
        $last_job = $job;
    }

    #-- split video file
    if ( $title->tc_split ) {
        push @title_jobs, $job = $self->build_split_job($title);
        $job->set_depends_on([$last_job]);
        $job->set_stash({ prefer_local_access => 1 });
        $last_job = $job;
    }

    #-- vobsub generation?
    if ( $title->has_vobsub_subtitles ) {
        push @title_jobs, $job = $self->build_vobsub_job($title);
        $job->set_depends_on([$last_job]);
        my $stash_method = $job->get_type eq 'group' ? "add_stash_to_all_jobs" : "add_stash";
        $job->$stash_method({ prefer_local_access => 1 });
        $last_job = $job;
    }

    #-- build a group for all jobs of this title
    return Event::ExecFlow::Job::Group->new (
        title    => __x("Project '{project}' - title #{nr}",
                        project => $project->name, nr => $title->nr ),
        jobs     => \@title_jobs,
        parallel => 1,
    );
}        

sub build_cluster_psu_jobs {
    my $self = shift;
    my ($title, $psu) = @_;
    
    my ($job, $last_job);
    
    #-- calculate number of chunks for this PSU
    my $frames_per_chunk = $title->frames_per_chunk || 10000;
    my $psu_frames       = $psu->frames;
    my $psu_nr           = $psu->nr;
    my $chunk_cnt        = int( $psu_frames / $frames_per_chunk );

    my $nodes_cnt =
        1 + Video::DVDRip::Cluster::Master->get_master->get_online_nodes_cnt;

    $chunk_cnt = $nodes_cnt if $chunk_cnt < $nodes_cnt;
    $chunk_cnt = 2          if $chunk_cnt < 2;
    $psu->set_chunk_cnt($chunk_cnt);

    #-- jobs for this PSU are collected here
    my @psu_jobs;

    #-- first all audio transcoding jobs
    my $tc_audio_job = $self->build_cluster_audio_jobs($title, $psu);
    push @psu_jobs, $tc_audio_job if $tc_audio_job;

    #-- then all video chunk jobs
    my $tc_video_job;
    push @psu_jobs, $tc_video_job = $self->build_cluster_video_chunk_jobs($title, $psu);

    #-- add jobs for video chunk merging
    my $tc_merge_video_job = $self->build_cluster_merge_video_chunks_job ($title, $psu);
    $tc_merge_video_job->set_depends_on([$tc_video_job]);
    push @psu_jobs, $tc_merge_video_job;

    #-- add jobs for audio tracks merging
    if ( $tc_audio_job ) {
        my $tc_merge_audio_job = $self->build_cluster_merge_audio_tracks_job ($title, $psu);
        if ( $tc_merge_audio_job ) {
            $tc_merge_audio_job->set_depends_on([$tc_merge_video_job, $tc_audio_job]);
            push @psu_jobs, $tc_merge_audio_job;
        }
        else {
            #-- with one audio track video need to depend on the audio job
            push @{$tc_merge_video_job->{depends_on}}, $tc_audio_job->get_name;
        }
    }

    #-- build a group for all jobs of this PSU
    return Event::ExecFlow::Job::Group->new (
        title    => __x("Process PSU #{nr}", nr => $psu->nr),
        jobs     => \@psu_jobs,
        parallel => 1,
    );
}

sub build_cluster_audio_jobs {
    my $self = shift;
    my ($title, $psu) = @_;
    
    my @audio_jobs;
    foreach my $audio ( @{$title->audio_tracks} ) {
        #-- skip deactivated tracks
        next if $audio->tc_target_track == -1;

        my $vob_nr = $audio->tc_nr;
        my $avi_nr = $audio->tc_target_track;

        my $job = $self->build_transcode_audio_job($title, $vob_nr, $avi_nr);

        $job->set_stash ({
            prefer_local_access => 1,
            psu                 => $psu->nr,
            chunk_cnt           => $psu->chunk_cnt,
            vob_nr              => $vob_nr,
            avi_nr              => $avi_nr,
        });

        push @audio_jobs, $job;
    }
    
    return unless @audio_jobs;

    return Event::ExecFlow::Job::Group->new (
        title    => __x("Process all audio tracks - title #{nr}, PSU #{psu}",
                        nr => $title->nr, psu => $psu->nr ),
        jobs     => \@audio_jobs,
        parallel => 1,
    );
}

sub build_cluster_merge_audio_tracks_job {
    my $self = shift;
    my ($title, $psu) = @_;
    
    my $mode = $title->is_ogg ? "all" : "skip1";
    
    my @merge_audio_jobs;
    my $first = 1;
    my $last_job;
    foreach my $audio ( sort { $a->tc_target_track <=> $b->tc_target_track }
                             @{$title->audio_tracks} ) {
        #-- skip deactivated tracks
        next if $audio->tc_target_track == -1;

        #-- all or skip first?
        if ( $mode eq 'skip1' && $first ) {
            $first = 0;
            next;
        }
        $first = 0;

        my $vob_nr = $audio->tc_nr;
        my $avi_nr = $audio->tc_target_track;

        my $job = $self->build_merge_audio_job($title, $vob_nr, $avi_nr);
        $job->set_depends_on([$last_job]) if $last_job;

        $job->set_stash ({
            prefer_local_access => 1,
            psu                 => $psu->nr,
            chunk_cnt           => $psu->chunk_cnt,
            vob_nr              => $vob_nr,
            avi_nr              => $avi_nr,
        });

        push @merge_audio_jobs, $job;
        $last_job = $job;
    }

    return unless @merge_audio_jobs;

    return Event::ExecFlow::Job::Group->new (
        title    => __x("Merge all audio tracks - title #{nr}, PSU #{psu}",
                        nr => $title->nr, psu => $psu->nr ),
        jobs     => \@merge_audio_jobs,
        parallel => 1,
    );
}

sub build_cluster_video_chunk_jobs {
    my $self = shift;
    my ($title, $psu) = @_;
    
    my @all_video_chunk_jobs;

    my $chunk_cnt = $psu->chunk_cnt;
    my $multipass = $title->tc_multipass;
    
    my ($job, $last_job);
    
    for ( my $i = 0; $i < $chunk_cnt; ++$i ) {
        if ( $multipass ) {
            #-- First pass
            my $pass1_job = $self->build_transcode_video_pass_job($title, 1, undef, $i+1, $psu->nr);
            $pass1_job->set_progress_max($psu->frames);
            $pass1_job->set_stash({
                chunk       => $i,
                chunk_cnt   => $psu->chunk_cnt,
                psu         => $psu->nr,
            });
            
            #-- Second pass
            my $pass2_job = $self->build_transcode_video_pass_job($title, 2, undef, $i+1, $psu->nr);
            $pass2_job->set_progress_max($psu->frames);
            $pass2_job->set_stash({
                chunk       => $i,
                chunk_cnt   => $psu->chunk_cnt,
                psu         => $psu->nr,
            });
            $pass2_job->set_depends_on([$pass1_job]);
            
            #-- Build group for both passes
            push @all_video_chunk_jobs, Event::ExecFlow::Job::Group->new (
                title    => __x("Multipass video transcoding - title #{nr}, PSU #{psu}, ".
                                "chunk #{chunk}",
                                nr => $title->nr, psu => $psu->nr, chunk => $i+1),
                jobs     => [ $pass1_job, $pass2_job ],
                parallel => 1,
            );
        }
        else {
            #-- Single pass transcoding
            my $tc_video_job = $self->build_transcode_video_pass_job($title, 0, undef, $i+1, $psu->nr);
            $tc_video_job->set_progress_max($psu->frames);
            $tc_video_job->set_stash({
                chunk       => $i,
                chunk_cnt   => $psu->chunk_cnt,
                psu         => $psu->nr,
            });
            push @all_video_chunk_jobs, $tc_video_job;
        }
    }        
    
    return Event::ExecFlow::Job::Group->new (
        title    => __x("Process all video chunks - title #{nr}, PSU #{psu}",
                        nr => $title->nr, psu => $psu->nr ),
        jobs     => \@all_video_chunk_jobs,
        parallel => 1,
    );
}

sub build_cluster_merge_video_chunks_job {
    my $self = shift;
    my ($title, $psu) = @_;
    
    my $info = __x("Merge video chunks - title #{nr}, PSU #{psu}",
                   nr => $title->nr, psu => $psu->nr);

    my $command = sub {
        $title->get_merge_video_audio_command;
    };

    my $progress_parser = sub {
        my ($job, $buffer) = @_;
	if ( $buffer =~ /\(\d+-(\d+)\)/ ) {
	    # avimerge
	    $job->set_progress_cnt ($1);
	} elsif ( $buffer =~ /(\d+)/ ) {
	    # ogmmerge
	    $job->set_progress_cnt ($1);
	}
    };

    return Event::ExecFlow::Job::Command->new (
        title               => $info,
        command             => $command,
        diskspace_consumed  => 0, # $diskspace_consumed,
        progress_ips        => __"fps",
        progress_max        => $psu->frames,
        progress_parser     => $progress_parser,
        stash               => {
            prefer_local_access => 1,
            psu                 => $psu->nr,
        },
    );
}

sub build_cluster_merge_psu_files_job {
    my $self = shift;
    my ($title) = @_;

    my $info = __x("Merge all PSU files - title #{nr}",
                   nr => $title->nr);

    my $command = sub {
        $title->get_merge_psu_command;
    };

    my $progress_parser = sub {
        my ($job, $buffer) = @_;
	if ( $buffer =~ /\(\d+-(\d+)\)/ ) {
	    # avimerge
	    $job->set_progress_cnt ($1);
	} elsif ( $buffer =~ /(\d+)/ ) {
	    # ogmmerge
	    $job->set_progress_cnt ($1);
	}
    };

    return Event::ExecFlow::Job::Command->new (
        title               => $info,
        command             => $command,
        diskspace_consumed  => 0, # $diskspace_consumed,
        progress_ips        => __"fps",
        progress_max        => $title->frames,
        progress_parser     => $progress_parser,
        stash               => {
            prefer_local_access => 1,
        },
    );
}

1;
