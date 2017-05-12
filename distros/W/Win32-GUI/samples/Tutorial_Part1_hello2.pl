#!perl -w
use strict;
use warnings;

use Win32::GUI();

# Get the text to put in the label from the command line,
# using 'Hello, world' as a default if nothing is provided.
my $text = defined($ARGV[0]) ? $ARGV[0] : "Hello, world";

my $main = Win32::GUI::Window->new(
	-name   => 'Main',
	-width  => 100,
	-height => 100,
	-text   => 'Perl',   # Add a title
);

my $label = $main->AddLabel(
	-text => $text,
);

# Calculate the non-client area of the main window:
my $ncw = $main->Width()  - $main->ScaleWidth();
my $nch = $main->Height() - $main->ScaleHeight();

# Calculate the required size of the main window to
# exactly fit the label:
my $w = $label->Width()  + $ncw;
my $h = $label->Height() + $nch;

# Resize the main window to the calculated size:
$main->Resize($w, $h);

$main->Show();
Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
	return -1;
}
