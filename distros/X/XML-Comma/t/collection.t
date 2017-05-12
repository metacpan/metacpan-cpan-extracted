#!/usr/bin/perl

use lib ".test/lib/";

use warnings;
use strict;

use Test::More 'no_plan';
use XML::Comma;

my ( $num_docs, $last_id ) = make_docs();

ok( $num_docs == 3 );

my $index = XML::Comma::Def->read( name => "_test_collection" )
                           ->get_index( "main" );


my $iterator = $index->iterator( 
  collection_spec => "free_tag_a:girl AND free_tag_b:serious",
  textsearch_spec => "text:bob ross",
#  where_clause    => "doc_id = '$last_id'",
  order_by        => "name",
);

ok( $iterator->name eq 'Sally' );
ok( 4 == scalar $iterator->free_tag_a() );
$iterator++;
ok( $iterator->name eq 'Sandra' );
ok( join("/", $iterator->free_tag_a()) eq 'girl/silly' );


$iterator = $index->iterator();
while ( $iterator++ ) {
  $iterator->retrieve_doc()->erase();
}

sub make_docs {
  my $doc = XML::Comma::Doc->new( type => "_test_collection" );

  my $num_docs = 0;

  $doc->name( "Sally" );
  $doc->add_element( "free_tag_a" )->set( "girl" );
  $doc->add_element( "free_tag_a" )->set( "sassy" );
  $doc->add_element( "free_tag_a" )->set( "spunky" );
  $doc->add_element( "free_tag_a" )->set( "silly" );
  $doc->add_element( "free_tag_b" )->set( "girl" );
  $doc->add_element( "free_tag_b" )->set( "scholar" );
  $doc->add_element( "free_tag_b" )->set( "shaman" );
  $doc->add_element( "free_tag_b" )->set( "serious" );
  $doc->element( "text" )->set( "bob ross" );
  $doc->store( store => "main" );
  $num_docs++;
  
  $doc = XML::Comma::Doc->new( type => "_test_collection" );
  $doc->name( "Sandy" );
  $doc->add_element( "free_tag_a" )->set( "girl" );
  $doc->add_element( "free_tag_a" )->set( "sassy" );
  $doc->add_element( "free_tag_a" )->set( "spunky" );
  $doc->add_element( "free_tag_b" )->set( "scholar" );
  $doc->add_element( "free_tag_b" )->set( "shaman" );
  $doc->element( "text" )->set( "bob ross" );
  $doc->store( store => "main" );
  $num_docs++;
  
  $doc = XML::Comma::Doc->new( type => "_test_collection" );
  $doc->name( "Sandra" );
  $doc->add_element( "free_tag_a" )->set( "girl" );
  $doc->add_element( "free_tag_a" )->set( "silly" );
  $doc->add_element( "free_tag_b" )->set( "serious" );
  $doc->element( "text" )->set( "bob ross" );
  $doc->store( store => "main" );
  $num_docs++;
  
  return ($num_docs, $doc->doc_id);
}  
