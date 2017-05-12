# -*- perl -*-
use Test::More tests => 10;
#use lib '.';
#use lib './lib/';
#use strict;

use optimize;
my $foo : optimize(int) = 1.5;
is($foo,1.5, "Assign is not affected");
$foo += 0;
is($foo, 1 , "As soon as we touch it gets integerized");
$foo = $foo - 1;
is($foo, 0 , "Subtraction is negative aswell");
$foo = 5.5;
my $bar = $foo + 0.5 + $foo;
is($bar, 10, "Nested operations are affected");
my $baz : optimize(int) = 2;
$baz *= 1.5;
is($baz, 2, "Multiply");
$baz = $baz / 2.5;
is($baz, 1, "Divide");
$bar *= 1.5;
is($bar, 15, "Check that others are not affected");
$bar = $bar + 0.5;
is($bar, 15.5 ,' -"- ');
is($baz == 1.5, 1, "Check that comparison is integerized");
is($foo == 5.6, 1, "Seems like it");


