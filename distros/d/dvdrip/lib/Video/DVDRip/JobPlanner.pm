# $Id: JobPlanner.pm 2391 2009-12-19 13:34:55Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::JobPlanner;

use base qw(Video::DVDRip::Base);

use Carp;
use strict;

use Locale::TextDomain qw (video.dvdrip);
use Event::ExecFlow 0.63 qw (video.dvdrip);


sub get_project                 { shift->{project}                      }
sub set_project                 { shift->{project}              = $_[1] }

sub new {
    my $class = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    my $self = $class->SUPER::new(@_);

    $self->set_project($project);
    
    return $self;
}

sub get_title_info {
    my $self = shift;
    my ($title) = @_;
    
    my $info = "";
    my $chapter = $title->real_actual_chapter;
    
    $info .= " - ".__x("title #{title}", title => $title->nr);
    $info .= ", ".__x("chapter #{chapter}", chapter => $chapter )
        if $chapter;
    
    return $info;
}

sub build_read_toc_job {
    my $self = shift;
    
    my $job;
    if ( $self->has("lsdvd") ) {
        my $lsdvd_job   = $self->build_read_toc_lsdvd_job;
        my $tcprobe_job = $self->build_read_toc_tcprobe_job;
        $job = Event::ExecFlow::Job::Group->new (
            title => __x("Read TOC ({method})", method => "lsdvd|tcprobe"),
            jobs  => [ $lsdvd_job, $tcprobe_job ],
        );
        $tcprobe_job->get_pre_callbacks->prepend(sub{
            if ( ! $lsdvd_job->get_stash->{try_tcprobe} ) {
                $tcprobe_job->set_skipped(1);
            }
        });
    }
    else {
        $job = $self->build_read_toc_tcprobe_job;
    }
    
    $job->get_post_callbacks->add (sub {
        my ($job) = @_;
        return if ! $job->finished_ok;
        $self->log (__"Successfully read DVD TOC");
        eval { $self->get_project->copy_ifo_files };
        $job->set_error_message(
	    __"Failed to copy the IFO files. vobsub creation ".
              "won't work properly.\n(Did you specify the mount ".
              "point of your DVD drive in the Preferences?)\n".
              "The error message is:\n".
              $self->stripped_exception
        ) if $@;
        1;
    });
    
    return $job;
}

sub build_read_toc_lsdvd_job {
    my $self = shift;

    my $command = $self->get_project
                       ->content
                       ->get_read_toc_lsdvd_command;
    
    return Event::ExecFlow::Job::Command->new (
        name            => "read_toc_lsdvd",
        title           => __x("Read TOC ({method})", method => "lsdvd"),
        command         => $command,
        fetch_output    => 1,
        post_callbacks  => sub {
            my ($job) = @_;
            if ( ! $job->finished_ok ) {
                $job->set_error_message(
                    __("Error reading table of contents. Please check ".
                       "your DVD device settings in the Preferences ".
                       "and don't forget to put a DVD in the drive.")
                );
                return;
            }
            eval {
	        Video::DVDRip::Probe->analyze_lsdvd (
                    probe_output    => $job->get_output,
                    project         => $self->get_project,
	        );
            };
            if ( $@ ) {
                #-- lsdvd produced illegal output (with lsdvd 0.16
                #-- this happens for some DVDs)
                $job->add_stash({ try_tcprobe => 1 });
                $self->log(__"Warning: lsdvd failed reading TOC, trying tcprobe.");
            }
        },
    );
}

sub build_read_toc_tcprobe_job {
    my $self = shift;
    
    my $cnt_command = $self->get_project->content->get_probe_title_cnt_command;

    return Event::ExecFlow::Job::Group->new (
        name    => "read_toc_tcprobe",
        title   => __x("Read TOC ({method})", method => "tcprobe"),
        jobs    => [
            Event::ExecFlow::Job::Command->new (
                title           => __"Determine number of titles",
                fetch_output    => 1,
                no_progress     => 1,
                command         => $cnt_command,
                post_callbacks  => sub {
                    my ($job) = @_;
                    return if !$job->finished_ok;
                    my $output = $job->get_output;
                    my ($title_cnt) = $output =~ m!DVD\s+title\s+\d+/(\d+)!;
                    if ( !$title_cnt ) {
                        $job->set_error_message(
                            __("Error reading table of contents. Please check ".
                               "your DVD device settings in the Preferences ".
                               "and don't forget to put a DVD in the drive.")
                        );
                        return;
                    }
                    $self->get_project->content->set_titles ({});
                    my $add_job = $self->build_probe_all_titles_job($title_cnt);
                    $job->get_group->add_job($add_job);
                    1;
                },
            ),
        ],
    );
}

sub build_probe_all_titles_job {
    my $self = shift;
    my ($title_cnt) = @_;
    
    my $titles_href = $self->get_project->content->titles;
    my $project     = $self->get_project;

    my @jobs;
    foreach my $nr ( 1..$title_cnt ) {
        push @jobs, Event::ExecFlow::Job::Command->new (
            name            => "probe_title_$nr",
            title           => __x("Probe - title #{title}",
                                   title => $nr),
            command         => undef, # set in pre_callbacks
            fetch_output    => 1,
            no_progress     => 1,
            stash           => { hide_progress => 1 },
            pre_callbacks   => sub {
                my ($job) = @_;
                my $title = Video::DVDRip::Title->new (
		        nr      => $nr,
		        project => $project,
	        );
                $job->set_command($title->get_probe_command);
                $titles_href->{$nr} = $title;
            },
            post_callbacks  => sub {
                my ($job) = @_;
                if ( !$job->finished_ok ) {
                    delete $titles_href->{$nr};
                    return;
                }
                my $title = $titles_href->{$nr};
                $title->analyze_probe_output (
                    output => $job->get_output,
                );
                $title->suggest_transcode_options;
                $self->log ("Successfully probed title #".$title->nr);
                $job->frontend_signal("title_probed", $title);
                1;
            },
        );
    }

    return Event::ExecFlow::Job::Group->new (
        name            => "probe_all_titles_group",
        title           => __"Probe all DVD titles",
        stash           => { show_progress => 1 },
        jobs            => \@jobs,
        progress_max    => $title_cnt,
    );
}

