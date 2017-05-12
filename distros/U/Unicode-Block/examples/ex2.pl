#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Unicode::Block::Item;

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