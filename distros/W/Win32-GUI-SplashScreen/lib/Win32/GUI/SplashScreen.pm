package Win32::GUI::SplashScreen;
# Copyright 2005..2009 Robert May, All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;
use warnings::register;

use Win32::GUI 1.02 qw(WS_CHILD WS_POPUP WS_EX_TOPMOST WS_EX_TOOLWINDOW);
use Win32::GUI::BitmapInline ();

BEGIN { eval "use Win32::GUI::DIBitmap ()"; };

=head1 NAME

Win32::GUI::SplashScreen - Win32::GUI SplashScreen support

=cut

our $VERSION = 0.04;
our $DEBUG=0;  # set to a true value to see console debugging info

our %INFO;     # package global information

=head1 SYNOPSIS

	use Win32:GUI::SplashScreen;

	Win32::GUI::SplashScreen::Show([%options]);

	Win32::GUI::SplashScreen::Done([$now]);

Win32::GUI::SplashScreen is a module that works with Win32::GUI
to implement a Windows application splash screen.

It can generate a simple splash screen from basic text information,
or use a supplied image.  The splash screen can be configured to
have a minimum display time (so that users always have time
to read any information), and can be taken down automatically
once your program reaches the dialog phase.

=cut

=head1 METHODS

=cut

######################################################################
# Public Show()
######################################################################

=head2 Show

	Win32::GUI::SplashScreen::Show(%options);

where C<%options> are:

=over

=item B<-file>

The file or resource name containing the splash image to load.  Defaults
to F<SPLASH>.  First attempt is to load the image from the running
executable as a resource - this is for people who have packaged their
GUI with perl2exe, PAR or some similar packaging tool.  If not found
as a resource, then attempts are made to find F<file> in the filesystem:
The script directory, the current directory and C<$ENV{PAR_TEMP}>
directories are searched for
F<file> with no extension, and with F<.bmp>, F<.jpg> and F<.jpeg>
extensions.  JPEG support is only available if Win32::GUI::DIBitmap
is available.

=item B<-mintime>

The minimum time for which the splash screen should be shown in seconds.
Defaults to 3 seconds.

=item B<-info>

If a user defined bitmap is not supplied, or not foound, then
Win32::GUI::SplashScreen generates it's own internal splash screen.
When doing this any text provided by the B<-info> option is drawn
in the top left corner of the splash screen.

=item B<-copyright>

If a user defined bitmap is not supplied, or not foound, then
Win32::GUI::SplashScreen generates it's own internal splash screen.
When doing this any text provided by the B<-copyright> option is drawn
in the top left corner of the splash screen, under any text provided
by the B<-info> option.

=back

If no other action is taken the splash screen will be taken down
automatically once B<-mintime> seconds have passsed and you have
entered the dialog phase.

Only one splash screen can be diaplayed at a time.

returns C<1> on success and C<0> on failure.

=cut

sub Show
{
	if (defined %INFO) {
		warnings::warnif("Can't have more than one SplashScreen at once");
		return 0;
	}

	my %options = @_;

	my $file         = exists($options{-file})      ? $options{-file}      : 'SPLASH';
	$INFO{mintime}   = exists($options{-mintime})   ? $options{-mintime}   : 3; # seconds
	$INFO{info}      = exists($options{-info})      ? $options{-info}      : "";
	$INFO{copyright} = exists($options{-copyright}) ? $options{-copyright} : "";

	my $splashimage = _LoadSplash($file);

	my %cOptions;
	if($splashimage) {
		$cOptions{-size} = [($splashimage->Info())[0,1]];
		$cOptions{-bitmap} = $splashimage;
		$INFO{bitmap} = $splashimage;
	}
	else {
		#$splashimage = _InternalBitmap();
		$cOptions{-size} = [480, 360];
	}

	#create the splash window, containing the bitmap
	my $splash = Win32::GUI::Label->new(
		-popstyle   => WS_CHILD,
		-addstyle   => WS_POPUP,
		-addexstyle => WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
		-background => 0xFFFFFF,
		-onTimer    => \&_Timer,
		%cOptions,
	);  
	$INFO{window} = $splash;

	#center the splash
	Win32::GUI::Window::Center($splash);

	$splash->Show();
	#call do events - not Dialog - this will display the window and let us 
	#build the rest of the application.
	$splash->DoEvents();
	_PaintInternal($splash) if(not defined $INFO{bitmap});

	# record the diaply time
	$INFO{dtime} = time;

	# set up a timer - if the main dialog loop is entered without
	# closing the splash screen, then we'll start to see events
	# and can use them to close down the splashscreen at the right
	# time.
	Win32::GUI::Timer->new($splash, "splashTimer", 250);

	return 1;
}

