#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip;
use Locale::TextDomain qw (video.dvdrip);

BEGIN {
    $VERSION = "0.98.11";
}

use base Video::DVDRip::Base;

use Carp;
use FileHandle;
require 5.006;

%Video::DVDRip::container_formats = (
	'avi'       => "AVI",
	'ogg'       => "OGG",
	'vcd'       => "MPEG",
);

@Video::DVDRip::deinterlace_filters = (
	0          => __"No deinterlacing",
	1          => __"Interpolate scanlines (fast)",
	2          => __"Handled by encoder (may segfault)",
	3          => __"Zoom to full frame (slow)",
	5          => __"Interpolate scanlines / blend frames (pp=lb)",
	'32detect' => __"Automatic deinterlacing of single frames",
	'smart'    => __"Smart deinterlacing",
	'ivtc'     => __"Inverse telecine",
);

%Video::DVDRip::antialias_filters = (
	0 => __"No antialiasing",
	1 => __"Process de-interlace effects",
	2 => __"Process resize effects",
	3 => __"Process full frame (slow)",
);

%Video::DVDRip::audio_filters = (
	'rescale'   => __"None, volume rescale only",
	'a52drc'    => __"Range compression (liba52 filter)",
	'normalize' => __"Normalizing (mplayer filter)",
);

1;

__END__

=head1 NAME

Video::DVDRip - GUI for copying DVDs, based on an open Low Level API

=head1 DESCRIPTION

This Perl module consists currently of two major components:

  1. A low level OO style API for ripping and transcoding
     DVD video, which is based on Thomas Oestreichs program
     transcode, a Linux Video Stream Processing Tool.
     This API is currently well undocumented.

  2. A Gtk+ based Perl program called 'dvd::rip' which provides
     a nice GUI to control all necessary steps from ripping,
     adjusting all parameters and transcoding the video to
     the format you desire.

The distribution name is derived from the Perl namespace it occupies:
Video::DVDRip. Although the DVD Ripper GUI is called dvd::rip, because
it's shorter and easier to pronounce (if you omit the colons... ;)

You'll find all information regarding installation and usage of
dvd::rip in the README file shipped with the distribution or
on the dvd::rip homepage:

  http://www.exit1.org/dvdrip/

=head1 COPYRIGHT

Copyright (C) 2001-2002 by Joern Reder, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
