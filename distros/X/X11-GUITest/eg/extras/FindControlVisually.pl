#!/usr/bin/perl
#-----------------------------------------------------------------------------#
# X11::GUITest ($Id: FindControlVisually.pl 253 2026-08-19 22:37:51Z ctrondlp $)
# Notes: Example of script to locate a widget/control visually using an
#        image baseline.  Uses ImageMagick's 'compare' and 'convert'
#        command-line tools (part of the imagemagick package) rather than
#        a dedicated CPAN subimage-search module -- the couple that exist
#        (Image::SubImageFind, Image::Match) have both been unmaintained
#        for over a decade, while ImageMagick itself is actively developed.
#-----------------------------------------------------------------------------#

## Pragmas/Directives/Diagnostics ##
use strict;
use warnings;

## Imports (use [MODULE] qw/[IMPORTLIST]/;) ##
use File::Temp qw/:POSIX/;
use X11::GUITest qw/
	MoveMouseAbs
	ClickMouseButton
	:CONST
/;

## Constants (sub [CONSTANT]() { [VALUE]; }) ##
# Normalized RMSE distortion (0 = perfect match, 1 = no similarity at all)
# at or below which a match is accepted.  Tune to taste -- a baseline
# image with more size/detail and less repetitive background allows a
# lower/stricter threshold.
use constant MATCH_THRESHOLD => 0.15;

## Variables (my [SIGIL][VARIABLE] = [INITIALVALUE];) ##

## Core ##
print "$0 : Script Start\n";

print "Locating the control...\n";
# Find the control on-screen using baseline image to compare to
my ($x, $y) = FindScreenObject('/test/but_superscript.png');
if ($x >= 0 && $y >= 0) {
	print "Found at $x X $y\n";
	#MoveMouseAbs $x, $y;
	#ClickMouseButton M_LEFT;
} else {
	print "Not found\n";
}

print "$0 : Script End (Success)\n";

## Subroutines ##
sub FindScreenObject {
	my $baseline = shift; # baseline sub-image/clip to find on screen
	my $maxwait = shift || 30; # seconds to wait for discovery

	if (!-e $baseline) {
		die("Baseline $baseline image does not exist");
	}

	for (my $i = 1; $i <= $maxwait; $i++) {
		# Results may vary, depending on baseline quality and detail, etc.
		# In general, a larger (50x50 pixels) baseline with good detail will fair good.
		my $scrfile = GetScreenshot();
		my ($x, $y) = FindSubImage($scrfile, $baseline);
		unlink $scrfile;
		if ($x >= 0 && $y >= 0) {
			return ($x, $y);
		}
		sleep(1);
	}
	return (-1, -1);
}

# Uses ImageMagick's 'compare -subimage-search' to locate $baseline within
# $scrfile.  Returns the top-left (x, y) of the best match, or (-1, -1) if
# no match at or under MATCH_THRESHOLD was found.
sub FindSubImage {
	my ($scrfile, $baseline) = @_;

	my $diff = tmpnam();
	my $output = `compare -metric RMSE -subimage-search '$scrfile' '$baseline' '$diff' 2>&1`;
	unlink $diff;

	# compare's stderr looks like: "7842.99 (0.119679) @ 351,127"
	if ($output =~ /\(([\d.]+)\)\s*\@\s*(\d+)\s*,\s*(\d+)/) {
		my ($distortion, $mx, $my) = ($1, $2, $3);
		return ($distortion <= MATCH_THRESHOLD) ? ($mx, $my) : (-1, -1);
	}
	return (-1, -1);
}

sub GetScreenshot {
	my $file = tmpnam();
	system("xwd -root | convert xwd:- '$file'");
	return $file;
}
