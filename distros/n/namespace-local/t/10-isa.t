#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Bar;
    sub bar { 42 };
};

{
    package Foo;
    BEGIN { our @ISA = qw(Bar); };
    use namespace::local -above;
};

lives_ok {
    is( Foo->bar, 42, "\@ISA propagates no matter what" );
} "method didn't die";

done_testing;
