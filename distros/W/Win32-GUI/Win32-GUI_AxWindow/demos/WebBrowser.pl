#!perl -w
use strict;
use warnings;

#
#  Hosting a WebBrowser
#    Create a WebBrowser and register an event.
#    Enumerate Property, Methods and Events and create a Html file.
#    Load Html file in WebBrowser.
#

use File::Temp();
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::AxWindow();

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
#   -control => "{8856F961-340A-11D0-A96B-00C04FD705A2}",
 ) or die "new Control";

# Register Event

$Control->RegisterEvent("StatusTextChange",
        sub {
            my($self,$id, @args) = @_;
            print "Event : ", @args, "\n";
        }
);

# Enum Property info

my $tmp = File::Temp->new(SUFFIX => ".html");
print "writing to file: $tmp\n";

print $tmp "<html>\n";
print $tmp "<head><title>AxWindow WebBrowser Properties</title></head>\n";
print $tmp "<body><hr /><h1>Properties</h1><hr />\n";

foreach my $id ($Control->EnumPropertyID()) {
    my %property = $Control->GetPropertyInfo ($id);

    print $tmp "<p>\n";
    foreach my $key (keys %property) {
        print $tmp "<b>$key</b> = $property{$key}<br />\n";
    }
    print $tmp "</p>\n";
}

# Enum Method info

print $tmp "<hr /><h1>Methods</h1><hr />\n";

foreach my $id ($Control->EnumMethodID()) {
    my %method = $Control->GetMethodInfo ($id);

    print $tmp "<p>\n";
    foreach my $key (keys %method) {
        print $tmp "<b>$key</b> = $method{$key}<br />\n";
    }
    print $tmp "</p>\n";
}

# Enum Event info

print $tmp "<hr /><h1>Events</h1><hr />\n";

foreach my $id ($Control->EnumEventID()) {
    my %event = $Control->GetEventInfo ($id);

    print $tmp "<p>\n";
    foreach my $key (keys %event) {
        print $tmp "<b>$key</b> = $event{$key}<br />\n";
    }
    print $tmp "</p>\n";
}

print $tmp "</body></html>\n";

# Method call
my $path = "file://$tmp";

# print $path, "\n";
$Control->CallMethod("Navigate", $path);

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
