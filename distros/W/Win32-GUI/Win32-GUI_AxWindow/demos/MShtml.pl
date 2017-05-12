#!perl -w
use strict;
use warnings;

#
#  MSHTML : Load static HTML data
#
#

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::AxWindow();

# main Window
my $Window = new Win32::GUI::Window (
    -title => "Win32::GUI::AxWindow MSHTML demo",
    -pos   => [100, 100],
    -size  => [400, 400],
    -name  => "Window",
    -addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Create AxWindow
my $Control = new Win32::GUI::AxWindow  (
    -parent  => $Window,
    -name    => "Control",
    -pos     => [0, 0],
    -size    => [400, 400],
    -control => "MSHTML:<body>This is a line of text</body>",
) or die "new Control";

# Event loop
$Window->Show();
Win32::GUI::Dialog();
$Window->Hide();
exit(0);

# Main window event handler

sub Window_Resize {
    if (defined $Window) {
        my ($width, $height) = ($Window->GetClientRect)[2..3];
        $Control->Resize ($width, $height);
    }
}
