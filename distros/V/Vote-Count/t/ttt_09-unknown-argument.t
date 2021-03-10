#!perl
use strict;
use warnings;
use Test::More tests => 1;
use Vote::Count::TextTableTiny qw/ generate_table /;
use Test::Fatal;

my $rows = [
   [ 'Pokemon', 'Type', 'Seen' ],
   [ 'Rattata', 'Normal', 10199 ],
   [ 'Ekans', 'Poison', 536 ],
   [ 'Vileplume', 'Grass / Poison', 4 ],
];

like(
    exception { generate_table( rows => $rows, heeder_row => 1) },
    qr/unknown argument/,
    "unknown argument should cause generate_table() to croak"
);