######################################################################
# Public Done()
######################################################################

=head2 Done

	Win32::GUI::SplashScreen::Done([$now]);

C<Done()> is a blocking call that waits until the B<-mintime> has
passed since the splash screen was displayed, and takes it down.

Perhaps more usefully, if called with a TRUE parameter, takes the
splash screen down NOW.

Returns C<1> on success and C<0> on failure (for example if there
is no splash screen showing currently).

=cut

sub Done
{
	return 0 unless defined %INFO; # error if no splashscreen displayed

	$INFO{mintime} = 0 if shift;   # take splash down NOW.

	# keep doing events until our object is cleaned up
	while (defined %INFO) {
		Win32::GUI::WaitMessage();
		$INFO{window}->DoEvents();
	}

	return 1;
}

######################################################################
# Private _Timer()
# Win32::GUI::Timer callback for processing timer messages: determines
#  if the time has come to take down the splash acreen and if so
#  releases all used resources.
######################################################################

sub _Timer
{
	my $splash = shift;
	my $timerName = shift;

	my $dtime  = $INFO{dtime};
	my $mintime = $INFO{mintime};

	print "Timer waiting for " . ($mintime - time + $dtime) . " more seconds\n" if $DEBUG;
	return 1 if (time - $dtime) < $mintime;

	# time elapsed, clean up
	print "Timer cleaning up\n" if $DEBUG;

	$splash->Hide();

	# kill the timer
	$splash->{$timerName}->Kill();

	# free all our resources
	undef %INFO;

	return 1;
}

######################################################################
# Private _PaintInternal()
# Paints text and icons onto the blank label
######################################################################

sub _PaintInternal
{
	my $splash = $INFO{window};

	# write some stuff onto the label
	my $DC = Win32::GUI::DC->new($splash);
	$DC->DrawEdge(0,0,$splash->Width(),$splash->Height());
	$DC->Rectangle(2,2,$splash->Width()-3,$splash->Height()-3);
	$DC->TextOut(10, 20, $INFO{info});
	$DC->TextOut(20, 40, $INFO{copyright});
	$DC->TextOut(10, 80, "Using Win32::GUI::Splashscreen v$VERSION");
	$DC->TextOut(20,100, "(c) 2005..2009 Robert May");
	$DC->TextOut(10,120, "Using Win32::GUI v$Win32::GUI::VERSION");
	$DC->TextOut(20,140, "(c) 1997..2005 Aldo Calpini; 2005..2009 Robert May");

	my $bitmap = _Win32GUIBitmap();

	my $memDC = $DC->CreateCompatibleDC();
	$memDC->SelectObject($bitmap);
	$DC->BitBlt($splash->Width()-100, $splash->Height()-100, ($bitmap->Info())[0,1], $memDC, 0, 0);
	$memDC->DeleteDC();

	return 1;
}

######################################################################
# Private _LoadSplash()
# Attempts to load a user provided image from for the splash screeen.
# First attempts to load the image as a win32 resource from the
# running executable, then tries the filesystem.  If available uses
# Win32::GUI::DIBitmap to enable JPEG support.
# Returns a Win32::GUI::Bitmap oject on success or undef on failure.
######################################################################