sub build_rip_job {
    my $self = shift;
    
    my $content            = $self->get_project->content;
    my $selected_title_idx = $content->selected_titles;

    my @jobs;
    foreach my $title_idx ( @{$selected_title_idx} ) {
        my @title_jobs;
        my $title = $content->titles->{ $title_idx + 1 };
        if ( ! $title->tc_use_chapter_mode ) {
            push @title_jobs, (
                $self->build_rip_title_job($title),
#                @{$self->build_grab_preview_frame_job($title, 1)->get_jobs},
                $self->build_grab_preview_frame_job($title, 1),
            );
        }
        else {
            my @chapter_jobs;
            push @title_jobs, Event::ExecFlow::Job::Group->new (
                title   => __x("Rip chapters of title #{nr}",
                               nr => $title->nr ),
                jobs    => \@chapter_jobs,
            );

            foreach my $chapter ( @{ $title->get_chapters } ) {
                push @chapter_jobs, $self->build_rip_chapter_job($title, $chapter);
            }
#            push @title_jobs, @{$self->build_grab_preview_frame_job($title, 1)->get_jobs};
            push @title_jobs, $self->build_grab_preview_frame_job($title, 1);
        }

        push @jobs, Event::ExecFlow::Job::Group->new (
            title   => __x("Process title #{nr}", nr => $title->nr),
            jobs    => \@title_jobs,
        );
    }

    my $rip_job = Event::ExecFlow::Job::Group->new (
        name                => "rip_and_preview",
        title               => __"Rip selected title(s) / chapter(s)",
        jobs                => \@jobs,
        stop_on_failure     => 0,
        post_callbacks      => sub { $self->get_project->backup_copy },
    );

    return $rip_job;
}

sub build_rip_title_job {
    my $self = shift;
    my ($title) = @_;
    return $self->build_rip_chapter_job($title, undef);
}

sub build_rip_chapter_job {
    my $self = shift;
    my ($title, $chapter) = @_;
    
    my $info = __"Rip";
    $info .= " - ".__x("title #{title}", title => $title->nr);
    $info .= ", ".__x("chapter {chapter}", chapter => $chapter )
        if $chapter;

    $title->set_actual_chapter($chapter);
    my $command = $title->get_rip_and_scan_command;
    $title->set_actual_chapter(undef);
    
    my $progress_max;
    if ( ! $chapter || $title->tc_use_chapter_mode eq 'all' ) {
	$progress_max = $title->frames;
    }
    elsif ( $chapter && $title->chapter_frames->{$chapter} ) {
        $progress_max = $title->chapter_frames->{$chapter};
    }

    my $name = "rip_to_harddisk_".$title->nr.($chapter?"_".$chapter:'');

    my $diskspace_consumed = 6*1024*1024;
    $diskspace_consumed = int($diskspace_consumed/$title->chapters);

    my $progress_start = 0;

    return Event::ExecFlow::Job::Command->new (
        name               => $name,
        title              => $info,
        command            => $command,
        diskspace_consumed => $diskspace_consumed,
        fetch_output       => 1,
        progress_max       => $progress_max,
        progress_ips       => __"fps",
        progress_parser    => sub {
            my ($self, $buffer) = @_;
            if ( $buffer =~ /--splitpipe-started--/ ) {
                $progress_start = 1;
                return 1;
            }
            return 1 unless $progress_start;
            if ( $buffer =~ /^(.*)--splitpipe-finished--/s ) {
                $buffer = $1;
                $progress_start = 0;
            }
	    my $frames = $self->get_progress_cnt;
            $frames += $buffer =~ tr/\n/\n/;
	    $self->set_progress_cnt ($frames);
            1;
        },
        post_callbacks  => sub {
            my ($job) = @_;
            if ( $job->get_cancelled ) {
                $title->remove_vob_files;
            }
            elsif ( !$job->get_error_message ) {
                $self->analyze_rip($job, $title, $chapter);
            }
        },
    );
}

sub analyze_rip {
    my $self = shift;
    my ($job, $title, $chapter) = @_;
    
    my $count = 0;
    $count = 1 if $chapter &&
		  $chapter != $title->get_first_chapter;

    $title->analyze_scan_output (
	output => $job->get_output,
	count  => $count,
    );

    my $audio_tracks = $title->audio_tracks;

    $_->set_tc_target_track(-1) for @{$audio_tracks};
    $title->audio_track->set_tc_target_track(0);

    if ( $chapter ) {
        $title->set_actual_chapter($chapter);
        $title->set_chapter_length ($chapter);
        if ( $title->chapter_frames->{$chapter} < 10 ) {
	        $job->set_warning_message (
                    __x("Chapter {nr} is too small and useless. ".
                        "You should deselect it.",
                        nr => $chapter)
	        );
	        $title->set_actual_chapter(undef);
        }
        elsif ( $chapter == $title->get_last_chapter ) {
	        $title->probe_audio;
	        $title->calc_program_stream_units;
	        $title->suggest_transcode_options;
        }
        $title->set_actual_chapter(undef);
    }
    else {
        #-- remember TOC fps
        my $title_fps = $title->frame_rate;
        #-- probe audio (and fps) from ripped data
	$title->probe_audio;
        #-- this is the real framerate
        my $disc_fps  =  $title->frame_rate;

        #-- get frame cnt from disc and from TOC
	my $disc_frames  = $job->get_progress_cnt;
	my $title_frames = $title->frames; 

        #-- check whether fps differ
        if ( $title_fps != $disc_fps ) {
            #-- adjust $title_frames to prevent wrong
            #-- "ripping short" warning
            $title_frames = $disc_fps * $title->runtime;
            $self->log(
                __x("DVD TOC reported wrong framerate {toc_fps}, ".
                    "adjusted frame rate to {disc_fps} and frame count to {disc_count}",
                    toc_fps    => $title_fps,
                    disc_fps   => $disc_fps,
                    disc_count => $disc_frames )
            );
        }

	$title->set_frames($disc_frames);
	$title->calc_program_stream_units;
	$title->suggest_transcode_options("update");

        $job->frontend_signal("toc_info_changed");

	if ( $disc_frames / $title_frames < 0.99 ) {

        my $message = 
                    __x("It seems that transcode ripping stopped short.\n".
			"The movie has {title_frames} frames, but only {disc_frames}\n".
			"were ripped. This is most likely a problem with your\n".
			"transcode/libdvdread installation, resp. a problem with\n".
			"this specific DVD.",
                        title_frames => $title_frames,
                        disc_frames  => $disc_frames);
            
  		$job->set_warning_message ($message);
	}
    }

    1;
}

