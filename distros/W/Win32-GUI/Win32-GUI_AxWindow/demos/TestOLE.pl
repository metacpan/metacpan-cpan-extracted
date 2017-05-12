#!perl -w
use strict;
use warnings;

#
#  Host with AxWindow and manipulate with Win32::OLE
#  - Use GetOLE
#  - Call method
#  - Write in a HTML document
#

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::OLE();
use Win32::GUI::AxWindow();

# main Window
my $Window = new Win32::GUI::Window (
    -title    => "Win32::GUI::AxWindow and Win32::OLE",
    -pos      => [100, 100],
    -size     => [600, 600],
    -name     => "Window",
    -addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# A button
my $Button = $Window->AddButton (
    -name => "Button",
    -pos  => [0, 25],
    -size => [600, 50],
    -text => "Click me !!!",
    );

# Create AxWindow
my $Control = new Win32::GUI::AxWindow  (
    -parent  => $Window,
    -name    => "Control",
    -pos     => [0, 100],
    -size    => [600, 500],
    -control => "Shell.Explorer.2",
 ) or die "new Control";

# Get Ole object
my $OLEControl = $Control->GetOLE();

# $OLEControl->Navigate("about:blank");  # Clear control
$OLEControl->Navigate("http://www.google.com/");

# Event loop
$Window->Show();
Win32::GUI::Dialog();
$Window->Hide();
exit(0);

# Button Event
sub Button_Click {
    $OLEControl->{Document}->{body}->insertAdjacentHTML("BeforeEnd","Click !!!");
    #print "HTML = ", $OLEControl->{Document}->{body}->innerHTML, "\n";
    return 0;
}

# Main window event handler

sub Window_Resize {
    if (defined $Window) {
        my ($width, $height) = ($Window->GetClientRect)[2..3];
        $Button->Width($width);
        $Control->Resize($width, $height-100);
    }
}
