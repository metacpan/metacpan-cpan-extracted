#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use UR;

class Foo {
    has => [
        _bar => {},
        _baz => {},
    ],
};

sub evaluate_permutations_for_boolexps_with_message {
    my $bx1 = shift;
    my $bx2 = shift;
    my $msg = shift;

    for my $obj (Foo->create( _bar => 0, _baz => 0 ),
                    Foo->create( _bar => 1, _baz => 0 ),
                    Foo->create( _bar => 1, _baz => 1 ),
                    Foo->create( _bar => 0, _baz => 1 )){

        is( $bx1->evaluate($obj), $bx2->evaluate($obj), $msg );
    }
}

my $bx1 = Foo->define_boolexpr('_bar != 1 and _baz != 1');
my $bx2 = Foo->define_boolexpr('_bar != 1 AND _baz != 1');


my $bx3 = Foo->define_boolexpr('_bar != 1 or _baz != 1');
my $bx4 = Foo->define_boolexpr('_bar != 1 OR _baz != 1');

evaluate_permutations_for_boolexps_with_message($bx1, $bx2, "Lower and uppercase AND behave the same");
evaluate_permutations_for_boolexps_with_message($bx3, $bx4, "Lower and uppercase OR behave the same");

done_testing();