sub build_detect_audio_bitrate_job {
    my $self = shift;
    my ($title, $codec) = @_;
    
    return Event::ExecFlow::Job::Command->new (
        title           => __x("Detect audio bitrate of title #{nr}",
                               nr => $title->nr),
        command         => $title->get_detect_audio_bitrate_command,
        fetch_output    => 1,
        progress_max    => 10000,
        progress_parser => sub {
            my ($job, $buffer) = @_;
            if ( $buffer =~ m!dvdrip-progress:\s*(\d+)/(\d+)! ) {
    	        $job->set_progress_cnt (10000*$1/$2);
            }
        },
        post_callbacks  => sub {
            my ($job) = @_;
            return if !$job->finished_ok;
            $title->analyze_probe_audio_output(output => $job->get_output);
            $title->calc_video_bitrate;
            $job->frontend_signal("audio_bitrate_changed", $title, $codec);
            1;
        },
    );
}

sub build_grab_preview_frame_job {
    my $self = shift;
    my ($title, $apply_preset) = @_;

    my $info = __ "Grab preview";
    $info .= $self->get_title_info($title);

    my $progress_max;
    my $progress_ips;
    my $slow_mode;

    if ( ( $title->project->rip_mode ne 'rip' ||
           !$title->has_vob_nav_file ||
            $title->tc_force_slow_grabbing )
          and not $self->has("ffmpeg") ) {
        $progress_ips = __"fps";
        $progress_max = $title->preview_frame_nr;
        $slow_mode    = 1;
    }

    my $name = "grab_preview_".$title->nr;

    my $got_frame_with_ffmpeg;
    my $grab_preview_job = Event::ExecFlow::Job::Command->new (
        name            => $name,
        title           => $info,
        command         => undef,       # pre callback, rip in chapter mode, frames not known yet
        no_progress     => (!$slow_mode),
        progress_max    => $progress_max,
        progress_ips    => $progress_ips,
        progress_parser => sub {
            my ($job, $buffer) = @_;
            if ( $slow_mode ) {
                if ( $self->version("transcode") >= 10100 ) {
                    $job->set_progress_cnt($1)
                        if $buffer =~ /frame=(\d+)/;
                }
                else {
                    $job->set_progress_cnt($1)
                        if $buffer =~ /\[\d+-(\d+)\]/;
                }
            }
            if ( $buffer =~ /encoded\s+(\d+)\s+frame/ ) {
                if ( $1 != 1 ) {
                    $job->set_error_message (
                        __ ("transcode can't find this frame. ").
                        __ ("Try a lower frame number. ").
                        ($slow_mode ? "" :
                         __"Try forcing slow frame grabbing.")
                    );
                }
            }
            if ( $self->has("ffmpeg") and $buffer =~ /frame=\s*1.*?q\s*=/ ) {
                $got_frame_with_ffmpeg = 1;
            }
        },
        pre_callbacks   => sub {
            my ($job) = @_;
            if ( !$title->is_ripped ) {
                $job->set_error_message(
                    __"You first have to rip this title."
                );
            }
            $job->set_command($title->get_take_snapshot_command);
        },
        post_callbacks => sub {
            my ($job) = @_;
            if ( $self->has("ffmpeg") and not $got_frame_with_ffmpeg ) {
                $job->set_error_message (
                    __ ("transcode can't find this frame. ").
                    __ ("Try a lower frame number. ").
                    ($slow_mode ? "" :
                     __"Try forcing slow frame grabbing.")
                );
            }
        },
    );
    
    my @jobs;
    if ( $apply_preset ) {
        my $apply_preset_job = $self->build_apply_preset_job($title, $apply_preset);
#        @jobs = ( $grab_preview_job, @{$apply_preset_job->get_jobs} );
        @jobs = ( $grab_preview_job, $apply_preset_job );
    }
    else {
        my $make_previews_job = $self->build_make_previews_job($title, $apply_preset);
        @jobs = ( $grab_preview_job, $make_previews_job );
    }
    
    return Event::ExecFlow::Job::Group->new (
        title   => __("Process preview frame").$self->get_title_info($title),
        jobs    => \@jobs,
    );
}

sub build_make_previews_job {
    my $self = shift;
    my ($title) = @_;

    return Event::ExecFlow::Job::Command->new (
        title               => __("Generate preview thumbnails").$self->get_title_info($title),
        command             => undef,   # pre_callback, clip&zoom values changes in build_apply_preset_job()
        progress_max        => 3,
        progress_parser     => sub {
            my ($job, $buffer) = @_;
            if ( $buffer =~ /\n/ ) {
                $job->set_progress_cnt(1+$job->get_progress_cnt);
            }
        },
        pre_callbacks       => sub {
            my ($job) = @_;
            $job->set_command($title->get_make_previews_command);
        },
    );
}

sub build_apply_preset_job {
    my $self = shift;
    my ($title) = @_;

    my $preset = $self->config_object->get_preset( name => $title->preset );

    return Event::ExecFlow::Job::Group->new (
        title   => __("Apply preset & make previews").$self->get_title_info($title),
        jobs    => [
            Event::ExecFlow::Job::Code->new (
                title => __("Apply Clip & Zoom preset").$self->get_title_info($title),
                code  => sub {
                    my ($job) = @_;
                    $title->calc_snapshot_bounding_box;
                    $title->apply_preset;
                },
            ),
            $self->build_make_previews_job($title),
        ],
    );
}

#=====================================================================
# transcode stuff
#=====================================================================

sub check_transcode_settings {
    my $self = shift;
    my ($job, $title) = @_;

    my $split    = $title->tc_split;
    my $chapters = $title->get_chapters;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    if ( not $title->is_ripped ) {
        $job->set_error_message(
            __ "You first have to rip this title."
        );
        return 0;
    }

    if ( $title->tc_psu_core
         && ( $title->tc_start_frame || $title->tc_end_frame ) ) {
        $job->set_error_message(
            __"You can't select a frame range with psu core."
        );
        return 0;
    }

    if (    $title->tc_psu_core
         && $title->project->rip_mode ne 'rip' ) {
        $job->set_error_message (
            __"PSU core only available for ripped DVD's."
        );
        return 0;
    }

    if ( $title->tc_use_chapter_mode && ! @{$chapters} ) {
        $job->set_error_message(__ "No chapters selected.");
        return 0;
    }

    if ( $title->tc_use_chapter_mode && $split ) {
        $job->set_error_message(
            __"Splitting AVI files in\nchapter mode makes no sense."
        );
        return 0;
    }

    if ( $title->get_first_audio_track == -1 ) {
        $job->emit_warning_message (
            __"WARNING: no target audio track #0"
        );
    }

    if ( keys %{ $title->get_additional_audio_tracks } ) {
        if ( $title->tc_video_codec =~ /^X?VCD$/ ) {
            $job->set_error_message (
                __ "Having more than one audio track "
                 . "isn't possible on a (X)VCD."
            );
            return 0;
        }
        if ( $title->tc_video_codec =~ /^(X?SVCD|CVD)$/
             && keys %{ $title->get_additional_audio_tracks } > 1 ) {
            $job->emit_warning_message (
                __ "WARNING: Having more than two audio tracks\n"
                 . "on a (X)SVCD/CVD is not standard conform. You may\n"
                 . "encounter problems on hardware players."
            );
        }
    }

    my $svcd_warning;
    if ( $svcd_warning = $title->check_svcd_geometry ) {
        $job->emit_warning_message (
            $svcd_warning."\n"
          . __ "You better cancel now and select the appropriate\n"
             . "preset on the Clip &amp; Zoom page."
        );
    }

    return 1;
}

