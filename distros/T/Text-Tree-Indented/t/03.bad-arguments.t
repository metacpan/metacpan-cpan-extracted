#!perl
use strict;
use warnings;
use Test::More 0.88;
use Text::Tree::Indented qw/ generate_tree /;
use Test::Fatal;
use utf8;

my $data = ['Fruit', ['Apples', 'Oranges']];

like(
    exception { generate_tree($data, { style => 'funky' }) },
    qr/unknown style/,
    "unknown style should cause generate_tree() to croak"
);

like(
    exception { generate_tree($data, { size => 'huge' }) },
    qr/unknown argument/,
    "unknown argument should cause generate_tree() to croak"
);

done_testing;
