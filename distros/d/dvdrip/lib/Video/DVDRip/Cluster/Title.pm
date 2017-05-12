# $Id: Title.pm 2397 2010-03-06 13:06:33Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Title;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Title;

use Carp;
use strict;

use File::Basename;

sub frames_finished             { shift->{frames_finished}              }
sub with_cleanup                { shift->{with_cleanup}                 }
sub with_vob_remove             { shift->{with_vob_remove}              }
sub frames_per_chunk            { shift->{frames_per_chunk}             }

sub set_frames_finished         { shift->{frames_finished}      = $_[1] }
sub set_with_cleanup            { shift->{with_cleanup}         = $_[1] }
sub set_with_vob_remove         { shift->{with_vob_remove}      = $_[1] }
sub set_frames_per_chunk        { shift->{frames_per_chunk}     = $_[1] }

sub info {
    my $self = shift;
    return $self->project->name . " (#" . $self->nr . ")";
}

sub create_vob_dir {
    my $self = shift;

    # no vob_dir creating here. This is done just before we
    # start transcoding to prevent from too much ssh remote
    # communication.

    return 1;
}

sub create_avi_dir {
    my $self = shift;

    # no avi_dir creating here. This is done just before we
    # start transcoding to prevent from too much ssh remote
    # communication.

    return 1;
}

sub is_ripped {
    return 1;
}

#-----------------------------------------------------------------------
# Filenames of all stages
#-----------------------------------------------------------------------

sub multipass_log_dir {				# directory for multipass logs
    my $self = shift;

    my $job = $Event::ExecFlow::JOB;

    return sprintf (
	"%s/%s/cluster/%03d-%02d-%05d",
	$job->get_node->data_base_dir,
	$self->project->name,
	$self->nr,
	$job->get_stash->{psu},
	$job->get_stash->{chunk},
    );
}

sub avi_chunks_dir {       # directory for avi chunks
    my $self = shift;

    my $job = $Event::ExecFlow::JOB;

    return sprintf (
	"%s/%03d/chunks-psu-%02d",
	$self->project->final_avi_dir,
	$self->nr,
	$job->get_stash->{psu},
    );
}

sub avi_file {             # transcode output file
    my $self = shift;

    my $job = $Event::ExecFlow::JOB;

    return sprintf (
	"%s/%s-%03d-%05d.avi",
	$self->avi_chunks_dir,
	$self->project->name,
	$self->nr,
	$job->get_stash->{chunk},
    );
}

sub target_avi_audio_file {
    my $self = shift;

    my $ext = $self->is_ogg ? $self->config('ogg_file_ext') : 'avi';
    my $job = $Event::ExecFlow::JOB;

    return sprintf (
	"%s/%03d/audio-psu-%02d/%s-%03d-audio-psu-%02d-%02d.$ext",
	$self->project->final_avi_dir,
	$self->nr,
	$job->get_stash->{psu},
	$self->project->name,
	$self->nr,
	$job->get_stash->{psu},
	$job->get_stash->{avi_nr},
    );
}

sub audio_video_psu_dir {
    my $self = shift;

    return sprintf (
	"%s/%03d/audio-video-psu",
	$self->project->final_avi_dir,
	$self->nr,
    );
}

sub audio_video_psu_file {
    my $self = shift;

    my $ext = $self->is_ogg ? $self->config('ogg_file_ext') : 'avi';
    my $job = $Event::ExecFlow::JOB;

    return sprintf (
	"%s/%s-%03d-av-psu-%02d.$ext",
	$self->audio_video_psu_dir,
	$self->project->name,
	$self->nr,
	$job->get_stash->{psu},
    );
}

sub target_avi_file {    # final avi, merged PSUs + audio
    my $self = shift;

    my $ext = $self->is_ogg ? $self->config('ogg_file_ext') : 'avi';

    return sprintf(
	"%s/%03d/%s-%03d.$ext",
	$self->project->final_avi_dir,
	$self->nr,
	$self->project->name,
	$self->nr
    );
}

#-----------------------------------------------------------------------
# Commands for all Jobs
#-----------------------------------------------------------------------