sub build_transcode_job {
    my $self = shift;
    my ($subtitle_test) = @_;

    my $content            = $self->get_project->content;
    my $selected_title_idx = $content->selected_titles;

    my @title_jobs;
    foreach my $title_idx ( @{$selected_title_idx} ) {
        my $title = $content->titles->{ $title_idx + 1 };
        $title->set_actual_chapter(undef);
        $title->set_subtitle_test($subtitle_test);

        my $job;
        if ( ! $subtitle_test &&
               $title->has_vbr_audio && $title->tc_multipass &&
             ! $title->multipass_log_is_reused ) {
            $job = $self->build_transcode_multipass_with_vbr_audio_job($title);
        }
        else {
            $job = $self->build_transcode_no_vbr_audio_job($title);
        }

        $job->get_pre_callbacks->add(sub {
            my ($job) = @_;
            $self->check_transcode_settings($job, $title);
            1;
        });

        if ( !$subtitle_test ) {
            $job->get_post_callbacks->add(sub {
                my ($job) = @_;
                return if !$job->finished_ok;
                require Video::DVDRip::InfoFile;
                Video::DVDRip::InfoFile->new (
    	                title    => $title,
	                filename => $title->info_file,
                )->write;
                if ( $title->tc_execute_afterwards =~ /\S/ ) {
                    system( "(" . $title->tc_execute_afterwards . ") &" );
                }
                if ( $title->tc_exit_afterwards ) {
                    $title->project->save
                        if $title->tc_exit_afterwards ne 'dont_save';
                    $job->frontend_signal("program_exit");
                }
                1;
            });
        }

        $title->set_subtitle_test(undef);
        
        push @title_jobs, $job;
    }

    return $title_jobs[0] if @title_jobs == 1;
    return Event::ExecFlow::Job::Group->new (
        title               => __"Transcode multiple titles",
        jobs                => \@title_jobs,
        parallel            => 0,
        stop_on_failure     => 0,
    );
}

sub build_transcode_no_vbr_audio_job {
    my $self = shift;
    my ($title) = @_;

    my $mpeg          = $title->is_mpeg;
    my $split         = $title->tc_split;
    my $chapters      = $title->get_chapters;
    my $subtitle_test = $title->subtitle_test;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    my @jobs;
    foreach my $chapter ( @{$chapters} ) {
        my @chapter_jobs;

        $title->set_actual_chapter($chapter);

        my ($transcode_video_job, $merge_audio_job,
            $transcode_more_audio_tracks_job,
            $mplex_job, $split_job, $vobsub_job);

        push @chapter_jobs, $transcode_video_job =
            $self->build_transcode_video_job($title);

        push @chapter_jobs, $merge_audio_job =
            $self->build_merge_audio_job($title)
                if $title->tc_container eq 'ogg' &&
                   $title->get_first_audio_track != -1;

        push @chapter_jobs, $transcode_more_audio_tracks_job =
            $self->build_transcode_more_audio_tracks_job($title)
                if !$subtitle_test &&
                   keys %{$title->get_additional_audio_tracks};

        push @chapter_jobs, $mplex_job = 
            $self->build_mplex_job($title)
                if $mpeg;

        push @chapter_jobs, $split_job =
            $self->build_split_job($title)
                if !$subtitle_test && $split && !$mpeg;

        push @chapter_jobs, $vobsub_job =
            $self->build_vobsub_job($title)
                if $title->has_vobsub_subtitles;

        $merge_audio_job->set_depends_on([$transcode_video_job->get_name])
            if $merge_audio_job;

        if ( $mplex_job && $transcode_more_audio_tracks_job ) {
            $mplex_job->set_depends_on([
                $transcode_video_job->get_name,
                $transcode_more_audio_tracks_job->get_name,
            ]);
        }
        elsif ( $mplex_job ) {
            $mplex_job->set_depends_on([$transcode_video_job->get_name]);
        }


        if ( @chapter_jobs > 1 ) {
            push @jobs, Event::ExecFlow::Job::Group->new (
                title       => __("Transcode").$self->get_title_info($title),
                jobs        => \@chapter_jobs,
                parallel    => 0,
            );
        }
        else {
            push @jobs, $chapter_jobs[0],
        }

        $title->set_actual_chapter(undef);
    }

    if ( @jobs > 1 ) {
        return Event::ExecFlow::Job::Group->new (
            title       => __("Transcode chapters").$self->get_title_info($title),
            jobs        => \@jobs,
            parallel    => 0,
        );
    }
    else {
        return $jobs[0];
    }
}

