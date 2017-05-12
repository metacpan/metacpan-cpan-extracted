# $Id$

package Win32::GUIRobot;

use strict;
use warnings;
use Prima;
use Prima::Application;
use Time::HiRes qw(time);

our $VERSION = 0.05;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	ScreenGrab ScreenDepth ScreenWidth ScreenHeight
	LoadImage   ImageDepth  ImageWidth  ImageHeight
	FindImage   WaitForImage

	Sleep
	CloseWindow Rect2OffsetSize
	SendMouseClick MouseMove MouseMoveRel
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
if ( $^O =~ /win32|cygwin/i) {
	eval "use Win32::GuiTest qw(:ALL);";
	die $@ if $@;
	push @EXPORT_OK, @Win32::GuiTest::EXPORT_OK;
}


my %mouse_buttons = (
	Left   => [ \&SendLButtonDown, \&SendLButtonUp ],
	Middle => [ \&SendMButtonDown, \&SendMButtonUp ],
	Right  => [ \&SendRButtonDown, \&SendRButtonUp ],
);

our $EventDelay = 0.1;

sub LoadImage    { Prima::Image-> load( @_ ) }
sub ImageDepth   { shift-> type & im::BPP  }
sub ImageWidth   { shift-> width  }
sub ImageHeight  { shift-> height }
sub ScreenDepth  { $::application-> get_image(0,0,1,1)-> type & im::BPP }
sub ScreenWidth  { $::application-> width }
sub ScreenHeight { $::application-> height }
sub Sleep        { select ( undef, undef, undef, $_[0] || $EventDelay ) }
sub CloseWindow  { PostMessage( $_[0], 16, 0, 0) }
sub Rect2OffsetSize { $_[0], $_[1], $_[2] - $_[0], $_[3] - $_[1] }

sub ScreenGrab
{
	my @rect;
	if ( 4 == @_) {
		@rect = ( 
			$_[0], $::application-> height - $_[1] - $_[3],
			$_[2], $_[3],
		);
	} elsif ( 0 == @_) {
		@rect = (0,0,$::application-> size);
	} else {
		die "ScreenGrab ([X,Y,W,H])";
	}

	return $::application-> get_image( @rect);
}

sub FindImage
{
	my ( $image, $subimage) = @_;

	if ( ref($subimage) eq 'ARRAY') {
		for ( my $i = 0; $i < @$subimage; $i++) {
			my ( $x, $y) = FindImage( $image, $subimage->[$i]);
			return ( $x, $y, $i) if defined $x;
		}
		return;
	}

	my $G   = $image-> data;
	my $I   = $subimage-> data;
	my $W   = $image-> width;
	my $w   = $subimage-> width;

	my $bpp = ($subimage-> type & im::BPP) / 8;

	die "won't do images with less than 256 colors"
		if $bpp < 0;
	die "won't do images with different depth"
		if $subimage-> type != $image-> type;

	my $gw  = int(( $W * ( $image->    type & im::BPP) + 31) / 32) * 4;
	my $iw  = int(( $w * ( $subimage-> type & im::BPP) + 31) / 32) * 4;
	my $ibw = $w * $bpp;
	my $dw  = $gw - $ibw;
	
	my $rx  = join( ".{$dw}", map { quotemeta substr( $I, $_ * $iw, $ibw) } 
		(0 .. $subimage-> height - 1));
	my $D = 0;
	my ( $x, $y);
	while ( 1) {
		study $G;
		return unless $G =~ m/$rx/gs;
		$x = ( $D + pos($G)) % $gw / $bpp;
		last if $x >= $w;
		# handle scanline wraps, -- very unlikely, but still
		$D += pos($G);
		substr( $G, pos($G)) = '';
	}
	$y = int(( $D + pos($G)) / $gw) + 1;
	return ( $x - $w, $image-> height - $y);
}

sub SendMouseClick
{
	my ( $x, $y, $button, $delay) = @_;

	$button ||= 'Left';

	die "No such mouse button '$button'" unless $mouse_buttons{$button};

	MouseMoveAbsPix( $x, $y); 
	Sleep( $delay);
	$mouse_buttons{$button}-> [0]-> ();
	Sleep( $delay);
	$mouse_buttons{$button}-> [1]-> ();
	Sleep( $delay);
}

sub MouseMove
{
	my ( $x, $y, $sleep) = @_;

	MouseMoveAbsPix( $x, $y);
	Sleep( $sleep);
}

sub MouseMoveRel
{
	my ( $x, $y, $sleep) = @_;

	MouseMoveRelPix( $x, $y);
	Sleep( $sleep);
}

sub WaitForImage
{
	my ( $subimage, %options) = @_;

	my @rect;
	
	if ($options{window}) {
		@rect = Rect2OffsetSize( GetWindowRect( $options{window} ));
	} elsif ( $options{rect}) {
		@rect = @{$options{rect}};
	} else {
		@rect = (0, 0, $::application-> size);
	}

	$options{maxwait} ||= 0;
	$options{maxwait} += time;

	my $grab;
	while ( 1) {
		$grab = ScreenGrab( @rect);
		last unless $grab;

		my ( $x, $y, $idx) = FindImage( $grab, $subimage);
		return {
			ok   => 1,
			x    => $x + $rect[0],
			y    => $y + $rect[1],
			idx  => $idx
		} if defined $x;

		last if time > $options{maxwait};

		Sleep( $options{sleep} );
	}

	return { grab => $grab } ;
}


