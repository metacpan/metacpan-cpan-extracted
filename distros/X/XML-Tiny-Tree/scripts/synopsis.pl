#!/usr/bin/env perl

use strict;
use warnings;

use XML::Tiny::Tree;

# ------------------------------------------------

my($input_file) = shift || die "Usage $0 file. Try using data/test.xml as the input. \n";
my($tree)       = XML::Tiny::Tree -> new
					(
						input_file        => $input_file,
						no_entity_parsing => 1,
					) -> convert;

print "Input file: $input_file. \n";
print "The whole tree: \n";
print map("$_\n", @{$tree -> tree2string});
print '-' x 50, "\n";
print "Bits and pieces from the first child (tag_4) of the second child (tag_3) of the root (tag_1): \n";

my(@children) = $tree -> children;
@children     = $children[1] -> children;
my($tag)      = $children[0] -> value;
my($meta)     = $children[0] -> meta;
my($attr)     = $$meta{attributes};

print "tag:        $tag. \n";
print "content:    $$meta{content}. \n";
print 'attributes: ', join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr), ". \n";
