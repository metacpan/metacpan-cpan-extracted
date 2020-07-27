#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Text::Hspell v0.4.0;

srand(24);
my @letters = split //, "אבגדהוזחטיכלמנסעפצקרשת";
my $l       = 0;
{
    my $obj = Text::Hspell->new();

    my $cnt = 0;
    while (1)
    {
        my $word = join( "", @letters[ map { int rand(@letters) } 0 .. 5 ] );
        my @x    = @{ $obj->try_to_correct_word($word) };
        $l += @x;
        printf( "%d\t%d\t%s\t%s\n", ( ++$cnt ), $l, $word, ( join ",", @x ) );
    }
}
