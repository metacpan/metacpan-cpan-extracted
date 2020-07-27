#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use Text::Hspell v0.4.0;

{

    my $obj = Text::Hspell->new();

    # TEST
    ok( $obj, "was instantiated." );

    # TEST
    ok( scalar( $obj->check_word("שלום") ), "word is ok" );

    # TEST
    ok(
        scalar( !( $obj->check_word("םץףללללללללללללללל") ) ),
        "word is a misspelling",
    );
    if (0)
    {
        diag( join ",", @{ $obj->try_to_correct_word("שולת") } );
    }

    # TEST
    is_deeply(
        [
            grep { $_ eq "שולט" } @{ $obj->try_to_correct_word("שולת") }
        ],
        ["שולט"],
        "spelling suggestion is ok"
    );
}
