# $Id: Probe.pm 2195 2006-08-18 21:43:37Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Probe;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;

sub width			{ shift->{width}	    		}
sub height			{ shift->{height}	    		}
sub aspect_ratio		{ shift->{aspect_ratio}	    		}
sub video_mode			{ shift->{video_mode}	    		}
sub letterboxed			{ shift->{letterboxed}	    		}
sub frames			{ shift->{frames}			}
sub runtime			{ shift->{runtime}			}
sub frame_rate			{ shift->{frame_rate}			}
sub bitrates			{ shift->{bitrates}			}	# href
sub audio_tracks		{ shift->{audio_tracks}			}	# lref
sub probe_output		{ shift->{probe_output}	    		}
sub audio_probe_output		{ shift->{audio_probe_output}  		}
sub chapters			{ shift->{chapters}	    		}
sub viewing_angles		{ shift->{viewing_angles}		}

sub set_width			{ shift->{width}		= $_[1]	}
sub set_height			{ shift->{height}		= $_[1]	}
sub set_aspect_ratio		{ shift->{aspect_ratio}		= $_[1]	}
sub set_video_mode		{ shift->{video_mode}		= $_[1]	}
sub set_letterboxed		{ shift->{letterboxed}		= $_[1]	}
sub set_frames			{ shift->{frames}		= $_[1] }
sub set_runtime			{ shift->{runtime}		= $_[1] }
sub set_frame_rate		{ shift->{frame_rate}		= $_[1] }
sub set_bitrates		{ shift->{bitrates}		= $_[1] }
sub set_audio_tracks		{ shift->{audio_tracks}		= $_[1] }
sub set_probe_output		{ shift->{probe_output}		= $_[1]	}
sub set_audio_probe_output	{ shift->{audio_probe_output}	= $_[1]	}
sub set_chapters		{ shift->{chapters}		= $_[1]	}
sub set_viewing_angles		{ shift->{viewing_angles}	= $_[1]	}