sub _LoadSplash
{
	my $base = shift;

    return undef unless defined $base;

	# try to load the splash bitmap as resource from the exe that is running
	# this will also get the image if it has a .bmp extension
	my $splashimage = Win32::GUI::Bitmap->new($base);
	return $splashimage if $splashimage;

	# attempt to load from filesystem

	# places to try:
	my @dirs;
	# directory of perl script
	my $tmp = $0; $tmp =~ s/[^\/\\]*$//;
	push @dirs, $tmp;
	# cwd
	push @dirs, ".";
	#try to load the splash image from the PAR_TEMP directory
	#  this is for exes built with PAR's pp -a xxxxx.bmp ...
	push @dirs, $ENV{PAR_TEMP}."/inc" if exists $ENV{PAR_TEMP};

	# try as a bitmap
	for my $dir (@dirs) {
		next unless -d $dir;
		print "Attempting to load splash image from $dir/$base.bmp\n" if $DEBUG;
		$splashimage = Win32::GUI::Bitmap->new("$dir/$base.bmp");
		return $splashimage if $splashimage;
	}

	# if we have DIBitmap available, try some other formats
	if(defined $Win32::GUI::DIBitmap::VERSION) {
		my @exts;
		push @exts, "";
		push @exts, ".jpg";
		push @exts, ".jpeg";

		for my $dir (@dirs) {
			next unless -d $dir;
			for my $ext (@exts) {
				print "Attempting to load splash image from $dir/$base$ext\n" if $DEBUG;
				my $diSplash = Win32::GUI::DIBitmap->newFromFile("$dir/$base$ext");
				return $diSplash->ConvertToBitmap() if $diSplash;
			}
		}
	}

	return undef;
}

######################################################################
# Private _Win32GUIBitmap()
# Returns a bitmap of the Win32::GUI icon for use on the internally
# generated splash screen.
######################################################################

