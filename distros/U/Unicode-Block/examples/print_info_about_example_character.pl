#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::Block::Item;
use Unicode::UTF8 qw(encode_utf8);

# Object.
my $obj = Unicode::Block::Item->new(
       'hex' => 2505,
);

# Print out.
print 'Character: '.encode_utf8($obj->char)."\n";
print 'Hex: '.$obj->hex."\n";
print 'Last hex character: '.$obj->last_hex."\n";
print 'Base: '.$obj->base."\n";

# Output.
# Character: ┅
# Hex: 2505
# Last hex character: 5
# Base: U+250x