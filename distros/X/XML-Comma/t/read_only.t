#!/usr/bin/perl -w

use strict;
use File::Path;

use Test::More 'no_plan';

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg random_an_string );

sub modify {
  my $doc = shift();
  $doc->element('a')->set( random_an_string(8) );
  $doc->b()->element('b_1')->set ( random_an_string(8) );
  $doc->b()->b_2()->element('b_2_1')->set ( random_an_string(8) );
  $doc->c()->set ( random_an_string(8) );

  $doc->a ( 'some', 'more', 'elements' );
  $doc->delete_element ( $doc->elements('a')->[-1] );

  $doc->b()->b_1 ( 'some', 'more', 'elements' );
  $doc->b()->delete_element ( $doc->b()->elements('b_1')->[-1] );

  $doc->b()->b_2()->b_2_1 ( 'some', 'more', 'elements' );
  $doc->b()->b_2()->delete_element 
    ( $doc->b()->b_2()->elements('b_2_1')->[-1] );
}

my $doc = XML::Comma::Doc->new ( type => '_test_read_only' );

rmtree ( $doc->def()->get_store('main')->base_directory(), 0 );

# store keeping open
$doc->store ( store=>'main', keep_open => 1 );
&modify ( $doc );
ok("store keeping open");

# copy keeping open
$doc->copy( keep_open => 1 );
&modify ( $doc );
ok("copy keeping open");

# store again
$doc->store();
eval { &modify ( $doc ); };
ok( $@ );


$doc = XML::Comma::Doc->new ( type => '_test_read_only' );

# store
$doc->store( store=>'main' );
eval { &modify ( $doc ); };
ok( $@ );

# get lock
$doc->get_lock();
&modify ( $doc );
ok("get lock after store");

# copy
$doc->copy();
eval { &modify ( $doc ); };
ok( $@ );

# get lock
$doc->get_lock();
&modify ( $doc );
ok("get lock after copy");

# unlock
$doc->doc_unlock();
eval { &modify ( $doc ); };
ok( $@ );

# aaah
