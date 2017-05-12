#!perl -w
use strict;
use warnings;

#
# Hosting SCGrid (A freeware Grid ActiveX see : http://www.scgrid.com/)
# Download SCGridLite from http://www.scgrid.com/
# - Extract SCGrid.ocx and put it somewhere
# - from the command prompt: regsvr32 <path_to>\SCGrid.ocx
# - (uninstall regsvr32 /u <path_to>\SCGrid.ocx, and delete SCGrid.ocx)
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
    -control => "prjSCGrid.SCGrid",
 ) or die "new Control";

# Redraw Off
$Control->SetProperty("Redraw", 0);

# Create 1 Fixed col and Row
$Control->SetProperty("FixedRows", 1);
$Control->SetProperty("FixedCols", 1);
# Create 5 col and Row
$Control->SetProperty("Rows", 5);
$Control->SetProperty("Cols", 5);
# Adjust grid on column
$Control->SetProperty("AdjustLast", "scColumn");
# Add Resize column mode
$Control->SetProperty("ResizeMode", "scColumn");

# Fill Cell
for my $C (0..4)
{
    for my $R (0..4)
    {
        $Control->SetProperty("Text", $R, $C, "Cell ($R, $C)");
    }
}

# Fill Fixed Rows
$Control->SetProperty("Text", -1, -1, "    ");
for my $R (0..4)
{
    $Control->SetProperty("Text", $R, -1, "$R");
}
#$Control->CallMethod("AdjustWidth", -1, -32767);  # Force optional value

# Fill Fixed Cols and adjust size
for my $C (0..4)
{
    $Control->SetProperty("Text", -1, $C, "FixedCol($C)");
    #$Control->CallMethod("AdjustWidth", $C, -32767); # Force optional value
}

# Enable draw mode
$Control->SetProperty("Redraw", 1);

# Some property get
my $r = $Control->GetProperty("Rows");
my $c = $Control->GetProperty("Cols");
my $t = $Control->GetProperty("Text", 1, 2);
print "Rows = $r, Cols = $c, Text(1,2) = $t\n";

# Event loop
$Window->Show();
Win32::GUI::Dialog();

# Main window event handler

sub Window_Resize {
    if (defined $Window) {
        my ($width, $height) = ($Window->GetClientRect)[2..3];
        $Control->Move   (0, 0);
        $Control->Resize ($width, $height);
    }
}
