use strict;
use warnings;
use Win32::MMF;
use Data::Dumper;

# DEMO 2 - Variable management

my $ns = new Win32::MMF or die "Can not create shared memory";

for (1 .. 10) {
    $ns->setvar("Var$_", $_);
}

$ns->debug();
print "press any key to continue..."; <>;

for (1 .. 10) {
    print $ns->getvar("Var$_"), "\n";
}

for (5 .. 9) {
    $ns->deletevar("Var$_");
}

$ns->debug();
print "press any key to continue..."; <>;

for (5 .. 9) {
    $ns->setvar("Var$_", $_);
}

$ns->debug();

