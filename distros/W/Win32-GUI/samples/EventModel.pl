#! perl -w
#
# This sample show different event model availlabnle in Win32::GUI
#  - OEM (Old Event Model) : Call a function evnet based on control name and event name
#  - NEM (Nem Event Model) : Associate a sub event for a control.
# It present how to use both event model for a control.
# And event work with custom registered Class.
#
# NOTE : An event handler should return -1 for stop program, 0 for stop default event processing 
#        and other value for contine default event.
#
use strict;
use warnings;

use Win32::GUI qw(BS_NOTIFY);
use FindBin();

# Load a cursor bitmap
my $C = new Win32::GUI::Bitmap("$FindBin::Dir/harrow.cur", 2);

# Register a BUTTON class with cursor
my $BC = new Win32::GUI::Class(
	-name => 'Class_Button',            # Class name
	-extends => 'BUTTON',               # Extending Windows BUTTON class
	-widget => 'Button',                # Use button class event loop.
	-cursor   => $C,                    # Specific cursor for class
);	

# Create your main window
my $Window = new Win32::GUI::Window(
    -name   => "Window",                    # Window name (important for OEM event)
    -title  => "Win32::GUI test",           # Title window
    -pos    => [100,100],                   # Default position
    -size   => [400,400],                   # Default size
    -dialogui => 1,                         # Enable keyboard navigation like DialogBox
);


# Add a fisrt button in main window using default OEM event
$Window->AddButton (
    -name    => "OEM",                      # Button name (important for OEM event)
    -pos     => [5,5],                      # Default position
    -text    => "Click button OEM",         # Text show on button
    -addstyle => BS_NOTIFY,                 # Force notify style for more event
    -tabstop  => 1,                         # Allow tab navigation
);

# Add a second button in main window using NEM event (Automaticly set to NEM by using NEM Event)
$Window->AddButton (
    -name    => "NEM",
    -pos     => [5,35],
    -text    => "Click button NEM",
    -onClick     => sub { print "NEM Click !!!\n";},          # Register some NEN event
    -onDblClick  => sub { print "NEM DblClick !!!\n";},
    -onGotFocus  => sub { print "NEM GotFocus !!!\n";},
    -onLostFocus => sub { print "NEM LostFocus !!!\n";},
    -tabstop  => 1,                         # Allow tab navigation
);

# Add a third button in main window using both event model (OEM/NEM)
$Window->AddButton (
    -name    => "BOTH",
    -pos     => [5,70],
    -text    => "Click button BOTH",
    -eventmodel => "both",                  # Force both event model
    -onClick     => sub { print "BOTH Click using NEM !!!\n";
                          return 1; },      # Return 1 for permit OEM event call, 0 for ignore it.
    -tabstop  => 1,                         # Allow tab navigation
);

# Add a last button in main window using your class
$Window->AddButton (
    -name    => "CLASS",
    -pos     => [5,105],
    -text    => "Click button Class",
    -class   => $BC,
    -onClick => sub { print "Class Click !!!\n"; },
    -tabstop  => 1,                         # Allow tab navigation
);

# Show Main Window
$Window->Show();
# Go to event message loooooop....
Win32::GUI::Dialog();

#===========================================================
# Window event
#=========================================================== 
# Terminate Event
sub Window_Terminate {
    return -1;   # Stop message loop and finish program
}

# MouseMove event
sub Window_MouseMove {
    print "Window_MouseMove\n";     
}

# Activate event
sub Window_Activate {
    print "Window_Activate !!!\n";
    return 1;    # Continue default processing
}

# Deactivate event
sub Window_Deactivate {
    print "Window_Deactivate !!!\n";
    return 1;    # Continue default processing
}

# Minimize event
sub Window_Minimize {
    print "Window_Minimize !!!\n";
    return 1;    # Continue default processing or 0 for stop minimize
}

# Maximise event
sub Window_Maximize {
    print "Window_Maximize !!!\n";
    return 1;    # Continue default processing or 0 for stop maximize
}

#===========================================================
# OEM Button event
#=========================================================== 

# Click Event
sub OEM_Click {
    print "OEM_Click !!!\n";
}

# DblClick Event
sub OEM_DblClick {
    print "OEM_DblClick !!!\n";
}

# GotFocus Event
sub OEM_GotFocus {
    print "OEM_GotFocus !!!\n";
}

# LostFocus Event
sub OEM_LostFocus {
    print "OEM_LostFocus !!!\n";
}

# MouseMove Event
sub OEM_MouseMove {
    print "OEM_MouseMouve\n";
}

# MouseDown Event
sub OEM_MouseDown {
    print "OEM_MouseDown\n";
    return 1; # Continue default processing or 0 for stop (don't receive click event)
}

# MouseUp Event
sub OEM_MouseUp {
    print "OEM_MouseUp\n";
    return 1; # Continue default processing or 0 for stop (don't receive click event)
}

# KeyDown Event
sub OEM_KeyDown {
    print "OEM_KeyDown\n";
    return 1; # Continue default processing or 0 for stop (button not push)
}

# KeyUp Event
sub OEM_KeyUp {
    print "OEM_KeyUp\n";
    return 1; # Continue default processing or 0 for stop (button not unpush)
}

#===========================================================
# BOTH Button event
#=========================================================== 

# Click  Event
sub BOTH_Click {
    print "BOTH_Click using OEM !!!\n";
}

# MouseMove Event
sub BOTH_MouseMove {
    print "BOTH_MouseMouve using OEM !!!\n";
}
