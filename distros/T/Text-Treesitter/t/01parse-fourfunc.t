#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Text::Treesitter::Language;
use Text::Treesitter::Parser;
use Text::Treesitter::Tree;

use constant TREE_SITTER_LANGUAGE_FOURFUNC_DIR => "languages/tree-sitter-fourfunc";

unless( -d TREE_SITTER_LANGUAGE_FOURFUNC_DIR ) {
   plan skip_all => "No fourfunc language dir " . TREE_SITTER_LANGUAGE_FOURFUNC_DIR;
}

use constant TREE_SITTER_LANGUAGE_FOURFUNC => TREE_SITTER_LANGUAGE_FOURFUNC_DIR . "/tree-sitter-fourfunc.so";
unless( -f TREE_SITTER_LANGUAGE_FOURFUNC ) {
   require Text::Treesitter::Language;
   Text::Treesitter::Language::build( TREE_SITTER_LANGUAGE_FOURFUNC, TREE_SITTER_LANGUAGE_FOURFUNC_DIR );
}

my $p = Text::Treesitter::Parser->new;
isa_ok( $p, [ "Text::Treesitter::Parser" ], '$p' );

my $lang = Text::Treesitter::Language::load( TREE_SITTER_LANGUAGE_FOURFUNC, "fourfunc" );
isa_ok( $lang, [ "Text::Treesitter::Language" ], '$lang' );

ok( $p->set_language( $lang ), '$p->set_language accepts language' ) or
   bail_out( "Unable to set language" );

use constant SOURCE => <<'EOF';
1 + 2
EOF
my $tree = $p->parse_string( SOURCE );
isa_ok( $tree, [ "Text::Treesitter::Tree" ], '$tree' );

is( $tree->text, SOURCE, '$tree->text' );

my $root = $tree->root_node;
isa_ok( $root, [ "Text::Treesitter::Node" ], '$root' );

is( $root->tree, $tree, '$root->tree is $tree' );

## The following is quite fragile based on the grammar for the program above.
#  We'll try to do our best

is( $root->type,       "fourfunc",    '$root->type' );
is( $root->start_byte, 0,             '$root->start_byte' );
is( $root->end_byte,   length SOURCE, '$root->end_byte' );
ok( $root->is_named,                  '$root->is_named' );

ok( !$root->has_error, '$root has no errors' );

is( [ $root->start_point ], [ 0, 0 ], '$root->start_point' );
is( [ $root->end_point   ], [ 1, 0 ], '$root->end_point' );

is( $root->start_row,    0, '$root->start_row' );
is( $root->start_column, 0, '$root->start_column' );
is( $root->end_row,      1, '$root->end_row' );
is( $root->end_column,   0, '$root->end_column' );

is( $root->child_count, 1, '$root->child_count' );

is( $root->parent, undef, '$root->parent' );

my $exprnode = ( $root->child_nodes )[0];

is( $exprnode->child_count, 3, '$exprnode->child_count' );

is( $exprnode->parent, $root, '$exprnode->parent' );

my @nodes = $exprnode->child_nodes;
is( scalar @nodes, 3, '$root->child_nodes returned 3 nodes' );

isa_ok( $nodes[0], [ "Text::Treesitter::Node" ], '$nodes[0]' );

is( $nodes[0]->type, "number", '$nodes[0]->type' );
is( $nodes[0]->text, "1",      '$nodes[0]->text' );

is( $nodes[1]->type, "+",      '$nodes[1]->type' );
is( $nodes[1]->text, "+",      '$nodes[1]->text' );

is( $nodes[2]->type, "number", '$nodes[2]->type' );
is( $nodes[2]->text, "2",      '$nodes[2]->text' );

is( $root->debug_sprintf, '(fourfunc (expr (number) operator: "+" (number)))',
   '$root->debug_sprintf' );

done_testing;
