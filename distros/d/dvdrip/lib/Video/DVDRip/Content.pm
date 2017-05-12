# $Id: Content.pm 2269 2007-03-10 09:51:32Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Content;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Video::DVDRip::Title;

use Carp;
use strict;

sub project			{ shift->{project}			}
sub titles			{ shift->{titles}  			}
sub selected_titles		{ shift->{selected_titles}		}

sub set_titles			{ shift->{titles}		= $_[1] }
sub set_selected_titles		{ shift->{selected_titles}	= $_[1]	}

sub set_project {
    my $self = shift;
    my ($project) = @_;

    $self->{project} = $project;

    return if not $self->titles;

    foreach my $title ( values %{ $self->titles } ) {
        $title->set_project($project);
        next if not $title->subtitles;
        foreach my $subtitle ( values %{ $title->subtitles } ) {
            $subtitle->set_title($title);
        }
        foreach my $audio_track ( @{ $title->audio_tracks } ) {
            $audio_track->set_title($title);
        }
    }

    return $project;
}

sub new {
    my $class     = shift;
    my %par       = @_;
    my ($project) = @par{'project'};

    my $self = {
        project         => $project,
        titles          => undef,
        selected_titles => [],
    };

    return bless $self, $class;
}

sub get_titles_by_nr {
    my $self = shift;

    $self->read_title_listing if not $self->titles;

    my @titles = sort { $a->nr <=> $b->nr } values %{ $self->titles };

    return \@titles;
}

sub set_selected_title_nr {
    my $self = shift;
    my ($nr) = @_;
    die "msg: " . __x( "Illegal title number {nr}", nr => $nr )
        unless exists $self->titles->{$nr};
    $self->set_selected_titles( [ $nr - 1 ] );
    return $nr;
}

sub selected_title_nr {
    my $self            = shift;
    my $selected_titles = $self->selected_titles;
    return if not $selected_titles;
    return if @{$selected_titles} == 0;
    return $self->titles->{ $selected_titles->[0] + 1 }->nr;
}

sub selected_title {
    my $self            = shift;
    my $selected_titles = $self->selected_titles;
    return if not $selected_titles;
    return if @{$selected_titles} == 0;
    return $self->titles->{ $selected_titles->[0] + 1 };
}

sub select_longest_title {
    my $self = shift;
    
    my $selected_title;
    foreach my $title ( values %{ $self->titles } ) {
        $selected_title ||= $title;
        if ( $title->runtime > $selected_title->runtime ) {
            $selected_title = $title;
        }
    }
    
    $self->set_selected_title_nr($selected_title->nr)
        if $selected_title;
    
    1;
}

#---------------------------------------------------------------------
# Methods for TOC reading
#---------------------------------------------------------------------

sub get_probe_title_cnt_command {
    my $self = shift;

    my $data_source = $self->project->rip_data_source;

    $data_source = quotemeta($data_source);

    return "execflow tcprobe -H 10 -i $data_source && echo EXECFLOW_OK";
}

sub get_read_toc_lsdvd_command {
    my $self = shift;

    my $data_source = $self->project->rip_data_source;

    $data_source = quotemeta($data_source);

    my $command
        = "execflow lsdvd -a -n -c -s -v -Op $data_source 2>/dev/null";

    return $command;
}

1;