sub build_transcode_multipass_with_vbr_audio_job {
    my $self = shift;
    my ($title) = @_;
    
    my @jobs;

    my $mpeg             = $title->is_mpeg;
    my $split            = $title->tc_split;
    my $chapters         = $title->get_chapters;
    my $subtitle_test    = $title->subtitle_test;
    my $add_audio_tracks = $title->get_additional_audio_tracks;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    my $bc = Video::DVDRip::BitrateCalc->new(
        title       => $title,
        with_sheet  => 0,
    );

    # 1. encode additional audio tracks and video per chapter
    my @first_pass_jobs;
    foreach my $chapter ( @{$chapters} ) {
        $title->set_actual_chapter($chapter);
        push @first_pass_jobs,
            $self->build_transcode_more_audio_tracks_job($title, $bc)
                if keys %{$title->get_additional_audio_tracks};
        push @first_pass_jobs,
            $self->build_transcode_video_pass_job($title, 1);
        $title->set_actual_chapter(undef);
    }

    # 2. calculate video bitrate
    my $bc_job =
        $self->build_calc_video_bitrate_job ($title, $bc);
    
    my $first_pass_group;
    push @jobs, $first_pass_group = Event::ExecFlow::Job::Group->new (
        title       => __("Transcode with VBR audio, first pass").$self->get_title_info($title),
        jobs        => \@first_pass_jobs,
        parallel    => 0,
    );
    
    $bc_job->set_depends_on([$first_pass_group]);

    push @jobs, $bc_job;

    # 3. 2nd pass Video and merging
    my @second_pass_jobs;
    foreach my $chapter ( @{$chapters} ) {
        $title->set_actual_chapter($chapter);

        my $transcode_video_job;
        push @second_pass_jobs, $transcode_video_job =
            $self->build_transcode_video_pass_job($title, 2);

        if ( $title->get_first_audio_track != -1 ) {
            my $merge_audio_job;
            push @second_pass_jobs, $merge_audio_job =
                $self->build_merge_audio_job($title);
            $merge_audio_job->set_depends_on([$transcode_video_job->get_name]);
        }

        foreach my $avi_nr ( sort { $a <=> $b } keys %{$add_audio_tracks} ) {
            my $vob_nr = $add_audio_tracks->{$avi_nr};
            my $merge_audio_job;
            push @second_pass_jobs, $merge_audio_job = $self->build_merge_audio_job(
                $title, $vob_nr, $avi_nr,
            );
        }

        $title->set_actual_chapter(undef);
    }

    my $second_pass_group;
    push @jobs, $second_pass_group = Event::ExecFlow::Job::Group->new (
        title      => __("Transcode with VBR audio, second pass").$self->get_title_info($title),
        depends_on => [ $first_pass_group->get_name ],
        jobs       => \@second_pass_jobs,
        parallel    => 0,  # 0
    );
    
    # 4. optional splitting (non chapter mode only)
    if ( $split ) {
        my $split_job;
        push @jobs, $split_job = $self->build_split_job($title);
        $split_job->set_depends_on([$second_pass_group->get_name ]);
    }

    # 5. vobsub
    if ( $title->has_vobsub_subtitles ) {
        push @jobs,
            $self->build_vobsub_job($title);
        $jobs[-1]->set_depends_on([$jobs[-2]->get_name]);
    }

    return Event::ExecFlow::Job::Group->new (
        title       => __("Transcode with VBR audio").$self->get_title_info($title),
        jobs        => \@jobs,
        parallel    => 0,
    );
}

sub build_calc_video_bitrate_job {
    my $self = shift;
    my ($title, $bc) = @_;

    return Event::ExecFlow::Job::Code->new (
        title      => __("Calculate video bitrate ").
                      $self->get_title_info($title),
        code       => sub {
            my ($job) = @_;
            $bc->calculate;
            $title->set_tc_video_bitrate($bc->video_bitrate);
            $job->frontend_signal("video_bitrate_changed", $title);
            $self->log(
                __x("Adjusted video bitrate to {video_bitrate} "
                        . "after vbr audio transcoding",
                    video_bitrate => $bc->video_bitrate
                )
            );
        },  
    );
}

sub build_transcode_video_job {
    my $self = shift;
    my ($title) = @_;

    if ( $title->tc_multipass ) {
        if ( $title->multipass_log_is_reused ) {
            return $self->build_transcode_video_pass_job(
                $title, 2
            );
        }
        else {
            return Event::ExecFlow::Job::Group->new (
                title   => __("Transcode multipass").$self->get_title_info($title),
                jobs    => [
                    $self->build_transcode_video_pass_job(
                        $title, 1
                    ),
                    $self->build_transcode_video_pass_job(
                        $title, 2
                    ),
                ],
                parallel => 0, # 0
            );
        }
    }
    else {
        return $self->build_transcode_video_pass_job($title);
    }
}

sub build_transcode_video_pass_job {
    my $self = shift;
    my ($title, $pass, $bc, $chunk, $psu) = @_;
    
    my $subtitle_test = $title->subtitle_test;
    my $chapter       = $title->actual_chapter;

    my $info = __"Transcode video";
    $info .= $self->get_title_info($title);

    if ( defined $psu ) {
        $info .= ", ".__x("PSU {psu}", psu => $psu);
    }

    if ( $chunk ) {
        $info .= ", ".__x("chunk {chunk}", chunk => $chunk);
    }

    if ( $pass ) {
        $info .= ", ".__x("pass {pass}", pass => $pass);
    }
    else {
        $info .= ", ".__"single pass";
    }
    
    my $chapter = $title->actual_chapter;

    my $command = sub {
        $title->set_actual_chapter($chapter);
        $subtitle_test ?
            $title->get_subtitle_test_transcode_command :
            $title->get_transcode_command (
                pass    => $pass,
                split   => $title->tc_split,
            );
# return "echo 'FEHLER' && /bin/false";
    };
        
    my $diskspace_consumed = 0;
    if ( $pass != 1 ) {
	my $bc = Video::DVDRip::BitrateCalc->new (
		title		=> $title,
		with_sheet	=> 0,
	);
	$bc->calculate;
        $diskspace_consumed = int(($bc->video_size + $bc->non_video_size)*1024);
    }

    if ( $pass == 1 &&
         $title->has_vbr_audio && $title->tc_multipass ) {
	my $bc = Video::DVDRip::BitrateCalc->new (
		title		=> $title,
		with_sheet	=> 0,
	);
	$bc->calculate;
        $diskspace_consumed += $bc->audio_size * 1024;
    }
                 
    my $progress_parser = $self->get_transcode_progress_parser($title);
    
    my $post_callbacks;
    if ( $bc ) {
        $post_callbacks = sub {
	    my $nr = $title->get_first_audio_track;
	    return 1 if $nr == -1;
	    my $vob_nr = $title->audio_tracks->[$nr]->tc_nr;
	    my $avi_nr = $title->audio_tracks->[$nr]->tc_target_track;
	    my $audio_file = $title->target_avi_audio_file (
		vob_nr => $vob_nr,
		avi_nr => $avi_nr,
	    );
	    $self->bc->add_audio_size ( bytes => -s $audio_file );
            1;
        };
    }
    
    my $progress_max = $title->get_transcode_progress_max;

    return Event::ExecFlow::Job::Command->new (
        title               => $info,
        command             => $command,
        diskspace_consumed  => $diskspace_consumed,
        progress_ips        => __"fps",
        progress_max        => $progress_max,
        progress_parser     => $progress_parser,
        post_callbacks      => $post_callbacks,
    );
}

