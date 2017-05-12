# $Id: Subtitle.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Subtitle;

use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Video::DVDRip::SrtxFile;

use Carp;
use strict;

sub title                       { shift->{title}                        }
sub id                          { shift->{id}                           }
sub lang                        { shift->{lang}                         }
sub tc_preview_img_cnt          { shift->{tc_preview_img_cnt}           }
sub tc_preview_timecode         { shift->{tc_preview_timecode}          }
sub tc_vobsub                   { shift->{tc_vobsub}                    }
sub tc_render                   { shift->{tc_render}                    }
sub tc_vertical_offset          { shift->{tc_vertical_offset}           }
sub tc_time_shift               { shift->{tc_time_shift}                }
sub tc_postprocess              { shift->{tc_postprocess}               }
sub tc_antialias                { shift->{tc_antialias}                 }
sub tc_color_manip              { shift->{tc_color_manip}               }
sub tc_color_a                  { shift->{tc_color_a}                   }
sub tc_color_b                  { shift->{tc_color_b}                   }
sub tc_assign_color_a           { shift->{tc_assign_color_a}            }
sub tc_assign_color_b           { shift->{tc_assign_color_b}            }
sub tc_test_image_cnt           { shift->{tc_test_image_cnt}            }

sub set_title                   { shift->{title}                = $_[1] }
sub set_id                      { shift->{id}                   = $_[1] }
sub set_lang                    { shift->{lang}                 = $_[1] }
sub set_tc_preview_img_cnt      { shift->{tc_preview_img_cnt}   = $_[1] }
sub set_tc_preview_timecode     { shift->{tc_preview_timecode}  = $_[1] }
sub set_tc_vobsub               { shift->{tc_vobsub}            = $_[1] }
sub set_tc_render               { shift->{tc_render}            = $_[1] }
sub set_tc_vertical_offset      { shift->{tc_vertical_offset}   = $_[1] }
sub set_tc_time_shift           { shift->{tc_time_shift}        = $_[1] }
sub set_tc_postprocess          { shift->{tc_postprocess}       = $_[1] }
sub set_tc_antialias            { shift->{tc_antialias}         = $_[1] }
sub set_tc_color_manip          { shift->{tc_color_manip}       = $_[1] }
sub set_tc_color_a              { shift->{tc_color_a}           = $_[1] }
sub set_tc_color_b              { shift->{tc_color_b}           = $_[1] }
sub set_tc_assign_color_a       { shift->{tc_assign_color_a}    = $_[1] }
sub set_tc_assign_color_b       { shift->{tc_assign_color_b}    = $_[1] }
sub set_tc_test_image_cnt       { shift->{tc_test_image_cnt}    = $_[1] }
sub set_ripped_images_cnt       { shift->{ripped_images_cnt}    = $_[1] }

sub ripped_images_cnt {
    my $self = shift;

    return $self->{ripped_images_cnt}
        if $self->{ripped_images_cnt};

    my $dir = $self->preview_dir;

    my @files = glob("$dir/*.{pgm,png}");
    my $cnt   = @files;

    $self->{ripped_images_cnt} = $cnt;

    return $cnt;
}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $id, $lang, $tc_preview_img_cnt, $tc_preview_timecode )
        = @par{ 'id', 'lang', 'tc_preview_img_cnt', 'tc_preview_timecode' };
    my ( $tc_vobsub, $tc_render, $tc_vertical_offset, $tc_time_shift )
        = @par{ 'tc_vobsub', 'tc_render', 'tc_vertical_offset',
        'tc_time_shift' };
    my ( $tc_antialias, $tc_color_a, $tc_color_b, $tc_assign_color_a )
        = @par{ 'tc_antialias', 'tc_color_a', 'tc_color_b',
        'tc_assign_color_a' };
    my ( $tc_assign_color_b, $tc_test_image_cnt, $title, $tc_color_manip )
        = @par{
        'tc_assign_color_b', 'tc_test_image_cnt',
        'title',             'tc_color_manip'
        };
    my ($tc_postprocess) = @par{'tc_postprocess'};

    $tc_preview_img_cnt  = 20         if not defined $tc_preview_img_cnt;
    $tc_preview_timecode = "00:00:00" if not defined $tc_preview_timecode;

    $tc_test_image_cnt  ||= 1;
    $tc_color_a         ||= 0;
    $tc_color_b         ||= 0;
    $tc_assign_color_a  ||= 0;
    $tc_assign_color_b  ||= 0;
    $tc_antialias       ||= 1;
    $tc_vertical_offset ||= 0;
    $tc_time_shift      ||= 0;
    $tc_color_manip     ||= 0;
    $tc_postprocess     ||= 0;

    my $self = {
        title               => $title,
        id                  => $id,
        lang                => $lang,
        tc_preview_img_cnt  => $tc_preview_img_cnt,
        tc_preview_timecode => $tc_preview_timecode,
        tc_vobsub           => $tc_vobsub,
        tc_render           => $tc_render,
        tc_vertical_offset  => $tc_vertical_offset,
        tc_time_shift       => $tc_time_shift,
        tc_postprocess      => $tc_postprocess,
        tc_antialias        => $tc_antialias,
        tc_color_manip      => $tc_color_manip,
        tc_color_a          => $tc_color_a,
        tc_color_b          => $tc_color_b,
        tc_assign_color_a   => $tc_assign_color_a,
        tc_assign_color_b   => $tc_assign_color_b,
        tc_test_image_cnt   => $tc_test_image_cnt,
    };

    return bless $self, $class;
}

