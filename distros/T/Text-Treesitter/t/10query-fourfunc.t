#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Text::Treesitter::Language;
use Text::Treesitter::Parser;
use Text::Treesitter::Query qw( TSQuantifierOne );
use Text::Treesitter::QueryCursor;
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

my $querysrc = read_text TREE_SITTER_LANGUAGE_FOURFUNC_DIR . "/queries/highlights.scm";
my $query = Text::Treesitter::Query->new( $lang, $querysrc );
isa_ok( $query, [ "Text::Treesitter::Query" ], '$query' );

ok( $query->pattern_count > 0, '$query has some patterns' );
ok( $query->capture_count > 0, '$query has some captures' );

my @capture_names = map { $query->capture_name_for_id( $_ ) } 0 .. $query->capture_count - 1;
is( [ @capture_names ], [ "number" ],
   'query defines some captures' );

my $source = "1 + 2";

my $tree = $p->parse_string( $source );
my $root = $tree->root_node;

my $qc = Text::Treesitter::QueryCursor->new;
isa_ok( $qc, [ "Text::Treesitter::QueryCursor" ], '$qc' );

$qc->exec( $query, $root );

my @matches;
while( my $match = $qc->next_match ) {
   foreach my $capture ( $match->captures ) {
      my $substr = $capture->node->text;

      my $capturename = $query->capture_name_for_id( $capture->capture_id );

      push @matches, [ $capturename, $substr ];

      is( $query->capture_quantifier_for_id( $match->pattern_index, $capture->capture_id ), TSQuantifierOne,
         '$query->capture_quantifier_for_id' );
   }
}

is( \@matches,
   [ [ number => "1" ], [ number => "2" ] ],
   'QueryCursor contained the right matches and captures' );

done_testing;
