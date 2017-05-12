# $Id: Convert.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Convert;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;

sub convert_audio_tracks_0_45_04 {
    my $class     = shift;
    my %par       = @_;
    my ($project) = @par{'project'};

    print "[auto-conversion] Import audio configuration (0.45_04)\n";

    print "\nSorry, this version can't convert such old files.\n";
    print "If you really need this file, install dvd::rip < 0.49 first\n";
    print "and convert the file. Then upgrade dvd::rip again and\n";
    print "you should be able to convert and use the file.\n\n";

    exit 1;

    1;
}

sub set_audio_bitrates_0_47_02 {
    my $class     = shift;
    my %par       = @_;
    my ($project) = @par{'project'};

    print
        "[auto-conversion] Setting new audio bitrate attributes (0.47_02)\n";

    foreach my $title ( values %{ $project->content->titles } ) {
        my $audio_info = $title->audio_tracks;
        next if not $audio_info;
        my $i = 0;
        foreach my $audio ( @{ $title->{tc_audio_tracks} } ) {
            $audio->{tc_mp2_bitrate} = $audio->{tc_bitrate};
            $audio->{tc_mp3_bitrate} = $audio->{tc_bitrate};
            $audio->{tc_ogg_bitrate} = $audio->{tc_bitrate};
            $audio->{tc_ac3_bitrate} = $audio_info->[$i]->bitrate;
            ++$i;
        }
    }

    1;
}

sub convert_container_0_49_1 {
    my $class     = shift;
    my %par       = @_;
    my ($project) = @par{'project'};

    print
        "[auto-conversion] Converting container, vorbis, manual attributes (0.49.1)\n";

    foreach my $title ( sort { $a->nr <=> $b->nr }
        values %{ $project->content->titles } ) {

        # convert 'ogg' codec to 'vorbis' (incl. bitrate setting)
        foreach my $audio_track ( @{ $title->{tc_audio_tracks} } ) {
            if ( $audio_track->{tc_audio_codec} eq 'ogg' ) {
                $audio_track->{tc_audio_codec} = 'vorbis';
            }
            my $ogg_bitrate = delete $audio_track->{tc_ogg_bitrate};
            $audio_track->{tc_vorbis_bitrate} = $ogg_bitrate
                if $ogg_bitrate;
            $audio_track->{tc_vorbis_quality}        = 3.00;
            $audio_track->{tc_vorbis_quality_enable} = 0;
        }

        # set samplerate to probed value
        my $i          = 0;
        my $audio_info = $title->audio_tracks;
        foreach my $audio ( @{ $title->{tc_audio_tracks} } ) {
            ++$i, next if not defined $audio_info->[$i];
            $audio->{tc_vorbis_samplerate} = $audio_info->[$i]->sample_rate;
            $audio->{tc_mp3_samplerate}    = $audio_info->[$i]->sample_rate;
            ++$i;
        }

        # set container attribute
        my $container = $title->tc_video_codec =~ /S?VCD/ ? "vcd" : "avi";
        if ( $container eq 'avi' ) {
            $container = "ogg"
                if $title->get_first_audio_track >= 0
                and
                $title->{tc_audio_tracks}->[ $title->get_first_audio_track ]
                ->{tc_audio_codec} eq 'vorbis';
        }

        $title->set_tc_container($container);
        $title->set_tc_video_bitrate_manual(1);

    }

    1;
}

sub convert_0_49_2 {
    my $class     = shift;
    my %par       = @_;
    my ($project) = @par{'project'};

    print
        "[auto-conversion] Converting title and audio attributes (0.49.2)\n";

    foreach my $title ( sort { $a->nr <=> $b->nr }
        values %{ $project->content->titles } ) {

        # 1. no probe_result object anymore
        my $probe_result = delete $title->{probe_result};
        next if not defined $probe_result;
        $title->set_width( $probe_result->{width} );
        $title->set_height( $probe_result->{height} );
        $title->set_aspect_ratio( $probe_result->{aspect_ratio} );
        $title->set_video_mode( $probe_result->{video_mode} );
        $title->set_letterboxed( $probe_result->{letterboxed} );
        $title->set_frames( $probe_result->{frames} );
        $title->set_runtime( $probe_result->{runtime} );
        $title->set_frame_rate( $probe_result->{frame_rate} );
        $title->set_chapters( $probe_result->{chapters} );
        $title->set_viewing_angles( $probe_result->{viewing_angles} );
        $title->set_dvd_probe_output( $probe_result->{probe_output} );
        $title->set_vob_probe_output( $probe_result->{audio_probe_output} );

        delete $title->{scan_result};

        # 2. no ProbeAudio object anymore, merged into Audio (tc_audio_tracks)
        my $tc_audio_tracks = delete $title->{tc_audio_tracks};
        my $audio_tracks    = $probe_result->audio_tracks;

        my $i = 0;
        foreach my $audio ( @{$tc_audio_tracks} ) {
            $audio->set_type( $audio_tracks->[$i]->{type} );
            $audio->set_lang( $audio_tracks->[$i]->{lang} );
            $audio->set_channels( $audio_tracks->[$i]->{channels} );
            $audio->set_bitrate( $audio_tracks->[$i]->{bitrate} );
            $audio->set_sample_rate( $audio_tracks->[$i]->{sample_rate} );
            $audio->set_volume_rescale(
                $audio_tracks->[$i]->{volume_rescale} );
            $audio->set_scan_output(
                $audio_tracks->[$i]->{scan_result}->{scan_output} );
            delete $audio_tracks->[$i]->{scan_result};
            ++$i;
        }

        $title->set_audio_tracks($tc_audio_tracks);

        $title->set_subtitles( {} ) if not $title->subtitles;
    }

    1;
}

1;