sub info {
    my $self = shift;

    my $lang = $self->lang;
    $lang = "??" if $lang eq "<unknown>";

    if ( $self->is_ripped ) {
        my $cnt = $self->ripped_images_cnt;
        my $images = __x( "{cnt} images", cnt => $cnt );
        return sprintf( "%02d - %s - $images", $self->id, $lang, $cnt );
    }
    else {
        return sprintf( "%02d - %s", $self->id, $lang );
    }
}

sub vobsub_prefix {
    my $self      = shift;
    my %par       = @_;
    my ($file_nr) = @par{'file_nr'};

    my $title = $self->title;

    my $file = "";
    if ( defined $file_nr ) {
        if ( $self->title->is_ogg ) {
            $file = sprintf( "%06d-", $file_nr + 1 );
        }
        else {
            $file = sprintf( "%04d-", $file_nr );
        }
    }

    return sprintf( "%s-%03d-${file}sid%02d",
        $title->project->name, $title->nr, $self->id );
}

sub preview_dir {
    my $self = shift;

    return $self->title->get_subtitle_preview_dir( $self->id );
}

sub ifo_file {
    my $self = shift;
    my %par  = @_;
    my ($nr) = @par{'nr'};

    $nr ||= 0;

    my @ifo_files = glob( $self->title->project->ifo_dir . "/*" );
    $nr = 0 if $nr > @ifo_files - 1;

    return $ifo_files[$nr];
}

sub ps1_file {
    my $self = shift;

    return $self->title->project->snap_dir . "/"
        . $self->vobsub_prefix . ".ps1";
}

sub vobsub_file_exists {
    my $self = shift;

    my $mask
        = $self->title->avi_dir . "/" . $self->vobsub_prefix . ".{sub,rar}";
    my @files = glob($mask);

    return scalar(@files);
}

sub is_ripped {
    my $self = shift;

    return -f $self->preview_dir . "/.ripped";
}

sub get_first_entry {
    my $self = shift;
    
    my $srtx = Video::DVDRip::SrtxFile->new;
    $srtx->set_filename_from_dir ($self->preview_dir);

    $srtx->open;
    my $entry = $srtx->read_entry;
    $srtx->close;

    return $entry;
}

sub get_nth_entry {
    my $self = shift;
    my ($nr) = @_;

    my $srtx = Video::DVDRip::SrtxFile->new;
    $srtx->set_filename_from_dir ($self->preview_dir);

    $srtx->open;
    my $entry;
    while ( $entry = $srtx->read_entry ) {
        --$nr;
        last if $nr == 0;
    }
    $srtx->close;

    return if $nr != 0;
    return $entry;
}

package Video::DVDRip::Subtitle::PreviewImage;
use Locale::TextDomain qw (video.dvdrip);

sub nr       { shift->{nr} }
sub filename { shift->{filename} }
sub time     { shift->{time} }
sub height   { shift->{height} }
sub width    { shift->{width} }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $filename, $time, $nr ) = @par{ 'filename', 'time', 'nr' };

    my $catch = qx[identify -ping $filename 2>&1];
    my ( $width, $height );
    ( $width, $height ) = ( $catch =~ /(\d+)x(\d+)/ );

    my $self = {
        nr       => $nr,
        filename => $filename,
        time     => $time,
        height   => $height,
        width    => $width,
    };

    return bless $self, $class;
}

1;