1;

__DATA__

=pod

=head1 NAME

Win32::GUIRobot - send keyboard and mouse input to win32, analyze graphical output

=head1 DESCRIPTION

The module is a superset of C<Win32::GuiTest> module functionality, with
addition of simple analysis of graphic output. The module is useful where
analysis based on enumeration of window by title, class, etc is not enough (in
particular in Citrix environment), by providing searching of arbitrary graphic
bits on the screen.

The module is a mixed bag of various win32 functions with the same purpose as
C<Win32::GuiTest> - to provide environment for batch windows GUI tests/macros,
but also focusing on code logic reuse when many similar GUI scripts should be
written. Therefore, in addition to image search, the module also features a set
of wrapper functions to win32 API, timers, etc.

=head1 IMAGING

Image operations, -- loading, retrieving information etc is based on L<Prima>,
which can work not only on win32, so the module can be of limited use on X11,
for searching sub-images in images and grabbing the screen. Possibly this
functionality is worth releasing as a stand-alone module, but OTOH the image
search is not limited to C<Prima> toolkit, and can be trivially implemented
using any other image system, not to say that the searching algorithm itself is
very simple, and being abstracted from image toolkit calls, is a single regexp.

Functions collected below are little more than aliases to C<Prima> methods, but
for the sake of consistency, and in case C<Prima> will be replaced by some
other toolkit, image methods are replaced by opaque method wrappers:

=over

=item ScreenDepth

Returns image depth of a screen dump.

=item ScreenWidth

Returns screen width

=item ScreenHeight

Returns screen height

=item LoadImage $FILENAME

Loads image from $FILENAME, returns image object.

=item ScreenGrab [ $X, $Y, $WIDTH, $HEIGHT ].

Grabs the screen, returns image object with the screen dump. If no parameters
given, grabs the whole screen, otherwise the area limited by the passed
coordinates.

=item ImageDepth $IMAGE

Returns $IMAGE color depth

=item ImageWidth $IMAGE

Returns $IMAGE width

=item ImageHeight $IMAGE

Returns $IMAGE height

=item FindImage $IMAGE, $SUBIMAGE

Searches position of $SUBIMAGE in $IMAGE, reports coordinate if found, empty
list otherwise. $SUBIMAGE can be an array of images, in which case, coordinates
of first found image is reported, and the index of the image found is returned
as a third value. Since C<FindImage> is called within C<WaitForImage>,
the latter can also treat $SUBIMAGE as array of images.

=item WaitForImage $SUBIMAGE, %OPTIONS

Monitors area on the screen for $SUBIMAGE to appear by taking screenshots every
C<$OPTIONS{sleep}> seconds. Fails list when C<$OPTIONS{maxwait}> expires, succeeds
and returns (x,y) coordinates where $SUBIMAGE was found otherwise.

The monitored area is can be selected either by specifying C<$OPTIONS{window}>
in which case the window area is tracked, or by speciying explicit C<$OPTIONS{rect}>
which is a 4-integer (X,Y,WIDTH,HEIGHT) rectangle, or by not specifying anything,
in which case the whole screen is monitored.

Returns a hash reference, which contains C<ok> boolean success flag, C<x> and C<y>
coordinated and an optional C<idx> image index (see third value in C<FindImage>).
Also, C<grab> in the hash points to the last analyzed screenshot.

=item Rect2OffsetSize $LEFT, $TOP, $RIGHT, $BOTTOM

Converts win32 RECT(left,top,right,bottom) into OffsetSize(left,top,width,height).
Useful for constructions like

   $grab = ScreenGrab( Rect2OffsetSize( GetWindowRect( $HWND)));

=back

=head1 OTHER FUNCTIONS

=over

=item Sleep [ $SECONDS = DEFAULT_SECONDS ]

Sleeps given amount of seconds, or 0.02 by default.

=item SendMouseClick $BUTTON, $X, $Y, [ $SLEEP_BETWEEN_EVENTS ]

Positions mouse cursor over $X, $Y, sleeps some time, then
sends button down event, sleeps again, then button up event
and sleeps again.

=item MouseMove $X, $Y

Moves mouse cursor to $X, $Y

=item MouseMoveRel $X, $Y

Moves mouse cursor to $X, $Y relatively to the old cursor position

=item CloseWindow $HWND

Sends close signal to a window.

=back

=head1 BUGS

I didn't try image search on 8-bit paletted displays -- beware.

Prima coordinates ( images included ) is defined so Y axis grows upwards, whereas
in win32 screen coordinates, Y axis grows downwards. The wrapper methods take care
of the coordinate conversion, however if you need to call Prima methods, beware of 
this difference.

=head1 SEE ALSO

L<Prima>, L<Win32::GuiTest>, L<Win32::Capture>, L<Win32::Snapshot>,
L<Win32::GUI::DIBitmap>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 capmon ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dmitry@karasik.eu.org>

=cut
