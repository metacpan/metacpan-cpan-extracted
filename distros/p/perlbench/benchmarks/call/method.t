#!perl

# Name: Calling methods
# Require: 5
# Desc:
#


require 'benchlib.pl';

package Foo;

sub foo
{
    my $self = shift;
    $_[0] * $_[1];
}

package Bar;
@ISA=qw(Foo);

sub bar
{
    my $self = shift;
    $self;
}

package main;

$bar = bless {}, "Bar";

&runtest(10, <<'ENDTEST');

   $bar->foo(3, 4);
   $foo = $bar->bar;
   $bar->foo(3, 4);
   $foo = $bar->bar;

ENDTEST