sub get_transcode_progress_parser {
    my $self = shift;
    my ($title) = @_;
    
    if ( $self->version("transcode") >= 10100 ) {
        return sub {
            my ($job, $buffer) = @_;
            if ( $buffer =~ /frame=(\d+)/ ) {
                my $frame = $1;
                $job->set_progress_cnt($frame);
                if ( $buffer =~ /first=(\d+)/ ) {
                    $job->set_progress_cnt($frame-$1);
                }
            }
            if ( $buffer =~ /last=(\d+)/ ) {
                $job->set_progress_max($1);
            }
            1;
        };
    }
    
    my $psu_frames;
    return sub {
        my ($job, $buffer) = @_;
	if ( ! $title->tc_psu_core && 
	       $buffer =~ /split.*?mapped.*?-c\s+\d+-(\d+)/ ) {
		$job->set_progress_max($1);
		$job->set_progress_start_time(time);
	}

	#-- new PSU: store actual frame count, because
	#-- frame numbers start at 0 for each PSU
	if ( $title->tc_psu_core &&
	     $buffer =~ /reading\s+auto-split/ ) {
            $psu_frames = $job->get_progress_cnt;
	}

	if ( $buffer =~ /encoding.*?(\d+)\]/i ) {
            $job->set_progress_cnt($psu_frames + $1);
	}
    };
}

sub build_merge_audio_job {
    my $self = shift;
    my ($title, $vob_nr, $avi_nr) = @_;
    
    $vob_nr = $title->get_first_audio_track if ! defined $vob_nr;
    $avi_nr = 0                             if ! defined $avi_nr;

    return () if $vob_nr == -1;

    my $chapter = $title->actual_chapter;

    my $info = __"Merge audio";
    $info .= $self->get_title_info($title);
    $info .= ", ".__x("audio track #{nr}", nr => $vob_nr);

    my $progress_max = $title->get_transcode_progress_max;

    my ($diskspace_consumed, $diskspace_freed);
    my $bc = Video::DVDRip::BitrateCalc->new (
	    title       => $title,
	    with_sheet	=> 0,
    );
    $bc->calculate;
    my $bitrate = $title->audio_tracks->[$vob_nr]->tc_bitrate;
    my $runtime = $title->runtime;
    my $audio_size = int($runtime * $bitrate / 8);
    $diskspace_consumed = $audio_size + $bc->video_size * 1024;
    $diskspace_freed    = $audio_size;

    my $command = sub {
        $title->get_merge_audio_command (
	    vob_nr        => $vob_nr,
	    target_nr     => $avi_nr,
        );
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
        diskspace_consumed  => $diskspace_consumed,
        diskspace_freed     => $diskspace_freed,
        progress_ips        => __"fps",
        progress_max        => $progress_max,
        progress_parser     => $progress_parser,
    );
}

sub build_transcode_more_audio_tracks_job {
    my $self = shift;
    my ($title, $bc) = @_;
    
    my @jobs;
    my $add_audio_tracks = $title->get_additional_audio_tracks;
    my $mpeg             = $title->is_mpeg;

    foreach my $avi_nr ( sort { $a <=> $b } keys %{$add_audio_tracks} ) {
        my $vob_nr = $add_audio_tracks->{$avi_nr};
        my $transcode_audio_job = $self->build_transcode_audio_job (
            $title, $vob_nr, $avi_nr,
        );
        if ( $bc ) {
            $transcode_audio_job->get_post_callbacks(sub {
                my ($job) = @_;
                return if ! $job->finished_ok;
                $bc->add_audio_size (
		    bytes => -s $title->target_avi_audio_file (
			vob_nr => $vob_nr,
			avi_nr => $avi_nr,
		    )
	        );
                1;
            });
        }
        #-- merging not for MPEG and not if bitrate calculation
        #-- is in progress (vbr audio quality mode with later merging)
        if ( !$mpeg && !$bc ) {
            my $merge_audio_job = $self->build_merge_audio_job(
                $title, $vob_nr, $avi_nr,
            );
            push @jobs, Event::ExecFlow::Job::Group->new (
                title   => __("Transcode & merge audio track").$self->get_title_info($title),
                jobs    => [ $transcode_audio_job, $merge_audio_job ],
            );
        }
        else {
            push @jobs, $transcode_audio_job;
        }
        
    }
    
    return Event::ExecFlow::Job::Group->new (
        title   => __("Add additional audio tracks").$self->get_title_info($title),
        jobs    => \@jobs,
    );
}

sub build_transcode_audio_job {
    my $self = shift;
    my ($title, $vob_nr, $avi_nr) = @_;
    
    my $info = __("Transcode audio");
    $info .= $self->get_title_info($title);
    $info .= ", ".__x("track #{nr}", nr => $vob_nr);
	
    my $bitrate = $title->audio_tracks->[$vob_nr]->tc_bitrate;
    my $runtime = $title->runtime;
    my $diskspace_consumed = int($runtime * $bitrate / 8);

    my $command = sub {
        $title->get_transcode_audio_command (
            vob_nr    => $vob_nr,
            target_nr => $avi_nr,
        );
    };
    
    my $progress_parser = $self->get_transcode_progress_parser($title);
    my $progress_max    = $title->get_transcode_progress_max;
        
    return Event::ExecFlow::Job::Command->new (
        title               => $info,
        command             => $command,
        diskspace_consumed  => $diskspace_consumed,
        progress_ips        => __"fps",
        progress_max        => $progress_max,
        progress_parser     => $progress_parser,
    );
}

sub build_mplex_job {
    my $self = shift;
    my ($title) = @_;
    
    my $info = __("Multiplex MPEG").$self->get_title_info($title);

    my $bc = Video::DVDRip::BitrateCalc->new (
        title       => $title,
        with_sheet  => 0,
    );
    $bc->calculate;
    my $diskspace_consumed = int(($bc->video_size + $bc->non_video_size)*1024);
   
    my $command = $title->get_mplex_command;
   
    return Event::ExecFlow::Job::Command->new (
        title               => $info,
        command             => $command,
        diskspace_consumed  => $diskspace_consumed,
    );
}

sub build_split_job {
    my $self = shift;
    my ($title) = @_;
    
    my $info = $title->is_ogg ? __"Split OGG" : __"Split AVI";
    $info .= $self->get_title_info($title);

    my $diskspace_consumed = $title->tc_target_size * 1024;
    my $progress_ips = $title->is_ogg ? undef : __"fps";
    my $progress_max = $title->is_ogg ? 2000 : $title->get_transcode_progress_max;

    my $ogg_pass = 1;
    my $progress_parser = $title->is_ogg ?
        sub {
            my ($job, $buffer) = @_;
	    if ( $buffer =~ /second\s+pass/i ) {
		$job->set_progress_ips( __"fps" );
                $ogg_pass = 2;
	    }
	    if ( $buffer =~ m!(\d+)/(\d+)! ) {
		$job->set_progress_cnt (
		    1000 * ( $ogg_pass - 1 ) +
		    int ( 1000 * $1 / $2 )
		);
	    }
        } :
        sub {
            my ($job, $buffer) = @_;
	    if ( $buffer =~ /\(\d+-(\d+)\)/ ) {
                $job->set_progress_cnt ($1);
	    }
        };

    my $command = sub { $title->get_split_command };

    return Event::ExecFlow::Job::Command->new (
        title               => $info,
        command             => $command,
        diskspace_consumed  => $diskspace_consumed,
        progress_ips        => $progress_ips,
        progress_max        => $progress_max,
        progress_parser     => $progress_parser,
    );
}

