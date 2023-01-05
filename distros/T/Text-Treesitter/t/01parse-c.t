#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Text::Treesitter::Language;
use Text::Treesitter::Parser;

use constant TREE_SITTER_LANGUAGE_C_DIR => "languages/tree-sitter-c";

unless( -d TREE_SITTER_LANGUAGE_C_DIR ) {
   plan skip_all => "No C language dir " . TREE_SITTER_LANGUAGE_C_DIR;
}

use constant TREE_SITTER_LANGUAGE_C => TREE_SITTER_LANGUAGE_C_DIR . "/tree-sitter-c.so";
unless( -f TREE_SITTER_LANGUAGE_C ) {
   require Text::Treesitter::Language;
   Text::Treesitter::Language::build( TREE_SITTER_LANGUAGE_C, TREE_SITTER_LANGUAGE_C_DIR );
}

my $p = Text::Treesitter::Parser->new;
isa_ok( $p, "Text::Treesitter::Parser", '$p' );

my $lang = Text::Treesitter::Language::load( TREE_SITTER_LANGUAGE_C, "c" );
isa_ok( $lang, "Text::Treesitter::Language", '$lang' );

ok( $p->set_language( $lang ), '$p->set_language accepts language' ) or
   BAIL_OUT "Unable to set language";

use constant C_PROG => <<'EOF';
#include <stdio.h>

int main(void) {
  printf("Hello, world!\n");
  return 0;
}
EOF
my $tree = $p->parse_string( C_PROG );
isa_ok( $tree, "Text::Treesitter::Tree", '$tree' );

my $root = $tree->root_node;
isa_ok( $root, "Text::Treesitter::Node", '$root' );

## The following is quite fragile based on the grammar for the program above.
#  We'll try to do our best

is( $root->type,       "translation_unit", '$root->type' );
is( $root->start_byte, 0,                  '$root->start_byte' );
is( $root->end_byte,   length C_PROG,      '$root->end_byte' );
ok( $root->is_named,                       '$root->is_named' );

ok( !$root->has_error, '$root has no errors' );

is_deeply( [ $root->start_point ], [ 0, 0 ], '$root->start_point' );
is_deeply( [ $root->end_point   ], [ 6, 0 ], '$root->end_point' );

is( $root->child_count, 2, '$root->child_count' );

my @nodes = $root->child_nodes;
is( scalar @nodes, 2, '$root->child_nodes returned 2 nodes' );

isa_ok( $nodes[0], "Text::Treesitter::Node", '$nodes[0]' );

is( $nodes[0]->type, "preproc_include", '$nodes[0]->type' );

is( $nodes[1]->type, "function_definition", '$nodes[1]->type' );

done_testing;
