#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new->add('whitespace');

is($lossy->process('Hello,   World!'), 'Hello, World!', "Multiple spaces collapsed");
is($lossy->process('Hello, World!  '), 'Hello, World! ', "Spaces at end collapsed");
is($lossy->process('  Hello, World!'), 'Hello, World!', "Spaces at beginning removed");

is($lossy->process(" \t Hello, \n\r\n World!\x{A0}\x{A0}"), 'Hello, World! ', "Various whitespace removed");

is($lossy->process("Hello, Wo\x{2060}rld!"), "Hello, Wo\x{2060}rld!", "Word Joiner left alone");

done_testing();
