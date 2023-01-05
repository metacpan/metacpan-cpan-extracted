#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Text::Treesitter::Language;
use Text::Treesitter::Parser;

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
isa_ok( $p, "Text::Treesitter::Parser", '$p' );

my $lang = Text::Treesitter::Language::load( TREE_SITTER_LANGUAGE_FOURFUNC, "fourfunc" );
isa_ok( $lang, "Text::Treesitter::Language", '$lang' );

ok( $p->set_language( $lang ), '$p->set_language accepts language' ) or
   BAIL_OUT "Unable to set language";

use constant SOURCE => <<'EOF';
1 + 2
EOF
my $tree = $p->parse_string( SOURCE );
isa_ok( $tree, "Text::Treesitter::Tree", '$tree' );

my $root = $tree->root_node;
isa_ok( $root, "Text::Treesitter::Node", '$root' );

## The following is quite fragile based on the grammar for the program above.
#  We'll try to do our best

is( $root->type,       "fourfunc",    '$root->type' );
is( $root->start_byte, 0,             '$root->start_byte' );
is( $root->end_byte,   length SOURCE, '$root->end_byte' );
ok( $root->is_named,                  '$root->is_named' );

ok( !$root->has_error, '$root has no errors' );

is_deeply( [ $root->start_point ], [ 0, 0 ], '$root->start_point' );
is_deeply( [ $root->end_point   ], [ 1, 0 ], '$root->end_point' );

is( $root->child_count, 3, '$root->child_count' );

my @nodes = $root->child_nodes;
is( scalar @nodes, 3, '$root->child_nodes returned 3 nodes' );

isa_ok( $nodes[0], "Text::Treesitter::Node", '$nodes[0]' );

is( $nodes[0]->type, "number", '$nodes[0]->type' );
is( $nodes[1]->type, "+",      '$nodes[1]->type' );
is( $nodes[2]->type, "number", '$nodes[2]->type' );

done_testing;
