#!perl

use strict;

use lib '../lib';
use XiaoI;

my $robot = XiaoI->new;

while (my $line = <STDIN>) {
    chomp($line);
    if ($line eq 'q') {
        last;
    }
    print $robot->get_robot_text($line), "\n";
}
