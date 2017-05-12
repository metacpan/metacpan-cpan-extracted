#!perl -w
use strict;
use warnings;

#
#  Hosting Movie Control (A movie player control see
#  http://www.viscomsoft.com/movieplayer.htm)
#
# A 30-day trial licence of the control is available from
# the above site.
#

use FindBin();
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::AxWindow();

# main Window
my $Window = new Win32::GUI::Window (
    -title    => "Movie Control Test",
    -pos      => [100, 100],
    -size     => [200, 200],
    -name     => "Window",
    -addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Add a play button
$Window->AddButton(
	-name => "Button",
	-text => 'Play',
	-pos  => [10,10],
);

# Create AxWindow
my $Control = new Win32::GUI::AxWindow  (
    -parent  => $Window,
    -name    => "Control",
    -pos     => [0, $Window->Button->Height()+20],
    -width   => $Window->ScaleWidth(),
    -height  => $Window->ScaleHeight()-$Window->Button->Height()-20,
#   -control => "{F4A32EAF-F30D-466D-BEC8-F4ED86CAF84E}",
    -control => "MOVIEPLAYER.MoviePlayerCtrl.1",
) or die "new Control";

# Load Avi file
$Control->SetProperty("FileName", "$FindBin::Bin/movie.avi");

# Event loop
$Window->Show();
Win32::GUI::Dialog();
$Window->Hide();
exit(0);

# Main window event handler

sub Window_Resize {
  if (defined $Window) {
      my ($width, $height) = ($Window->GetClientRect)[2..3];
      $height = $height - $Window->Button->Height() - 20;
      #$Control->Resize ($width, $height);
      $Control->CallMethod("ResizeControl", $width, $height);
  }
}

sub Button_Click {
    # Start Avi player
    $Control->CallMethod("Play");
}
