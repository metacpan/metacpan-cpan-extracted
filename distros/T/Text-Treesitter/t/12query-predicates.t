#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Text::Treesitter::Language;
use Text::Treesitter::Parser;
use Text::Treesitter::Query;
use Text::Treesitter::QueryCursor;
use Text::Treesitter::QueryMatch;
use Text::Treesitter::Tree;

use File::Slurper qw( read_text );

use constant TREE_SITTER_LANGUAGE_FOURFUNC_DIR => "languages/tree-sitter-fourfunc";

unless( -d TREE_SITTER_LANGUAGE_FOURFUNC_DIR ) {
   plan skip_all => "No fourfunc language dir " . TREE_SITTER_LANGUAGE_FOURFUNC_DIR;
}

use constant TREE_SITTER_LANGUAGE_FOURFUNC => TREE_SITTER_LANGUAGE_FOURFUNC_DIR . "/tree-sitter-fourfunc.so";
unless( -f TREE_SITTER_LANGUAGE_FOURFUNC ) {
   require Text::Treesitter::Language;
   Text::Treesitter::Language::build( TREE_SITTER_LANGUAGE_FOURFUNC, TREE_SITTER_LANGUAGE_FOURFUNC_DIR );
}

my $lang = Text::Treesitter::Language::load( TREE_SITTER_LANGUAGE_FOURFUNC, "fourfunc" );
my $p = Text::Treesitter::Parser->new;
$p->set_language( $lang );

my $querysrc = read_text TREE_SITTER_LANGUAGE_FOURFUNC_DIR . "/queries/zero.scm";
my $query = Text::Treesitter::Query->new( $lang, $querysrc );

my $source = "123 + 0";

my $tree = $p->parse_string( $source );
my $root = $tree->root_node;

my $qc = Text::Treesitter::QueryCursor->new;
isa_ok( $qc, "Text::Treesitter::QueryCursor", '$qc' );

$qc->exec( $query, $root );

my @matches;
while( my $match = $qc->next_match ) {
   next unless $query->test_predicates_for_match( $tree, $match );

   foreach my $capture ( $match->captures ) {
      my $node = $capture->node;
      my $substr = substr( $source, $node->start_byte, $node->end_byte - $node->start_byte );

      my $capturename = $query->capture_name_for_id( $capture->capture_id );

      push @matches, [ $capturename, $substr ];
   }
}

is_deeply( \@matches,
   [ [ number => "0" ], [ zero => "0" ] ],
   'QueryCursor contained the right matches and captures' );

done_testing;
