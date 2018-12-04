#!perl

use strict;
use warnings;
use Test::More;

my $trace;
{
    package Foo;
    sub new { bless {}, shift };
    use namespace::local -below;
    sub DESTROY { $trace++ };
};

my $foo = Foo->new;

is $trace, undef, "no destroy called";

undef $foo;

is $trace, 1, "destroy called once";

done_testing;
