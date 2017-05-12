# $Id: InfoFile.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::InfoFile;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;
use FileHandle;
use File::Basename;
use File::Path;

sub title			{ shift->{title}			}
sub filename			{ shift->{filename}			}
sub fields			{ shift->{fields}			}
sub max_name_length		{ shift->{max_name_length}		}

sub set_title			{ shift->{title}		= $_[1]	}
sub set_filename		{ shift->{filename}		= $_[1]	}
sub set_fields			{ shift->{fields}		= $_[1]	}
sub set_max_name_length		{ shift->{max_name_length}	= $_[1]	}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $title, $filename ) = @par{ 'title', 'filename' };

    croak "title must be set" if not $title;

    $filename ||= $title->info_file;

    my $self = {
        title    => $title,
        filename => $filename,
        fh       => undef,
        fields   => [],
    };

    return bless $self, $class;
}

sub write {
    my $self = shift;

    my $title = $self->title;

    $self->init_fields;

    # General ----------------------------------------------------

    $self->add_head( name => "General", );
    $self->add_field(
        name  => "Title",
        value => $title->project->name,
    );
    $self->add_field(
        name  => "Data source",
        value => "DVD",
    );
    $self->add_field(
        name  => "DVD title number",
        value => $title->nr,
    );
    $self->add_field(
        name  => "Runtime",
        value => $self->format_time(
            time => int(
                $title->get_transcode_frame_cnt / $title->tc_video_framerate
            )
        ),
    );

    # Video ------------------------------------------------------

    $self->add_head( name => "Video", );
    $self->add_field(
        name  => "Video format",
        value => uc( $title->video_mode ),
    );
    $self->add_field(
        name  => "FPS",
        value => $title->tc_video_framerate,
    );
    $self->add_field(
        name  => "Size",
        value =>
            sprintf( "%d x %d", $title->get_transcoded_video_width_height )
    );
    $self->add_field(
        name  => "Video bitrate (kbps)",
        value => $title->tc_video_bitrate,
    );
    $self->add_field(
        name  => "Video codec",
        value => $title->tc_video_codec
    );
    $self->add_field(
        name  => "AF6 codec",
        value => $title->tc_video_af6_codec
        )
        if $title->tc_video_af6_codec;
    $self->add_field(
        name  => "2-pass-encoded",
        value => $title->tc_multipass ? "yes" : "no",
    );
    $self->add_field(
        name  => "Fast resizing",
        value => $title->tc_fast_resize ? "yes" : "no",
    );
    $self->add_field(
        name  => "Deinterlacer filter",
        value =>
            $Video::DVDRip::deinterlace_filters{ $title->tc_deinterlace },
    );
    $self->add_field(
        name  => "Antialiasing filter",
        value => $Video::DVDRip::antialias_filters{ $title->tc_anti_alias },
    );

    # Subtitles --------------------------------------------------

    my $sub_id = 1;
    if ( $title->subtitles ) {
        foreach my $sub ( sort { $a->id <=> $b->id }
            values %{ $title->subtitles } ) {
            next if not $sub->tc_vobsub and not $sub->tc_render;
            $self->add_head( name => "Subtitle $sub_id" );
            $self->add_field(
                name  => "Id",
                value => $sub->id,
            );
            $self->add_field(
                name  => "Language",
                value => $sub->lang,
            );
            $self->add_field(
                name  => "Type",
                value => ( $sub->tc_render ? "rendered" : "vobsub" )
            );
            ++$sub_id;
        }
    }

    # Audio ------------------------------------------------------

    foreach my $audio ( sort { $a->tc_target_track <=> $b->tc_target_track }
        @{ $title->audio_tracks } ) {
        next if $audio->tc_target_track < 0;
        $self->add_head( name => "Audio " . ( $audio->tc_target_track + 1 ) );

        my $codec = $audio->tc_audio_codec;

        $self->add_field(
            name  => "DVD audio track id",
            value => $audio->tc_nr,
        );
        $self->add_field(
            name  => "Language",
            value => $audio->lang,
        );
        $self->add_field(
            name  => "Audio codec",
            value => $codec,
        );
        $self->add_field(
            name  => "MP3 quality",
            value => $audio->tc_mp3_quality,
            )
            if $codec eq "mp3";
        $self->add_field(
            name  => "Channels",
            value => $codec eq "ac3" ? $audio->channels : 2,
        );
        $self->add_field(
            name  => "Sample rate",
            value => $audio->sample_rate,
        );
        my $bitrate_method = "tc_${codec}_bitrate";
        $self->add_field(
            name  => "Audio bitrate (kbps)",
            value => $audio->$bitrate_method(),
        );

        if ( $codec ne 'ac3' and $codec ne 'pcm' ) {
            $self->add_field(
                name  => "Volume rescaling",
                value => ( $audio->tc_volume_rescale || "none" ),
            );
            $self->add_field(
                name  => "Audio filter",
                value =>
                    $Video::DVDRip::audio_filters{ $audio->tc_audio_filter },
            );
        }
    }

    $self->add_head( name => "Programs" );
    $self->add_field(
        name  => "dvd::rip version",
        value => $Video::DVDRip::VERSION,
    );
    $self->add_field(
        name  => "transcode version",
        value => $self->depend_object->tools->{transcode}->{installed},
    );

    $self->write_fields;

    1;
}

