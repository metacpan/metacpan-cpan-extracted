use strict;
use warnings;
use Win32::MMF::Shareable;

defined(my $pid = fork()) or die "Can not fork a child process!";

if (!$pid) {
    print "Process 1 start\n";
    system("perl demo6_p1.pl");
    print "Process 1 finish\n";
    exit;
}

defined($pid = fork()) or die "Can not fork a child process!";

if (!$pid) {
    print "Process 2 start\n";
    system("perl demo6_p2.pl");
    print "Process 2 finish\n";
    exit;
}

print "Main process start\n";

my $ns = tie my $sigM, "Win32::MMF::Shareable", 'sigM';
tie my $sig1, "Win32::MMF::Shareable", 'sig1';
tie my $sig2, "Win32::MMF::Shareable", 'sig2';

while (!$sig1) {};
while (!$sig2) {};

$sig1 = $sig2 = 0;

$sigM = 1;          # start both proc 1 and 2

while (!$sig1) {};  # wait for proc 1
while (!$sig2) {};  # wait for proc 2

print "Main process finish\n";

