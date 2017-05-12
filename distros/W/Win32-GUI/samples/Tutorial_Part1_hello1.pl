#!perl -w
use strict;
use warnings;

use Win32::GUI();

# Create a window, saving it in variable $main
my $main = Win32::GUI::Window->new(
	-name   => 'Main',
	-width  => 100,
	-height => 100,
);

# Add a label to the window (by default a label
# has size big enough for its text and is positioned
# in the top left of its containing window)
$main->AddLabel(
	-text => "Hello, world",
);

# Show our main window
$main->Show();

# Enter the windows message loop, often referred
# to as the "dialog phase".
Win32::GUI::Dialog();

# When the message loopreturns control to our
# perl program, then the interaction with the
# GUI is complete, so we exit.
exit(0);

###################### ######################
# The Terminate event handler for a window
# named 'Main'.  Returning -1 causes the
# windows message loop to exit and return
# control to our perl program.
sub Main_Terminate {
	return -1;
}
