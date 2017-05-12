#!perl -I.

use Test::MultiFork;
use Time::HiRes qw(sleep);

FORK_a5:

print "1..3\n";

sleep(0.1);
print "ok 1  - one$$\n";
print "ok 2  - two$$\n";
sleep(0.1);
print "ok 3  - three$$\n";


