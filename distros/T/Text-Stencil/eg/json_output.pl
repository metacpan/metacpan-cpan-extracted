#!/usr/bin/env perl
use v5.20;
use Text::Stencil;

# use {{ literal escape for JSON braces
my $s = Text::Stencil->new(
    header    => '[',
    row       => '{{"id":{0:int},"name":"{1:json}","active":{2:bool:true:false}}',
    footer    => ']',
    separator => ',',
);

my @rows = (
    [1, 'Alice "A"', 1],
    [2, "Bob\nSmith", 0],
    [3, 'Charlie',    1],
);

say $s->render(\@rows);
