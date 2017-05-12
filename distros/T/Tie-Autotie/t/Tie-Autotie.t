# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-Autotie.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use Tie::Autotie 'Tie::IxHash';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

tie %x, Tie::IxHash;

$x{z}{a} = 10;
$x{z}{c} = 20;
$x{z}{b} = 30;

$x{a}{c} = 1;
$x{a}{b} = 2;
$x{a}{a} = 3;

$x{z}{z}{z}{z}{j} = 100;
$x{z}{z}{z}{z}{a} = 200;
$x{z}{z}{z}{z}{p} = 300;
$x{z}{z}{z}{z}{h} = 400;
$x{z}{z}{z}{z}{y} = 500;

ok(join("", keys %x) eq "za");
ok(join("", keys %{ $x{z} }) eq "acbz");
ok(join("", keys %{ $x{a} }) eq "cba");
ok(join("", keys %{ $x{z}{z}{z}{z} }) eq "japhy");
