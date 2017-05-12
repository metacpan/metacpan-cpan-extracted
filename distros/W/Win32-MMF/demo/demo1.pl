use strict;
use warnings;
use Win32::MMF;
use Data::Dumper;

# DEMO 1 - storing variables and getting them back

my $ns = new Win32::MMF or die "Can not create shared memory";

my $var1 = "Hello world!";
my $var2 = {
    'Name' => 'Roger',
    'Module' => 'Win32::MMF',
};
my $var3 = [ qw/ Monday Tuesday Wednesday Thursday Friday Saturday Sunday / ];

$ns->setvar('Var1', $var1);
$ns->setvar('Var2', $var2);
$ns->setvar('Var3', $var3);

$ns->debug();

print Dumper($ns->getvar('Var1'));
print Dumper($ns->getvar('Var2'));
print Dumper($ns->getvar('Var3'));

