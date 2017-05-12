#!perl -w
use strict;
use warnings;

use Win32::GUI();

my $main = Win32::GUI::Window->new(
    -name => 'Main',
    -text => 'Perl',
    -width => 200,
    -height => 200,
);

my $icon = new Win32::GUI::Icon('GUIPERL.ICO');

my $ni = $main->AddNotifyIcon(
    -name => "NI",
    -icon => $icon,
    -tip => "Hello",
);


Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
    return -1;
}

sub Main_Minimize {
    $main->Disable();
    $main->Hide();
    return 1;
}

sub NI_Click {
    $main->Enable();
    $main->Show();
    return 1;
}
