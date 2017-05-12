# $Id: SrtxFile.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::SrtxFile;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;

use FileHandle;

sub get_filename                { shift->{filename}                     }
sub get_fh                      { shift->{fh}                           }

sub set_filename                { shift->{filename}             = $_[1] }
sub set_fh                      { shift->{fh}                   = $_[1] }

sub new {
    my $class      = shift;
    my %par        = @_;
    my ($filename) = @par{'filename'};

    my $self = bless {
        filename => $filename,
        fh       => FileHandle->new,
    }, $class;

    return $self;
}

sub set_filename_from_dir {
    my $self     = shift;
    my ($dir)    = @_;
    my $filename = ( glob("$dir/{*.srtx,.*srtx}") )[0];
    return $self->set_filename($filename);
}

sub open {
    my $self = shift;

    my $fh       = $self->get_fh;
    my $filename = $self->get_filename;

    open( $fh, $filename ) or die "can't read $filename";

    1;
}

sub close {
    my $self = shift;

    close( $self->get_fh );

    1;
}

sub read_entry {
    my $self = shift;

    my $fh = $self->get_fh;

    chomp( my $nr         = <$fh> );
    chomp( my $time       = <$fh> );
    chomp( my $image_file = <$fh> );
    <$fh>;

    return
        unless defined $nr
        and defined $time
        and defined $image_file;

    $image_file =~ s/\.pgm\.txt$//;

    if ( -f "$image_file.pgm" ) {
        $image_file .= ".pgm";
    }
    elsif ( -f "$image_file.png" ) {
        $image_file .= ".png";
    }
    else {
        $image_file = undef;
    }

    return Video::DVDRip::SrtxFileEntry->new(
        nr         => $nr,
        time       => $time,
        image_file => $image_file,
    );
}

package Video::DVDRip::SrtxFileEntry;

sub get_nr                      { shift->{nr}                           }
sub get_time                    { shift->{time}                         }
sub get_time_sec                { shift->{time_sec}                     }
sub get_image_file              { shift->{image_file}                   }

sub set_nr                      { shift->{nr}                   = $_[1] }
sub set_time                    { shift->{time}                 = $_[1] }
sub set_time_sec                { shift->{time_sec}             = $_[1] }
sub set_image_file              { shift->{image_file}           = $_[1] }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $nr, $time, $image_file ) = @par{ 'nr', 'time', 'image_file' };

    ($time) = $time =~ /^(\d\d:\d\d:\d\d)/;
    $time =~ /^(\d\d):(\d\d):(\d\d)/;

    my $time_sec = $3 + $2 * 60 + $1 * 3600;

    my $self = bless {
        nr         => $nr,
        time       => $time,
        time_sec   => $time_sec,
        image_file => $image_file,
    }, $class;

    return $self;
}

1;
