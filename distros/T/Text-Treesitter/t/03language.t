#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Text::Treesitter::Language;

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

# These values are quite fragile to the grammar definition
is( $lang->symbol_count, 10, '$lang->symbol_count' );

my %symbols_by_name = map { $_->name, $_ } $lang->symbols;

ok( exists $symbols_by_name{"+"}, '$lang has a + symbol' );
ok( $symbols_by_name{"+"}->type_is_anonymous, '$lang + symbol is anonymous' );

is( $lang->field_count, 0, '$lang->field_count' );

done_testing;
