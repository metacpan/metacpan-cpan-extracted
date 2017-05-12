#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new;

is_deeply( [$lossy->list()], [], "Empty list after construction");

$lossy->add('lower');
is_deeply( [$lossy->list()], ['lower'], "Single filter named");

$lossy->add('punctuation', 'whitespace');
is_deeply( [$lossy->list()], ['lower', 'punctuation', 'whitespace'], "Add appends, names listed in order");

$lossy->clear();
is_deeply( [$lossy->list()], [], "Empty list after clear");

$lossy->add('lower', 'punctuation')->add('whitespace', 'punctuation');
is_deeply( [$lossy->list()], ['lower', 'punctuation', 'whitespace', 'punctuation'], "Order and count preserved");

done_testing();
