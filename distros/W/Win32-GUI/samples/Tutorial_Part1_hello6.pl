#!perl -w
use strict;
use warnings;

use Win32::GUI();

# Get text to diaply from the command line
my $text = defined($ARGV[0]) ? $ARGV[0] : "Hello, world";

# Create our window
my $main = Win32::GUI::Window->new(
	-name   => 'Main',
	-width  => 100,
	-height => 100,
	-text   => 'Perl',
);

# Create a font to diaply the text
my $font = Win32::GUI::Font->new(
	-name => "Comic Sans MS", 
	-size => 24,
);

# Add the text to a label in the window
my $label = $main->AddLabel(
	-text       => $text,
	-font       => $font,
	-foreground => 0x0000FF,
);

my $ncw = $main->Width()  - $main->ScaleWidth();
my $nch = $main->Height() - $main->ScaleHeight();
my $w = $label->Width()  + $ncw;
my $h = $label->Height() + $nch;


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
# Resize the window to the size of the label
$main->Resize($w, $h);
# Set the minimum size of the window to the size of the label
$main->Change(
	-minsize => [$w, $h],
);

# SHow the window and enter the dialog phase.
$main->Show();
Win32::GUI::Dialog();
exit(0);

# Terminate Event handler
sub Main_Terminate {
	return -1;
}

# Resize Event handler
sub Main_Resize {
	my $mw = $main->ScaleWidth();
	my $mh = $main->ScaleHeight();
	my $lw = $label->Width();
	my $lh = $label->Height();

	$label->Left(($mw - $lw) / 2);
	$label->Top(($mh - $lh) / 2);

	return 0;
}
