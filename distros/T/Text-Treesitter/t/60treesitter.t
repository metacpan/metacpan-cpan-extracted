#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Text::Treesitter;

my $ts = Text::Treesitter->new(
   lang_name => "fourfunc",
   lang_dir  => "languages/tree-sitter-fourfunc",
);

my $tree = $ts->parse_string( "1 + 2" );
my $root = $tree->root_node;

is( $root->tree, $tree, '$root->tree is $tree' );

## The following is quite fragile based on the grammar for the program above.
#  We'll try to do our best

is( $root->type,       "fourfunc", '$root->type' );
is( $root->start_byte, 0,          '$root->start_byte' );
is( $root->end_byte,   5,          '$root->end_byte' );
ok( $root->is_named,               '$root->is_named' );

done_testing;
