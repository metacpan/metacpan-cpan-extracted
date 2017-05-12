#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new->add('lower');

# ascii
is($lossy->process('Hello, World!'), 'hello, world!', "ASCII lowercase");
is($lossy->process('hello, world!'), 'hello, world!', "No change on already lower");

# latin1
is($lossy->process('TÜR schließen'), 'tür schließen', "Latin1 one");
is($lossy->process('FRÊRE ÇA JALAPEÑO'), 'frêre ça jalapeño', "Latin1 two");

# Greek
is($lossy->process('ΑΒΓΔ'), 'αβγδ', "Greek");

# Kyrillic
is($lossy->process('АБДЖ'), 'абдж', "Cyrillic");

done_testing();