sub _Win32GUIBitmap
{
	return new Win32::GUI::BitmapInline( q(
		Qk34CwAAAAAAADYEAAAoAAAAMAAAADAAAAABAAgAAQAAAMIHAAATCwAAEwsAAAABAAAAAQAAAAAA
		AAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAMDAwADA3MAA8MqmALUAKQClAAAAjAAIAAgICACMABAA
		nAAQABAQEAAYGBgAlAAhACEhIQC1ACkAKSkpAJQAMQAxMTEArSE5ADk5OQBCQkIASkpKALUxUgCE
		OVIAUlJSAEoIWgCESloAjEpaAFpaWgBSY1oApTljAKVCYwCtQmMAlEpjAIRSYwBaY2MAY2NjALVK
		awCMUmsAlFprAL1aawBra2sAUilzAHMxcwCEa3MAlGtzAJxrcwBzc3MAjHtzAHtjewCcc3sAe3t7
		AHuEewBzSoQAc1qEAIRzhACUc4QAe4SEAISEhACEjIQAnISMAHuMjACEjIwAjIyMAJyMjAB7a5QA
		vYSUAISUlACUlJQAe5yUAISclAC9jJwAnJycAJSlnACcpZwAjK2cAJSlpQClpaUAc5ytAK2trQC9
		ta0AtbW1ALW9tQC1vb0Avb29ALXGvQC9xsYAxsbGAL3OxgDOzs4AxtbOADmc1gDO1tYA1tbWAN7e
		3gDn5+cA7+/vAACc9wD39/cASr3/AP///wD///8A////AP///wD///8A////AP///wD///8A////
		AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A
		////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD/
		//8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
		/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////
		AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A
		////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD/
		//8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
		/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////
		AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A
		////AP///wD///8A8Pv/AKSgoACAgIAAAAD/AAD/AAAA//8A/wAAAP8A/wD//wAA////AC5OAUUB
		+AAAAANVWmMAB2QAHWhTFxUXFxAbTlMiExAqBwdfYy8TFxAbTk5ARQdlAAZkAANdTjkAAAAAA1df
		aAAIagFVBQAAFRUeTjkQABFXZV9FEQAAABceNfhFZAAHagADZfc1AAAAAANXX2YACGoBUwQAAAsv
		IgBAY0AQEEBjRQAEAAAHLyoAG0VAYwAGagAEaGRONQAAAANXX2YACGoBVQQAAAtANQAiV0UqL0ov
		EQAEAAAHFREALzkVVQAGagAEaGRONQAAAANXX2YACGoBVQQAAAkZGQAaRUBORSIACQAABBsVAE4G
		agAEaGRONQAAAANXX2YACGoBVQcAAAUiSkBKIgANAAFTBmoABGhkTjUAAAADV19mAAhqAA1VAAAT
		IioTADVXOUUbAA0AAVUGagAEaGRONQAAAANXX2YACGoADVUAABn3Wh4ARWVOVSoABAABFQEVBwAB
		VQZqAARoZE41AAAAA1dfZgAIagANVQAAFUD3GwA5ZV1lQAAEAAEvAS8HAAFTBmoABGhkTjUAAAAD
		V19mAAhqABNVAAANFTlOLxUiY2oHIg0AABMXAAcAATUBZgVqAARoZE41AAAAA1dfZgAIagFVBAAA
		DBc1LxMaV05F9yIVFQkAARABRQVqAARoZE41AAAAA1dfZgAIagFVBwAACiL3QBERQEVFQBUJAAEe
		BWoABGhkTjUAAAADV19mAAhqAAROAAANBAAAHRMaFQAAFRUq9/gRABUvIgAQLwAbampoampoZE41
		AAAAAANXX2YACGoAA18eEAAMAAAWDSJXShUqV/cbFyoNE1NmampqaGRONQAAAANXX2YACmoBHg4A
		AAhFX0D4QEBKIgQAAAhTampqaGRONQAAAANXX2YACmoBGQUAAB0bOSIAABsTAAATNfdXKhE1UyoT
		AAD3ampqaGRONQAAAAADV19mAApqAU4BEQQAAB0aSvcqNVoZAAAADSIvGhMaLy8TAABTampqaGRO
		NQAAAAADV19mAAtqAVMFAAAGFUBXZF0aBgAAAxdAFwAFAAAIU2pqamhkTjUAAAADV19mAAtqAANj
		Gg0ABAAABhUaFxU1KgUAAAMQFxAABQAACFNqampoZE41AAAAA1dfZgALagANaAcZAAAVEQAAEBNd
		VQANAAAIVWpqamhkTjUAAAADV19mAA1qAAseAAAvKgAaVV1lQAANAAAIU2pqamhkTjUAAAADV19m
		AA1qABAqAAA1LwAAKmNkV0AAE/cXBQAACxkqL0BdampoZE41AAAAAANXX2YACmoAFGhjUxcAAC9F
		FwAbXV9kZSIa9y8QBAAACzVTLy9XampoZE41AAAAAANXX2YACmoBBwEaBAAABSJKQDlOAARdAAVV
		GgAqLwAEAAALLyIANWhqamhkTjUAAAAAA1dfZgAEagApRRkeIh4aEwAAEyobEwAR+GNfX2NfWhsA
		DSIvFQAAExAA+GpqamhkTjUAAAAAA1dfZgAEagEXBAAAFw0TFxpFXVUiEBdTZldXWldVGwAAEy8V
		AAUAAAgqZGpqaGRONQAAAANXX2YABGoACB4AAAAVQFdfB10ACF9VQPhAQEoiCgAACBoHampoZE41
		AAAAIFdfZmpqagdOQEBAOUBXZGNfXV1fZmZAExUTExUq+BsNBgAACg0a92hqamhkTjUAAAAPV19m
		amhFGk5mZWZfU1pfAARdAARfWkAQBQAABSpjWioNAAUAARcBBwRqAARoZE41AAAACVdfaGoHGQAa
		VQAKXQFlAUAHAAAFQGVdVRsABQABHgVqAARoZE41AAAAJ1dfZmpqLwAAG05XNRciV2VmY11oSgAA
		EyIqEwAQGhpOLwAXQEAiTgAFagAEaGRONQAAACdXX2ZqamMeEBdATh4NKvc5NVNjVxsAABX3XUoa
		EwAAFyIVGlNlOTkABWoABGhkTjUAAAADV19mAARqACBVNUBA+EBfRQAAHl0eAAAAFUBXY11VGwAA
		F0ARGV0VGQVqAARoZE41AAAAA1dfZgAEagAgBxoNAB5kXS8ZAAARAAAAHh4RSmROU04vABBFExBA
		SgcFagAEaGRONQAAAANXX2YABGoAHmM5GhFFal9TB/gaGQAAABsiE0BfTi8iLxcbQBAQ9wdqAARo
		ZE41AAAAA1dfZgAQagARHgAAABVAQFNdGgAAIvdADRoACGoABGhkTjUAAAADV19mABBqABFfVVMN
		ABMVGRoQAAAiU0AZOQAIagAEaGRONQAAAANXX2YAE2oAA1MVEAAGAAAFHkX4U2UACWoAA2RONQAA
		AAADV19mABRqAANkQBMABQAABCJFQGMJagAEaGRONQAAAANXWl0AEV8AEl1fZGNVLxsbAAAbRVX3
		XWNfXQVfAAVdX19OOQAAAAAFV1laVlcAEVkAD1hcYFtZWCkpWGBgYFtYWQAGVwAFVQdgTjkAAAAB
		VwEHLF0BTgE5AAAABlcuPGFHHBYlASsBKwUlAAQkJT5PBEoABU84JTNDAAAAAAZXCh9nMAsdDgAN
		DA4tUfhFRfhRJw4dTAAAAAAGVxgxaTsPHRYADRIWTV5KV1dKXkgWIEkAAAAABlc0N1Q9IR0sAA0o
		LEZQRU5ORVBCLDJBAAAAAAZXTzo2QUsdSQANTEk/Ofg5Ofg5P0lEQAAAAQ==
		) );
}

