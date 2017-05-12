#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;
use open 'IO' => ':utf8';
use open ':std';

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new->add('punctuation_sp');

# Basically variants of 'punctuation'
is($lossy->process('Hello, World!'), 'Hello  World ', "ASCII punctuation replaced");
is($lossy->process("Hello\x{2042} World\x{ff1f}"), "Hello  World ", "non-ASCII punctuation replaced");
is($lossy->process("Hello World\x{2605}"), "Hello World\x{2605}", "non-punctuation stays");

done_testing();
