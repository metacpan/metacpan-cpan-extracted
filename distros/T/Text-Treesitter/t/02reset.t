#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

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
my $lang = Text::Treesitter::Language::load( TREE_SITTER_LANGUAGE_FOURFUNC, "fourfunc" );
$p->set_language( $lang );

sub walk_tree
{
   my ( $node ) = @_;

   return sprintf "%s[%s]",
      $node->type,
      join " ", map { walk_tree( $_ ) } $node->child_nodes;
}

my $tree1 = $p->parse_string( "1 + 2" );
my $root1 = $tree1->root_node;
is( walk_tree( $root1 ), "fourfunc[number[] +[] number[]]", 'walk_tree of root1' );

$p->reset;

my $tree2 = $p->parse_string( "3 * 4" );
my $root2 = $tree2->root_node;
is( walk_tree( $root2 ), "fourfunc[number[] *[] number[]]", 'walk_tree of root2 after reset' );

done_testing;
