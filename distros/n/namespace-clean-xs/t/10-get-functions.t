use strict;
use Test::More;

package Foo;
sub stub;
sub CONST() {42}
sub bar {124}
our @ISA = qw/Bar/;
our $PI = 3.14;

package Bar;
sub pn {1}

package main;
use namespace::clean::xs ();

Foo->pn;
my $funcs = namespace::clean::xs->get_functions('Foo');
is scalar keys %$funcs, 3;

is exists $funcs->{stub}, 1;
is exists $funcs->{CONST}, 1;
is exists $funcs->{bar}, 1;

#is $funcs->{CONST}->(), 42; # do not try to call const as a sub - it'd fail on modern perls
is $funcs->{bar}->(), 124;

eval 'sub Foo::stub {-3}';
is $funcs->{stub}->(), -3;

done_testing;