sub get_transcode_command {
    my $self = shift;

    my $psu       = "DVDRIP_JOB_PSU";
    my $chunk     = "DVDRIP_JOB_CHUNK";
    my $chunk_cnt = "DVDRIP_JOB_CHUNK_CNT";

    my $nav_file = $self->vob_nav_file;

    my $command = $self->SUPER::get_transcode_command(
        no_audio => 1,
        @_
    );

    # remove EXECFLOW_OK
    $command =~ s/&&\s+echo\s+EXECFLOW_OK//;

    # no audio options
    $command =~ s/\s-[baN]\s+[^\s]+//;

    # no -c in cluster mode
    $command =~ s/ -c \d+-\d+//;

    # no preview in cluster mode
    $command =~ s/-J\s+preview=[^\s]+//;

    # add -S and -W options for chunk selection (dont' just append,
    # because the transcode command probably got appended some
    # additional shell commands - e.g. h264 log copy stuff)
    $command =~
        s{ (execflow.*?transcode) }
         { $1 -S $psu -W $chunk,$chunk_cnt,$nav_file };

    # sorry, can't remember why I do that...
    $command =~ s/-M 2//;

    # add directory creation code
    my $avi_dir = dirname $self->avi_file;
    $command = "mkdir -m 0775 -p '$avi_dir' && $command";

    # add EXECFLOW_OK
    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub get_transcode_audio_command {
    my $self = shift;
    my %par = @_;
    my ( $vob_nr, $target_nr ) = @par{ 'vob_nr', 'target_nr' };

    my $command = $self->SUPER::get_transcode_audio_command(@_);
    $command =~ s/\s+&& echo EXECFLOW_OK//;

    if ( $self->version("transcode") >= 10100 ) {
        $command .=
              " --psu_mode --no_split"
            . " --psu_chunks DVDRIP_JOB_PSU-DVDRIP_JOB_ADD_ONE_PSU"
            . " --nav_seek ".$self->vob_nav_file;
    }
    else {
        $command .=
              " -S DVDRIP_JOB_PSU"
            . " -W DVDRIP_JOB_CHUNK_CNT,DVDRIP_JOB_CHUNK_CNT,"
            . $self->vob_nav_file;
    }

    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub get_merge_audio_command {
    my $self = shift;
    my %par = @_;
    my ( $vob_nr, $target_nr ) = @par{ 'vob_nr', 'target_nr' };

    my $avi_file    = $self->audio_video_psu_file;
    my $audio_file  = $self->target_avi_audio_file;
    my $target_file = $avi_file;

    my $command;
    my $nice;
    $nice = "`which nice` -n " . $self->tc_nice . " "
        if $self->tc_nice =~ /\S/;

    $command = $nice;

    # operate on final avi file if no PSU merging is necessary
#    if ( @{$self->program_stream_units} == 1 ) {
#        $avi_file    = $self->target_avi_file;
#        $target_file = $self->target_avi_file;
#    }

    if ( $self->is_ogg ) {
        # remove audio_video_psu file here, because
        # this isn't done in get_merge_video_audio_command,
        # because audio merging is done here with ogg.
        my $audio_video_psu_file;
        $audio_video_psu_file = $self->audio_video_psu_file
            if $self->with_cleanup
            and $self->audio_video_psu_file ne $target_file;

        $command .= "execflow ogmmerge -o $avi_file.merged "
            . " $avi_file"
            . " $audio_file &&"
            . " mv $avi_file.merged $target_file &&"
            . " rm -f $audio_file $audio_video_psu_file &&"
            . " echo EXECFLOW_OK";

    }
    else {
        $command .= "execflow avimerge"
            . " -p $audio_file"
            . " -a $target_nr"
            . " -o $avi_file.merged"
            . " -i $avi_file &&"
            . " mv $avi_file.merged $target_file &&"
            . " rm $audio_file &&"
            . " echo EXECFLOW_OK";
    }

    return $command;
}

sub get_merge_video_audio_command {
    my $self = shift;

    #-- with one PSU and AVI processing this avimerge file
    #-- creates the final file
    my $move_final = 0;
#        @{$self->program_stream_units} == 1 && !$self->is_ogg;
    
    my $avi_chunks_dir       = $self->avi_chunks_dir;
    my $audio_video_psu_file = $self->audio_video_psu_file;
    $audio_video_psu_file = $self->target_avi_file
        if $move_final;

    my $audio_video_psu_dir = dirname($audio_video_psu_file);
    my $audio_psu_file      = $self->target_avi_audio_file;

    my $chunks_mask = sprintf( "%s/%03d/chunks-psu-??/*",
        $self->project->final_avi_dir, $self->nr );

    my $nice;
    $nice = "`which nice` -n " . $self->tc_nice . " "
        if $self->tc_nice =~ /\S/;

    my $command = "mkdir -m 0775 -p '$audio_video_psu_dir' && "
        . "${nice}execflow avimerge -o $audio_video_psu_file";

    $command .= " -p $audio_psu_file " if !$self->is_ogg;

    #-- -i *always* at the end! At some time avimerge's cmd line
    #-- parser was messed up...
    $command .= " -i $avi_chunks_dir/*";

    $command .= " && rm $avi_chunks_dir/*"
        if $self->with_cleanup;

    $command .= " '$audio_psu_file'"
        if $self->with_cleanup
        and not $self->is_ogg;

    $command .= " && echo EXECFLOW_OK";

    return $command;
}

sub get_merge_psu_command {
    my $self = shift;
    my %par = @_;
    my ($psu) = @par{'psu'};

    my $target_avi_file     = $self->target_avi_file;
    my $target_avi_dir      = dirname($target_avi_file);
    my $audio_video_psu_dir = $self->audio_video_psu_dir;

    my $ext = $self->is_ogg ? $self->config('ogg_file_ext') : 'avi';
    my $nice;
    $nice = "`which nice` -n " . $self->tc_nice . " "
        if $self->tc_nice =~ /\S/;

    my $command
        = "mkdir -m 0775 -p '$target_avi_dir' && " . "${nice}execflow ";

    if ( $self->is_ogg ) {
        $command .= "ogmcat -v -v ";    # -v -v to prevent timeouts
    }
    else {
        $command .= "avimerge ";
    }

    $command .= "-o '$target_avi_file' ";
    $command .= "-i " if not $self->is_ogg;
    $command .= "$audio_video_psu_dir/*.$ext";

    $command .= " && echo EXECFLOW_OK";
    $command .= " && rm $audio_video_psu_dir/*.$ext"
        if $self->with_cleanup;

    return $command;
}

sub get_split_command {
    my $self = shift;

    my $target_avi_file = $self->target_avi_file;

    my $command = $self->SUPER::get_split_command;

    $command .= " && rm '$target_avi_file'"
        if $self->with_cleanup
        and $command =~ /avisplit|ogmsplit/;

    return $command;
}

sub save {
    my $self = shift;

    $self->project->save;

    1;
}

1;
