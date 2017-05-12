use strict;
use warnings;
use Win32::MMF::Shareable;
use CGI;

# Process 2

tie my @array, "Win32::MMF::Shareable", '@array';
tie my $sigM, "Win32::MMF::Shareable", 'sigM';
tie my $sig2, "Win32::MMF::Shareable", 'sig2';
tie my $cgi, "Win32::MMF::Shareable", 'cgi';

$sig2 = 1;

while (!$sigM) {}

while (@array < 10) {}  # wait for the array to be filled up by proc 1

while (@array) {
    print "proc2 - pop [", shift(@array), "]\n";
}

while (!$cgi) {};       # wait for $cgi to become alive

# use a shared perl object   :-)
print "Process 2 uses shared object...\n";
print $cgi->header(), $cgi->start_html(), $cgi->end_html(), "\n";

$sig2 = 1;

