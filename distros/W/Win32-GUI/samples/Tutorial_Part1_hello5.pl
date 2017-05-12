#!perl -w
use strict;
use warnings;

use Win32::GUI();

my $text = defined($ARGV[0]) ? $ARGV[0] : "Hello, world";

my $main = Win32::GUI::Window->new(
	-name   => 'Main',
	-width  => 100,
	-height => 100,
	-text   => 'Perl',
);

my $font = Win32::GUI::Font->new(
	-name => "Comic Sans MS", 
	-size => 24,
);

my $label = $main->AddLabel(
	-text       => $text,
	-font       => $font,
	-foreground => 0x0000FF,
);

my $ncw = $main->Width()  - $main->ScaleWidth();
my $nch = $main->Height() - $main->ScaleHeight();
my $w = $label->Width()  + $ncw;
my $h = $label->Height() + $nch;

$main->Resize($w, $h);

# Get the desktop window and its size:
my $desk = Win32::GUI::GetDesktopWindow();
my $dw = Win32::GUI::Width($desk);
my $dh = Win32::GUI::Height($desk);

# Calculate the top left corner position needed
# for our main window to be centered on the screen
my $x = ($dw - $w) / 2;
my $y = ($dh - $h) / 2;

# And move the main window to the center of the screen
$main->Move($x, $y);

$main->Show();
Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
	return -1;
}

sub Main_Resize {
	my $mw = $main->ScaleWidth();
	my $mh = $main->ScaleHeight();
	my $lw = $label->Width();
	my $lh = $label->Height();
	if ($lw > $mw) {
		$main->Width($lw + $ncw); # Remember the non-client width!
	}
	else {
		$label->Left(($mw - $lw) / 2);
	}
	if ($lh > $mh) {
		$main->Height($lh + $nch); # Remember the non-client height!
	}
	else {
		$label->Top(($mh - $lh) / 2);
	}

	return 0;
}
