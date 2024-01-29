#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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

my $source = "123 + 4 * 0";

my $tree = $p->parse_string( $source );
my $root = $tree->root_node;

my $qc = Text::Treesitter::QueryCursor->new;
isa_ok( $qc, [ "Text::Treesitter::QueryCursor" ], '$qc' );

# next_match
{
   $qc->exec( $query, $root );

   my @matches;
   while( my $match = $qc->next_match ) {
      next unless $query->test_predicates_for_match( $match );

      foreach my $capture ( $match->captures ) {
         my $node = $capture->node;
         my $substr = substr( $source, $node->start_byte, $node->end_byte - $node->start_byte );

         my $capturename = $query->capture_name_for_id( $capture->capture_id );

         push @matches, [ $capturename, $substr ];
      }
   }

   is( \@matches,
      [ [ number => "0" ], [ zero => "0" ] ],
      'QueryCursor contained the right matches and captures' );
}

# next_match_captures
{
   $qc->exec( $query, $root );

   my @captures;
   while( my $captures = $qc->next_match_captures ) {
      push @captures, $captures;
   }

   is( \@captures,
      [ { number => check_isa("Text::Treesitter::Node"), zero => check_isa("Text::Treesitter::Node") } ],
      'QueryCursor yields captures from ->next_match_captures' );
}

# next_match_captures multi
{
   $qc->exec( $query, $root );

   my @captures;
   while( my $captures = $qc->next_match_captures( multi => 1 ) ) {
      push @captures, $captures;
   }

   is( \@captures,
      [ { number => [ check_isa("Text::Treesitter::Node") ], zero => [ check_isa("Text::Treesitter::Node") ] } ],
      'QueryCursor yields captures from ->next_match_captures' );
}

# #has-parent? predicate
{
   my $query = Text::Treesitter::Query->new( $lang, '((expr) @expr (#has-parent? @expr expr))' );

   $qc->exec( $query, $root );

   my @matches;
   while( my $match = $qc->next_match ) {
      next unless $query->test_predicates_for_match( $match );

      push @matches, {};

      foreach my $capture ( $match->captures ) {
         $matches[-1]{ $query->capture_name_for_id( $capture->capture_id ) } = $capture->node->debug_sprintf;
      }
   }

   is( \@matches,
      [ { expr => q[(expr (number) operator: "*" (number))] } ],
      'query with #has-parent? predicate' );
}

# #has-ancestor? predicate
{
   my $query = Text::Treesitter::Query->new( $lang, '((expr) @expr (#has-ancestor? @expr expr))' );

   $qc->exec( $query, $root );

   my @matches;
   while( my $match = $qc->next_match ) {
      next unless $query->test_predicates_for_match( $match );

      push @matches, {};

      foreach my $capture ( $match->captures ) {
         $matches[-1]{ $query->capture_name_for_id( $capture->capture_id ) } = $capture->node->debug_sprintf;
      }
   }

   is( \@matches,
      [ { expr => q[(expr (number) operator: "*" (number))] } ],
      'query with #has-parent? predicate' );
}

# #set! directive
{
   my $query = Text::Treesitter::Query->new( $lang, '((expr) @expr (#set! meta "1234"))' );

   $qc->exec( $query, $root );

   my @captures;
   while( my $captures = $qc->next_match_captures ) {
      push @captures, $captures;
   }

   is( \@captures,
      [ { expr => check_isa( "Text::Treesitter::Node" ), meta => "1234" },
        { expr => check_isa( "Text::Treesitter::Node" ), meta => "1234" }, ],
      'query with #set! directive' );
}

done_testing;
