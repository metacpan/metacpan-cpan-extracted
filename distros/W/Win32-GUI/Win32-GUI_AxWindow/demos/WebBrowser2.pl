#!perl -w
use strict;
use warnings;

#
#  Hosting a WebBrowser
#    Create a WebBrowser and register an event.
#    Enumerate Property, Methods and Events and display in WebBrowser.
#  Same demo as WebBrowser.pl, but using OLE to avoid the temp file.
#

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::AxWindow();
use Win32::OLE();

# main Window
my $Window = Win32::GUI::Window->new(
    -title => "Win32::GUI::AxWindow WebBrowser",
    -pos   => [100, 100],
    -size  => [400, 400],
    -name  => "Window",
    -pushstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Create AxWindow
my $Control = new Win32::GUI::AxWindow  (
    -parent  => $Window,
    -name    => "Control",
    -pos     => [0, 0],
    -size    => [400, 400],
    -control => "Shell.Explorer.2",
 ) or die "new Control";

# Enum Property info

my $html = "";
$html .= "<html>\n";
$html .= "<head><title>AxWindow WebBrowser Properties</title></head>\n";
$html .= "<body><hr /><h1>Properties</h1><hr />\n";

foreach my $id ($Control->EnumPropertyID()) {
    my %property = $Control->GetPropertyInfo ($id);

    $html .= "<p>\n";
    foreach my $key (keys %property) {
        $html .= "<b>$key</b> = $property{$key}<br />\n";
    }
    $html .= "</p>\n";
}

# Enum Method info

$html .= "<hr /><h1>Methods</h1><hr />\n";

foreach my $id ($Control->EnumMethodID()) {
    my %method = $Control->GetMethodInfo ($id);

    $html .= "<p>\n";
    foreach my $key (keys %method) {
        $html .= "<b>$key</b> = $method{$key}<br />\n";
    }
    $html .= "</p>\n";
}

# Enum Event info

$html .= "<hr /><h1>Events</h1><hr />\n";

foreach my $id ($Control->EnumEventID()) {
    my %event = $Control->GetEventInfo ($id);

    $html .= "<p>\n";
    foreach my $key (keys %event) {
        $html .= "<b>$key</b> = $event{$key}<br />\n";
    }
    $html .= "</p>\n";
}

$html .= "</body></html>\n";

# Load blank page
$Control->CallMethod("Navigate", "about:blank");
# write the HTML to the page
$Control->GetOLE()->{Document}->write($html);

# free memory
undef $html;

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
