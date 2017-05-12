# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

use strict;
use Test;

BEGIN { plan tests => 12 };

use Tie::Scalar::Transactional;
ok(1); 

# Create a Transactional Scalar in with OO interface
my $foo = 10;
new Tie::Scalar::Transactional($foo);
ok($foo == 10);

# Create a Transactional Scalar in with Procedural interface
tie my $bar, 'Tie::Scalar::Transactional', 20;
ok($bar == 20);

$foo++; 
ok($foo == 11);

$bar++;
ok($bar == 21);

Tie::Scalar::Transactional->rollback($foo);
ok($foo == 10);

tied($bar)->rollback();
ok($bar == 20);

$foo = 100;
$bar = 200;

tied($foo)->commit();
ok($foo == 100);

tied($foo)->rollback();
ok($foo == 100);

tied($bar)->commit();
ok($bar == 200);

tied($bar)->rollback();
ok($bar == 200);

use Tie::Scalar::Transactional qw(:commit);

$bar = 2000;
rollback $bar;
ok($bar == 200);