sub init_fields {
    my $self = shift;

    $self->set_fields( [] );
    $self->set_max_name_length(0);

    1;
}

sub add_head {
    my $self   = shift;
    my %par    = @_;
    my ($name) = @par{'name'};

    push @{ $self->fields }, { head => $name };

    1;
}

sub add_field {
    my $self = shift;
    my %par  = @_;
    my ( $name, $value ) = @par{ 'name', 'value' };

    push @{ $self->fields }, { name => $name, value => $value };

    $self->set_max_name_length( length($name) )
        if length($name) > $self->max_name_length;

    1;
}

sub write_fields {
    my $self = shift;

    my $filename = $self->filename;
    my $dir      = dirname($filename);
    mkpath( [$dir], 0, 0755 ) if not -d $dir;

    my $fh = FileHandle->new;
    open( $fh, "> $filename" ) or die "can't write $filename";

    print $fh
        "# Movie information file. Generated by dvd::rip; http://www.exit1.org/dvdrip\n";

    my $len = $self->max_name_length + 1;

    foreach my $field ( @{ $self->fields } ) {
        if ( $field->{head} ) {
            print $fh "\n[$field->{head}]\n";
            next;
        }
        printf $fh "%-${len}s  %s\n", $field->{name} . ":", $field->{value};
    }

    close $fh;

    1;
}

sub read {
    my $self = shift;

    $self->init_fields;

    my $filename = $self->filename;

    my $fh = FileHandle->new;
    open( $fh, $filename ) or die "can't read $filename";

    while (<$fh>) {
        next if /^\s*#/;
        next if !/\S/;
        if (/\[([^\]]+)/) {
            $self->add_head( name => $1 );
            next;
        }
        if (/^\s*([^:]+):\s*(.*)/) {
            $self->add_field( name => $1, value => $2 );
        }
    }

    close $fh;

    1;
}

sub add_files_section {
    my $self         = shift;
    my %par          = @_;
    my ($files_lref) = @par{'files_lref'};

    my $nr = 0;
    foreach my $file ( @{$files_lref} ) {
        $self->add_head( name => "File $nr" );
        $self->add_field(
            name  => "Name",
            value => $file->{name},
        );
        $self->add_field(
            name  => "Size (MB)",
            value => $file->{size},
        );
        $self->add_field(
            name  => "Frames",
            value => $file->{frames},
        );
        ++$nr;
    }

    1;
}

sub get_value {
    my $self = shift;
    my %par  = @_;
    my ( $head, $field ) = @par{ 'head', 'field' };

    $head  = lc($head);
    $field = lc($field);

    my $in_head = 0;
    foreach my $field ( @{ $self->fields } ) {
        if ( lc( $field->{head} ) eq $head ) {
            $in_head = 1;
            next;
        }
        if ( $in_head and lc( $field->{name} ) eq $field ) {
            return $field->{value};
        }
    }

    croak "Can't find field '$field' in section '$head'";
}

1;
