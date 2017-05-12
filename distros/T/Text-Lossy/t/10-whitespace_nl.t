#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new->add('whitespace_nl');

# Repeat the tests for 'whitespace': should be the same behaviour
is($lossy->process('Hello,   World!'), 'Hello, World!', "Multiple spaces collapsed");
is($lossy->process('Hello, World!  '), 'Hello, World! ', "Spaces at end collapsed");
is($lossy->process('  Hello, World!'), 'Hello, World!', "Spaces at beginning removed");

is($lossy->process(" \t Hello, \n\r\n World!\x{A0}\x{A0}"), 'Hello, World! ', "Various whitespace removed");

is($lossy->process("Hello, Wo\x{2060}rld!"), "Hello, Wo\x{2060}rld!", "Word Joiner left alone");

# New tests with newline at end
is($lossy->process("Hello,   World!\n"), "Hello, World!\n", "Newline at end remains");
is($lossy->process(" \t Hello,\n \n    World!\t \n  "), "Hello, World!\n", "Only newline at end remains");

done_testing();
