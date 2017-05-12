use strict;
use warnings;
use Win32::MMF::Shareable;
use CGI;

# Process 1

tie my @array, "Win32::MMF::Shareable", '@array';
tie my $sigM, "Win32::MMF::Shareable", 'sigM';
tie my $sig1, "Win32::MMF::Shareable", 'sig1';
tie my $cgi, "Win32::MMF::Shareable", 'cgi';

$sig1 = 1;

while (!$sigM) {}

local $" = ' ';
for (1..10) {
    print "proc1 - push [$_]\n";
    push @array, $_;
}

# create a shared CGI object to be used by proc 2
$cgi = new CGI;

$sig1 = 1;
