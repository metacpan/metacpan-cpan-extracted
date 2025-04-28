#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use utf8;

use File::Slurper 'write_text';

use File::Spec;

use Tree::DAG_Node;

# ------------------------------------------------

sub add_child
{
	my($parent, $name) = @_;
	my($daughter)      = Tree::DAG_Node -> new({name => $name, attributes => {'#' => "$name$name"} });

	$parent -> add_daughter($daughter);

	return $daughter;

} # End of add_child.

# ------------------------------------------------

my($root)       = Tree::DAG_Node -> new({name => 'Root'});
my($parent)     = add_child($root, 'Â');
my($daughter_1) = add_child($parent, 'â');

add_child($parent, 'ä');

my($daughter_2) = add_child($parent, 'é');

add_child($daughter_1, 'É');

my($daughter_3) = add_child($daughter_2, 'Ñ');
my($daughter_4) = add_child($daughter_3, 'ñ');
my($daughter_5) = add_child($daughter_4, 'Ô');

add_child($daughter_5, 'ô');
add_child($daughter_5, 'ô');

$daughter_1 = add_child($root, 'ß');
$daughter_2 = add_child($daughter_1, '®');

add_child($daughter_2, '©');

$daughter_3 = add_child($daughter_1, '£');

add_child($daughter_1, '€');
add_child($daughter_1, '√');

$daughter_4 = add_child($daughter_1, '×xX');

add_child($daughter_4, 'í');
add_child($daughter_4, 'ú');
add_child($daughter_4, '«');
add_child($daughter_4, '»');

my($output_file_name) = File::Spec -> catfile('t', "tree.utf8.attributes.txt");

write_text($output_file_name, join("\n", @{$root -> tree2string}) . "\n");