sub analyze {
    my $class = shift;
    my %par   = @_;
    my ( $probe_output, $title ) = @par{ 'probe_output', 'title' };

    my ( $width,  $height,  $aspect_ratio, $video_mode, $letterboxed );
    my ( $frames, $runtime, $frame_rate,   $chapters,   $angles );

    ($width)        = $probe_output =~ /frame\s+size:\s*-g\s+(\d+)/;
    ($height)       = $probe_output =~ /frame\s+size:\s*-g\s+\d+x(\d+)/;
    ($aspect_ratio) = $probe_output =~ /aspect\s*ratio:\s*(\d+:\d+)/;
    ($video_mode)   = $probe_output =~ /dvd_reader.*?(pal|ntsc)/i;
    ($letterboxed)  = $probe_output =~ /dvd_reader.*?(letterboxed)/;
    ($frames)       = $probe_output =~ /V:\s*(\d+)\s*frames/;
    ($runtime)      = $probe_output =~ /playback time:.*?(\d+)\s*sec/;
    ($frame_rate)   = $probe_output =~ /frame\s+rate:\s+-f\s+([\d.]+)/;
    ($chapters)     = $probe_output =~ /(\d+)\s+chapter/;
    ($angles)       = $probe_output =~ /(\d+)\s+angle/;

    $letterboxed = $letterboxed ? 1 : 0;
    $video_mode  = lc($video_mode);

    my ( $size, %bitrates, $bitrate );
    while ( $probe_output =~ /CD:\s*(\d+)/g ) {
        $size = $1;
        ($bitrate) = $probe_output =~ /CD:\s*$size.*?\@\s*([\d.]+)\s*kbps/;
        ( $bitrates{$size} ) = int($bitrate);
    }

    my (@audio_tracks);
    while ( $probe_output
        =~ /audio\s+track:\s*-a\s*(\d+).*?-e\s+(\d+),(\d+),(\d+)/g ) {
        if ( $2 and $3 ) {
            $audio_tracks[$1] = {
                sample_rate  => $2,
                sample_width => $3,
                bitrate      => undef,    # later set by analyze_audio
                tc_option_n  => undef,    # later set by analyze_audio
                scan_result  => undef,    # later set by Title->scan
            };
        }
    }

    my $i = 0;
    while (
        $probe_output =~ /\(dvd_reader.c\)\s+([^\s]+)\s+(\w+).*?(\d+)Ch/g ) {
        $audio_tracks[$i]->{type}     = lc($1);
        $audio_tracks[$i]->{lang}     = lc($2);
        $audio_tracks[$i]->{channels} = $3;
        ++$i;
    }

    # Audio

    my @audio_track_objects;

    $i = 0;
    foreach my $audio (@audio_tracks) {
        push @audio_track_objects,
            Video::DVDRip::Audio->new(
            title           => $title,
            type            => $audio->{type},
            lang            => $audio->{lang},
            channels        => $audio->{channels},
            sample_rate     => $audio->{sample_rate},
            tc_nr           => $i,
            tc_target_track => ( $i == 0 ? 0 : -1 ),
            tc_audio_codec  => "mp3",
            tc_bitrate      => 128,
            tc_mp3_quality  => 0,
            tc_samplerate   => $audio->{sample_rate},
            );
        ++$i;
    }

    # Subtitles

    my %subtitles;
    my $sid;
    while ( $probe_output =~ /subtitle\s+(\d+)=<([^>]+)>/g ) {
        $sid = $1 + 0;
        $subtitles{$sid} = Video::DVDRip::Subtitle->new(
            id    => $sid,
            lang  => $2,
            title => $title,
        );
    }

    # Chapter frame counter
    my ( $timecode, $last_timecode );
    for ( my $i = 2; $i <= $chapters; ++$i ) {
        ($timecode) = ( $probe_output =~ /CHAPTER0?$i=([\d:.]+)/ );
        next if $timecode eq '';
        $timecode =~ /(\d+):(\d+):(\d+)\.(\d+)/;
        $timecode = $1 * 3600 + $2 * 60 + $3 + $4 / 1000;
        $timecode = int( $timecode * $frame_rate );
        $title->chapter_frames->{ $i - 1 } = $timecode - $last_timecode;
        $last_timecode = $timecode;
    }

    $title->chapter_frames->{$chapters} = $frames - $timecode if $timecode;

    $title->set_width($width);
    $title->set_height($height);
    $title->set_aspect_ratio($aspect_ratio);
    $title->set_video_mode($video_mode);
    $title->set_letterboxed($letterboxed);
    $title->set_frames($frames);
    $title->set_runtime($runtime);
    $title->set_frame_rate("$frame_rate");
    $title->set_bitrates( \%bitrates );
    $title->set_audio_tracks( \@audio_track_objects );
    $title->set_chapters($chapters);
    $title->set_viewing_angles($angles);
    $title->set_dvd_probe_output($probe_output);
    $title->set_audio_channel( @audio_tracks ? 0 : -1 );

    $title->set_subtitles( \%subtitles );
    $title->set_selected_subtitle_id(0) if defined $sid;

    1;
}

sub analyze_audio {
    my $self = shift;
    my %par  = @_;
    my ( $probe_output, $title ) = @par{ 'probe_output', 'title' };

    $title->set_vob_probe_output($probe_output);

    #-- probe audio bitrates
    my @lines = split( /\n/, $probe_output );
    my $nr;
    for ( my $i = 0; $i < @lines; ++$i ) {
        if ( $lines[$i] =~ /audio\s+track:\s+-a\s+(\d+).*?-n\s+([x0-9]+)/ ) {
            $nr = $1;
            next if not defined $title->audio_tracks->[$nr];
            $title->audio_tracks->[$nr]->set_tc_option_n($2);
            ++$i;
            $lines[$i] =~ /bitrate\s*=(\d+)/;
            $title->audio_tracks->[$nr]->set_bitrate($1);
            $title->audio_tracks->[$nr]->set_tc_ac3_bitrate($1);
        }
    }

    #-- probe frame rate (probing from DVD sometimes reports
    #-- wrong framerates for NTSC movies, so we'll correct this here)
    my ($frame_rate) = $probe_output =~ /frame\s+rate:\s+-f\s+([\d.]+)/;
    $title->set_frame_rate("$frame_rate");

    1;
}

