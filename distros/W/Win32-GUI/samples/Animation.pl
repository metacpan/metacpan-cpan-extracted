#! perl -w
#
# This samples show how use Animation control (You can only open silent AVI clips).
#
use strict;
use Win32::GUI();

# Create your main window
my $Window = new Win32::GUI::Window(
    -name   => "Window",                    # Window name (important for OEM event)
    -title  => "Win32::GUI::Animation",     # Title window
    -pos    => [100,100],                   # Default position
    -size   => [400,400],                   # Default size
    -dialogui => 1,                         # Enable keyboard navigation like DialogBox
);

# Add an Animation control.
my $Animation = $Window->AddAnimation (
    -name     => "Animation",
    -pos      => [5,35],
    -size     => [390,350],
    -autoplay => 0,                        # Don't want autoplay
    -center   => 1,                        # Center video in control
    -transparent => 1,                     # background is transparent.
    -tabstop  => 0,
    -onStart  => sub { print "Start playing !!!\n" },
    -onStop   => sub { print "Stop  playing !!!\n" },
);

# Add a load button.
$Window->AddButton (
    -name    => "Load",
    -pos     => [5,5],
    -text    => "&Load...",
    -default => 1,
    -tabstop => 1,
    -group   => 1,                        # You can use :
#    -onClick => \&LoadAviFile,            #  a reference sub
    -onClick  => 'LoadAviFile',           #  a string name sub
);

# Add a start button.
$Window->AddButton (
    -name    => "Start",
    -pos     => [65,5],
    -text    => "&Start",
    -tabstop => 1,
    -onClick => sub { $Animation->Play(); },
);

# Add a stop button.
$Window->AddButton (
    -name    => "Stop",
    -pos     => [115,5],
    -text    => "&Stop",
    -tabstop => 1,
    -onClick => sub { $Animation->Stop(); },
);

# Show Main Window
$Window->Show();
# Go to event message loooooop....
Win32::GUI::Dialog();

#===========================================================
# Load Button event
#===========================================================

sub LoadAviFile {

  # Stop and close if any playing
  $Animation->Close();

  # Use GetOpenFile for search a avi file
  my $file = Win32::GUI::GetOpenFileName(
                   -owner  => $Window,                    # Main window for modal dialog
                   -title  => "Open a avi file",          # Dialog title
                   -filter => [                           # Filter file
                       'Animation file (*.avi)' => '*.avi',
                       'All files' => '*.*',
                    ],
                   -directory => ".",                     # Use current directory
                   );

  # Have select a file ?
  if ($file) {
     # Load file to animation control
     $Animation->Open($file);
  }
  # Or an error messagebox with error.
  elsif (Win32::GUI::CommDlgExtendedError()) {
     Win32::GUI::MessageBox (0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetOpenFileName Error");
  }
}
