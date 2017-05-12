#!perl -w
use strict;
use warnings;

#
# Hosting MsFlexGrid : Test Indexed properties
# You need a computer with a registered version of MSFlxgrd.ocx
# (e.g. with a VC++ installation) to run this demo
#
# Sadly if you don't have a registered version of msflxgrd.ocx
# you don't get a control creation failure, but an IE window
# showing an error, as the underlying framework assumes that
# "MSFlexGridLib.MSFlexLib" is a URL to try any load!
#

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::AxWindow();

# main Window
my $Window = new Win32::GUI::Window (
    -title    => "Win32::GUI::AxWindow test",
    -pos      => [100, 100],
    -size     => [400, 400],
    -name     => "Window",
    -addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Create AxWindow
my $Control = new Win32::GUI::AxWindow  (
    -parent  => $Window,
    -name    => "Control",
    -pos     => [0, 0],
    -size    => [400, 400],
    -control => 'MSFlexGridLib.MSFlexGrid',
 ) or die "new Control";

# Test Enum property set by string value
# $Control->SetProperty("ScrollBars", "flexScrollBarNone");
# $Control->SetProperty("GridLines", "flexGridInset");

$Control->SetProperty("Rows", 5);
$Control->SetProperty("Cols", 5);

#$Control->SetProperty("TextMatrix", 1, 2, "Hello!!!");

#my $r = $Control->GetProperty("Rows");
#my $c = $Control->GetProperty("Cols");
#my $t = $Control->GetProperty("TextMatrix", 1, 2);
#print "Rows = $r, Cols = $c, TextMatrix(1,2) = $t\n";

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
