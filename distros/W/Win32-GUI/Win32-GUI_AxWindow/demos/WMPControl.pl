#!perl -w
use strict;
use warnings;

#
#  Hosting Windows Media Player
#  Needs WMP 7 and above (different object model to WMP 6.4)
#

use FindBin();
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::AxWindow();
use Win32::OLE();

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
    -control => "WMPlayer.OCX",
) or die "new Control";

# Don't autostart the video clip when we load it
$Control->GetOLE()->settings->{autoStart} = 0;

# Remove all ui widgets - just have the video window
# For some reason SetProperty doesn't seem to wrok - use OLE instead
#$Control->SetProperty("uiMode", "none");
$Control->GetOLE()->{uiMode} = "none";

# Stretch Video to video window
#$Control->GetOLE()->{stretchToFit} = 1;
$Control->SetProperty("stretchToFit", 1);

# Load the Avi file
$Control->SetProperty("URL", "$FindBin::Bin/Movie.avi");

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
      $Control->Resize ($width, $height);
  }
}

sub Button_Click {
    # Play the AVI file
    $Control->GetOLE()->{controls}->play();
    return 1;
}