#=====================================================================
# Subtitle stuff
#=====================================================================

sub build_grab_subtitle_images_job {
    my $self = shift;
    my ($title) = @_;
    
    my $info = __("Grab subtitle images").$self->get_title_info($title);

    my $progress_max    = $title->selected_subtitle->tc_preview_img_cnt;
    my $command         = $title->get_subtitle_grab_images_command;
    my $progress_parser = qr/pic(\d+)/;

    return Event::ExecFlow::Job::Command->new (
        title               => $info,
        command             => $command,
        progress_max        => $progress_max,
        progress_parser     => $progress_parser,
    );
}

sub check_subtitle_settings {
    my $self = shift;
    my ($job, $title, $split, @subtitles) = @_;
    
    foreach my $subtitle ( @subtitles ) {
        if ( not -f $subtitle->ifo_file ) {
            $job->set_error_message(
	        __"Need IFO files in place.\n".
	          "You must re-read TOC from DVD."
            );
            return;
        }
    }
    
    if ( $split && @{$title->get_split_files} == 0 ) {
        $job->set_error_message(
	    __"No splitted target files available.\n".
	      "First transcode and split the movie."
        );
        return;
    }
    
    1;
}

sub build_vobsub_job {
    my $self = shift;
    my ($title, $subtitle) = @_;

    my @subtitles;
    if ( $subtitle ) {
        @subtitles = ( $subtitle );
    }
    else {
        @subtitles = sort   { $a->id <=> $b->id }
                     grep   { $_->tc_vobsub }
                     values %{$title->subtitles};
    }

    my $job;
    if ( $title->tc_split ) {
        $job = $self->build_splitted_vobsub_job($title, @subtitles);
    }
    else {
        $job = $self->build_non_splitted_vobsub_job($title, @subtitles);
    }
    
    return $job;
}

sub build_splitted_vobsub_job {
    my $self = shift;
    my ($title, @subtitles) = @_;
    
    my @jobs;
    my $count_job = $self->build_count_frames_in_file_job($title);
    push @jobs, $count_job;

    $count_job->get_post_callbacks->add(sub {
        foreach my $subtitle ( @subtitles ) {
            my ($job) = @_;
            my $vobsub_group = $job->get_group->get_job_by_name("vobsub_group");
            my $file_nr = 0;
            my $files_scanned = $count_job->get_stash->{files_scanned};

            my $group = Event::ExecFlow::Job::Group->new (
                title       => __("Create vobsub files").
                               $self->get_title_info($title).
                               ", ".
                               "sid #".$subtitle->id,
                jobs        => [],
            );

            $vobsub_group->add_job($group);

            foreach my $file ( @{$files_scanned} ) {
                my ($start, $end);
                if ( $file_nr == 0 ) {
		    $start = 0;
		    $end   = $files_scanned->[$file_nr]->{frames} /
			     $title->tc_video_framerate;
                }
                else {
		    $start = $files_scanned->[$file_nr-1]->{end};
		    $end   = $start + 
			     $files_scanned->[$file_nr]->{frames}/
			     $title->tc_video_framerate;
		    $end += 1000 if $file_nr ==
				    @{$files_scanned} - 1;
                }
                $group->add_job(
                    $self->build_create_vobsub_file_job(
                        $title, $subtitle, $file_nr, $start, $end
                    )
                );
                ++$file_nr;
            }
        }
    });

    my @ps1_jobs;
    foreach my $subtitle ( @subtitles ) {
        push @ps1_jobs, $self->build_extract_ps1_job($title, $subtitle);
    }

    push @jobs, Event::ExecFlow::Job::Group->new (
        title           => __("Extract PS1 streams from VOB").
                           $self->get_title_info($title),
        jobs            => \@ps1_jobs,
    );

    push @jobs, Event::ExecFlow::Job::Group->new (
        name            => "vobsub_group",
        title           => __("Create vobsub files").
                           $self->get_title_info($title),
        jobs            => [],
    );

    my $pre_callbacks = sub{
        my ($job) = @_;
        $self->check_subtitle_settings($job, $title, "SPLIT", @subtitles);
    };

    return Event::ExecFlow::Job::Group->new (
        title           => __("Splitted vobsub file generation").
                           $self->get_title_info($title),
        jobs            => \@jobs,
        pre_callbacks   => $pre_callbacks,
    );
}

sub build_count_frames_in_file_job {
    my $self = shift;
    my ($title) = @_;
    
    my $info = __("Count frames of files").$self->get_title_info($title);

    my $pre_callbacks = sub {
        my ($job) = @_;
        $job->set_command($title->get_count_frames_in_files_command);
    };

    my $post_callbacks = sub {
        my ($job) = @_;
        return unless $job->finished_ok;
        my $output = $job->get_output;
        my @files;
        while ( $output =~ /DVDRIP:...:([^\s]+)/g  ) {
            push @files, { name => $1 };
        }
        my $i = 0;
        while ( $output =~ /frames=\s*(\d+)/g ) {
            $files[$i]->{frames} = $1;
            $job->log(
                __x("File {file} has {frames} frames.",
                    file   => $files[$i]->{name},
                    frames => $files[$i]->{frames})
            );
            ++$i;
        }
        $job->get_stash->{files_scanned} = \@files;
        1;
    };

    return Event::ExecFlow::Job::Command->new (
        title           => $info,
        command         => undef,
        pre_callbacks   => $pre_callbacks,
        post_callbacks  => $post_callbacks,
        no_progress     => 1,
        fetch_output    => 1,
    );
}

sub build_non_splitted_vobsub_job {
    my $self = shift;
    my ($title, @subtitles) = @_;
    
    my @jobs;
    foreach my $subtitle ( @subtitles ) {
        push @jobs, $self->build_extract_ps1_job($title, $subtitle);
        push @jobs, $self->build_create_vobsub_file_job($title, $subtitle);
    }

    my $pre_callbacks = sub{
        my ($job) = @_;
        $self->check_subtitle_settings($job, $title, 0, @subtitles);
    };

    return Event::ExecFlow::Job::Group->new (
        title           => __("Single vobsub file generation").
                           $self->get_title_info($title),
        jobs            => \@jobs,
        pre_callbacks   => $pre_callbacks,
    );
}

