#!/usr/bin/perl

# bin/peekvideo
#  Determine information about a given media file
#
# $Id: peekvideo.pl 9530 2009-10-04 04:37:16Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Pod::Usage;

use Video::Info;
use Video::FourCC::Info;

=head1 NAME

peekvideo - determine a codec used by a given file

=head1 VERSION

Version 1.1 ($Id: peekvideo.pl 9530 2009-10-04 04:37:16Z FREQUENCY@cpan.org $)

=cut

use version; our $VERSION = qv('1.1');

=head1 SYNOPSIS

Usage: peekvideo.pl filename [...]

Given a single path referring to a file containing video data, this script
will determine the codec required for the media to play.

=head1 DESCRIPTION

This is a simple script that determines information such as the common name
of the codec required for the given media to play. It is convenient to use
for troubleshooting video files that do not play for one reason or another.

=cut

my @files = @ARGV;

# if no parameters are passed, give usage information
unless (@files) {
  pod2usage(msg => 'Please supply at least one filename to analyze');
  exit();
}

foreach my $file (@files) {
  my $video;
  eval {
    $video = Video::Info->new(-file => $file);
  };
  if ($@) {
    printf {*STDERR} "Problem determining information about '%s':\n", $file;
    print 'In Video::Info: ', $@;
    next;
  }

  # Check if we have a FourCC
  unless (length($video->vcodec) == 4) {
    printf {*STDERR} "Video::Info returns '%s', which is not a FourCC\n",
      $video->vcodec;
    next;
  }

  my $codec;
  eval {
    $codec = Video::FourCC::Info->new($video->vcodec);
  };
  if ($@) {
    printf {*STDERR} "Codec '%s' is unregistered or unknown\n",
      $video->vcodec;
    next;
  }

  printf "File '%s' uses codec '%s': \n", $file, $video->vcodec;

  # Check if we have description entity information
  if (defined $codec->description) {
    printf "  Description:   %s\n", $codec->description;
  }

  # Check if we have owner entity information
  if (defined $codec->owner) {
    printf "  Registered by: %s\n", $codec->owner;
  }

  # Check if we have registration date information
  if (defined $codec->registered) {
    print '  Registered on: ';
    if (ref($codec->registered)) {
      ## no critic(ProhibitNoisyQuotes)
      # this is incorrectly reported as a noisy quote
      print $codec->registered->ymd('-');
    }
    else {
      print $codec->registered;
    }
    print "\n";
  }

  # Other information from Video::Info
  printf "  Dimensions:    %d x %d\n", $video->width, $video->height;
  printf "  Duration:      %s\n", $video->MMSS;
  printf "  Picture:       %d frames at %.2f frames/sec\n",
    $video->vframes, $video->fps;
  printf "  Audio:         %s, %d kbps at %d Hz\n", $video->acodec,
    $video->arate / 1000, $video->afrequency;
}

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 SUPPORT

For support details, please look at C<perldoc Video::FourCC::Info> and
use the corresponding support methods.

=head1 LICENSE

This has the same copyright and licensing terms as L<Video::FourCC::Info>.

=head1 SEE ALSO

L<Video::Info>,
L<Video::FourCC::Info>

=cut
