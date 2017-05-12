#!perl -w
use strict;
use warnings;

use Win32::GUI();

my $main = Win32::GUI::Window->new(
    -name => 'Main',
    -text => 'Perl',
    -width => 200,
    -height => 200
);

$main->Show();
Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
    return -1;
}
