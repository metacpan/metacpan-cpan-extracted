#!perl -w
use strict;
use warnings;

#
#  Hosting DHtmlEdit basic 
# You can't do much with it!  See DHtmlEditor.pl
# for a better sample (using Win32::GUI::DHtmlEdit)
#

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::AxWindow();

# main Window
my $Window = new Win32::GUI::Window(
    -name     => "Window",
    -title    => "Win32::GUI::AxWindow test",
    -pos      => [100, 100],
    -size     => [400, 400],
    -addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Create AxWindow
my $Control = new Win32::GUI::AxWindow(
    -parent  => $Window,
    -name    => "Control",
    -pos     => [0, 0],
    -size    => [400, 400],
    -control => "DHTMLEdit.DHTMLEdit",
   #-control => "{2D360200-FFF5-11D1-8D03-00A0C959BC0A}",
) or die "new Control";

# Method call
$Control->CallMethod("NewDocument");

# Event loop
$Window->Show();
Win32::GUI::Dialog();
$Window->Hide();
exit(0);

# Main window event handler

sub Window_Terminate {
    # Print Html Text
    print $Control->GetProperty("DocumentHTML");

    return -1;
}

sub Window_Resize {
    if (defined $Window) {
        my ($width, $height) = ($Window->GetClientRect)[2..3];
        $Control->Move(0, 0);
        $Control->Resize($width, $height);
    }
}