=head1 AUTHOR

Robert May, C<< <robertmay@cpan.org> >>

=head1 REQUIRES

L<Win32::GUI|Win32::GUI> v1.02 or later.

L<Win32::GUI::DIBitmap|Win32::GUI::DIBitmap> for JPEG support.

=head1 EXAMPLES

	#!perl -w
	use strict;
	use warnings;

	use Win32::GUI 1.02 ();
	use Win32::GUI::SplashScreen;

	# Create and display the splash screen
	# Uses default filename of 'SPLASH', and searches for
	# SPLASH.bmp and SPLASH.jp[e]g
	Win32::GUI::SplashScreen::Show();

	# Create the main window
	my $mw = Win32::GUI::Window->new(
		-title  => "SplashScreen Demo 1",
		-size   => [700, 500],
	) or die "Creating Main Window";

	# do some other stuff
	sleep(1);

	# show the main window and enter the dialog phase
	# splash screen taken down after (default) 3 seconds
	$mw->Center();
	$mw->Show();
	Win32::GUI::Dialog();
	exit(0);

=head1 USING WITH PAR

If you pack your GUI into an executable using PAR
(See L<http://par.perl.org/>) then add your bitmap
to the PAR distributable with the -a option,

	pp -a SPLASHFILE.bmp -o xxx.exe xxx.pl

where F<SPLASHFILE.bmp> is the name of your
splash screen image and Win32::GUI::SplashScreen
will find it.

=head1 BUGS

See the F<TODO> file from the disribution.

=head1 ACKNOWLEDGEMENTS

Many thanks to the Win32::GUI developers at
L<http://sourceforge.net/projects/perl-win32-gui/>

=head1 COPYRIGHT & LICENSE

Copyright 2005..2009 Robert May, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SplashScreen.pm