sub build_extract_ps1_job {
    my $self = shift;
    my ($title, $subtitle) = @_;

    my $info = __("Extract PS1 stream from VOB").
               $self->get_title_info($title).
               ", sid #".$subtitle->id;

    my $progress_max = $title->project->rip_mode eq 'rip' ? 10000 : undef;

    my $command = sub {
        $title->get_extract_ps1_stream_command (
            subtitle => $subtitle
        );
    };
    
    my $progress_parser = sub {
        my ($job, $buffer) = @_;
	if ( $buffer =~ m!dvdrip-progress:\s*(\d+)/(\d+)! ) {
	    $job->set_progress_cnt (10000*$1/$2);
	}
    };
    
    my $post_callbacks = sub {
        my ($job) = @_;
        unlink $subtitle->ps1_file unless $job->finished_ok;
    };
    
    my $pre_callbacks = sub {
        my ($job) = @_;
        my $ps1_file = $subtitle->ps1_file;
        if ( -f $ps1_file ) {
	    $job->log (
		    __x("PS1 file '{filename}' already exists. ".
                       "Skip extraction.", filename => $ps1_file)
	    );
            $job->set_skipped(1);
        }
    };
    
    return Event::ExecFlow::Job::Command->new (
        title           => $info,
        progress_max    => $progress_max,
        progress_parser => $progress_parser,
        pre_callbacks   => $pre_callbacks,
        post_callbacks  => $post_callbacks,
        command         => $command,
    );
}

sub build_create_vobsub_file_job {
    my $self = shift;
    my ($title, $subtitle, $file_nr, $start, $end) = @_;
    
    my $info = __("Create vobsub file").
               $self->get_title_info($title).
               ", sid #".$subtitle->id;

    $info .= __x(", file #{nr}", nr => $file_nr+1)
        if defined $file_nr;

    my $progress_max = 10000;
    
    my $command = sub {
        $title->get_create_vobsub_command (
            subtitle    => $subtitle,
            file_nr     => $file_nr,
            start       => $start,
            end         => $end,
        );
    };
    
    my $progress_parser = sub {
        my ($job, $buffer) = @_;
	if ( $buffer =~ m!dvdrip-progress:\s*(\d+)/(\d+)! ) {
	    $job->set_progress_cnt (10000*$1/$2);
	}
    };

    return Event::ExecFlow::Job::Command->new (
        title           => $info,
        progress_max    => $progress_max,
        progress_parser => $progress_parser,
        command         => $command,
    );
}

#=====================================================================
# Misc stuff
#=====================================================================

sub build_scan_volume_job {
    my $self = shift;
    my ($title) = @_;
    
    my $chapters = $title->get_chapters;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    my @jobs;
    my $count = 0;
    foreach my $chapter ( @{$chapters} ) {
        $title->set_actual_chapter($chapter);

        my $info =
            __("Volume scan").$self->get_title_info($title).", ".
            __x("audio track #{nr}", nr => $title->audio_channel );

        my $progress_max;
        my $progress_ips;
        if ( $title->project->rip_mode eq 'rip' ) {
            $progress_max = $title->get_vob_size;

        }
        elsif ( not $chapter ) {
            $progress_ips = __"fps";
            $progress_max = $title->frames;
        }
        else {
            if ( defined $title->chapter_frames->{$chapter} ) {
                $progress_ips = __"fps";
                $progress_max =
                    $title->chapter_frames->{$chapter};
            }
        }

        my $command = $title->get_scan_command;

        my $progress_parser = sub {
            my ($job, $buffer) = @_;
            if ( $buffer =~ m!dvdrip-progress:\s*(\d+)/(\d+)! ) {
                $job->set_progress_cnt( $1 );
                $job->set_progress_max( $2 );
            }
            else {
                my $frames = $job->get_progress_cnt;
                ++$frames while $buffer =~ /^[\d\t ]+$/gm;
                $job->set_progress_cnt($frames);
            }
        };

        my $scan_count = $count;    # make closure copy
        my $post_callbacks = sub {
            my ($job) = @_;
            $title->analyze_scan_output(
                output  => $job->get_output,
                count   => $scan_count,
            );
        };

        push @jobs, Event::ExecFlow::Job::Command->new (
            title           => $info,
            command         => $command,
            progress_max    => $progress_max,
            progress_ips    => $progress_ips,
            progress_parser => $progress_parser,
            post_callbacks  => $post_callbacks,
            fetch_output    => 1,
        );

        $title->set_actual_chapter();
        ++$count;
    }

    $jobs[0]->get_pre_callbacks->add(sub{
        $title->audio_track->set_volume_rescale();
    });

    if ( @jobs > 1 ) {
        my $info =
            __("Volume scan").$self->get_title_info($title).", ".
            __x("audio track #{nr}", nr => $title->audio_channel );
        return Event::ExecFlow::Job::Group->new (
            title   => $info,
            jobs    => \@jobs,
        );
    }
    else {
        return $jobs[0];
    }
}

sub build_create_wav_job {
    my $self = shift;
    my ($title) = @_;
    
    my $chapters = $title->get_chapters;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    my @jobs;
    my $count = 0;
    foreach my $chapter ( @{$chapters} ) {
        $title->set_actual_chapter($chapter);

        my $info =
            __("Create WAV").$self->get_title_info($title).", ".
            __x("audio track #{nr}", nr => $title->audio_channel );

        my $sample_rate = $title->audio_track->sample_rate;
        my $runtime = $title->runtime;
        my $diskspace_consumed = int($runtime * $sample_rate * 2 / 1024);
        $diskspace_consumed = int($diskspace_consumed / $title->chapters)
            if $chapter;

        my $command = $title->get_create_wav_command;

        my $progress_parser = $self->get_transcode_progress_parser($title);
        my $progress_max    = $title->get_transcode_progress_max;
        my $progress_ips    = __"fps";

        push @jobs, Event::ExecFlow::Job::Command->new (
            title               => $info,
            command             => $command,
            progress_max        => $progress_max,
            progress_ips        => $progress_ips,
            progress_parser     => $progress_parser,
            diskspace_consumed  => $diskspace_consumed,
        );

        $title->set_actual_chapter();
    }
    
    if ( @jobs > 1 ) {
        my $info =
            __("Create WAV").$self->get_title_info($title).", ".
            __x("audio track #{nr}", nr => $title->audio_channel );
        return Event::ExecFlow::Job::Group->new (
            title   => $info,
            jobs    => \@jobs,
        );
    }
    else {
        return $jobs[0];
    }
}

1;