sub analyze_scan {
    my $class = shift;
    my %par   = @_;
    my ( $scan_output, $audio, $count )
        = @par{ 'scan_output', 'audio', 'count' };

    my ($volume_rescale);
    ($volume_rescale) = $scan_output =~ /rescale=([\d.]+)/;

    return if $volume_rescale eq '';

    if ( $audio->volume_rescale > $volume_rescale || $count == 0 ) {
        $audio->set_scan_output($scan_output);
        $audio->set_volume_rescale($volume_rescale);
        $audio->set_tc_volume_rescale($volume_rescale);
    }

    1;
}

sub analyze_lsdvd {
    my $class = shift;
    my %par   = @_;
    my ( $probe_output, $project, $cb_title_probed )
        = @par{ 'probe_output', 'project', 'cb_title_probed' };

    $probe_output =~ s/EXECFLOW_OK//;
    $probe_output =~ s/^our//;

    my %lsdvd;
    eval $probe_output;
    die "Error compiling lsdvd output: $@. Output was:\n$probe_output" if $@;

    my %titles;
    $project->content->set_titles( \%titles );

    foreach my $track ( @{ $lsdvd{track} } ) {
        my $title = $titles{ $track->{ix} } = Video::DVDRip::Title->new(
            nr      => $track->{ix},
            project => $project,
        );

        my @audio_tracks;
        foreach my $audio ( @{ $track->{audio} } ) {
            push @audio_tracks,
                Video::DVDRip::Audio->new(
                title           => $title,
                type            => $audio->{format},
                lang            => $audio->{langcode},
                channels        => $audio->{channels},
                sample_rate     => $audio->{frequency},
                tc_nr           => $audio->{ix} - 1,
                tc_target_track => ( $audio->{ix} == 1 ? 0 : -1 ),
                tc_audio_codec  => "mp3",
                tc_bitrate      => 128,
                tc_mp3_quality  => 0,
                tc_samplerate   => $audio->{frequency},
                );
        }

        my %subtitles;
        foreach my $sub ( @{ $track->{subp} } ) {
            my $sid = hex( $sub->{streamid} ) - 32;
            $subtitles{$sid} = Video::DVDRip::Subtitle->new(
                id    => $sid,
                lang  => $sub->{langcode},
                title => $title,
            );
        }

        my %chapter_frames;
        foreach my $chap ( @{ $track->{chapter} } ) {
            $chapter_frames{ $chap->{ix} }
                = int( $chap->{length} * $track->{fps} );
        }

        $track->{aspect} =~ s!/!:!;
        $title->set_width( $track->{width} );
        $title->set_height( $track->{height} );
        $title->set_aspect_ratio( $track->{aspect} );
        $title->set_video_mode( lc( $track->{format} ) );
        $title->set_letterboxed( $track->{df} eq 'Letterbox' );
        $title->set_frames( int( $track->{length} * $track->{fps} ) );
        $title->set_runtime( int( $track->{length} + 0.5 ) );
        $title->set_frame_rate( "$track->{fps}" );
        $title->set_chapters( scalar( @{ $track->{chapter} } ) );
        $title->set_viewing_angles( $track->{angles} );
        $title->set_audio_channel( @audio_tracks ? 0 : -1 );

        $title->set_audio_tracks( \@audio_tracks );
        $title->set_subtitles( \%subtitles );
        $title->set_chapter_frames( \%chapter_frames );
        $title->set_selected_subtitle_id(0) if @{ $track->{subp} };

        $title->suggest_transcode_options;

        &$cb_title_probed($title) if $cb_title_probed;
    }

    1;
}

1;

