#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use UR;



class Foo {
    has => [
        _bar => {},
    ],
};

my $bx1 = Foo->define_boolexpr( _bar => { operator => '!=', value => undef});
my $bx2 = Foo->define_boolexpr( '_bar !=' =>  undef);

is( $bx2->id, $bx1->id, "Boolean expression created with an operator, with an operator using the new syntax and using a parameter name with an underbar works.");
