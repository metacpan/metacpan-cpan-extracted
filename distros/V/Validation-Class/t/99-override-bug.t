package TestBase;
use Validation::Class;
field foo => {required => 0,};

package TestDerived;
use Validation::Class;
set 'role' => 'TestBase';
field '++foo' => {required => 1,};

package main;
use Test::More;
use strict;
use warnings;

my $base = TestBase->new(params => {foo => undef});
ok($base->validate('foo'), 'base: foo not required');
my $derived = TestDerived->new(params => {foo => undef});
ok(!$derived->validate('foo'), 'derived: foo is required');
$derived->foo('bar');
ok($derived->validate('foo'), 'derived: foo is required');
ok($base->validate('foo'),    'base: foo not required');

done_testing();
