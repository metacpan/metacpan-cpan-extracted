
use strict;
use Test::More tests => 2;
use types;

package Foo;
package Bar;
my Bar $bar;
my Foo $foo;
eval '$foo = $bar';
Test::More::like($@, qr/can\'t sassign Bar \(\$bar\) to Foo \(\$foo\)/, "No inheritance");
our @ISA = qw(Foo);
eval '$foo = $bar';
Test::More::is($@,"", "With inheritance, possible");

