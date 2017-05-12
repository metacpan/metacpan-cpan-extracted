# $Id: Progress.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Term::Progress;

use base qw( Video::DVDRip::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

my @rot = ( "|", "/", "-", "\\" );

sub rot_idx			{ shift->{rot_idx}			}
sub quiet			{ shift->{quiet}			}

sub set_quiet			{ shift->{quiet}		= $_[1]	}
sub set_rot_idx			{ shift->{rot_idx}		= $_[1]	}

sub new {
    my $class   = shift;
    my %par     = @_;
    my ($quiet) = @par{'quiet'};

    return bless { quiet => $quiet }, $class;
}

sub update {
    my $self = shift;
    my %par  = @_;
    my ( $value, $label ) = @par{ 'value', 'label' };

    return if $self->quiet;

    my ( $info, $percent ) = split( ":", $label, 2 );

    my $width = 76;
    my $cnt   = int( $width * $value );
    $cnt = $width if $cnt > $width;

    my $rot_idx = $self->rot_idx;
    my $rot     = $rot[$rot_idx];
    ++$rot_idx;
    $rot_idx = 0 if $rot_idx == @rot;
    $self->set_rot_idx($rot_idx);

    my $clean = chr(27) . "[K";
    my $up    = chr(27) . "[1A";
    my $yel   = chr(27) . "[33m";
    my $bgw   = chr(27) . "[47m";
    my $reset = chr(27) . "[0m";
    my $bld   = chr(27) . "[1m";
    my $rev   = chr(27) . "[30;47;1m";
    my $prg   = chr(27) . "[30;42m";

    my $progress = "[$prg"
        . ( "·" x $cnt )
        . $reset
        . ( "·" x ( $width - $cnt ) ) . "]";

    $rot = "$rev$rot$reset";
    $rot = ">" if $cnt == $width;

    #-- some intelligence for l10n to align the words
    #-- "Job" and "Progress" properly
    my $word_job = __("Job") . ":";
    my $word_prg = __("Progress") . ":";

    my $len_job = length($word_job);
    my $len_prg = length($word_prg);

    my $max = $len_job > $len_prg ? $len_job : $len_prg;

    $word_job = sprintf( "%-${max}s", $word_job );
    $word_prg = sprintf( "%-${max}s", $word_prg );

    print "\r$rot $progress$clean\n";
    print "\r  ${yel}$word_job${reset}  $bld$info$reset$clean\n";
    print "\r  ${yel}$word_prg${reset} $bld$percent$reset$clean\n\r$up$up$up";

    1;
}

sub is_active {
    0;
}

sub open {
    1;
}

sub close {
    my $self = shift;
    return if $self->quiet;
    print "\n\n\n\n";
    1;
}

1;
