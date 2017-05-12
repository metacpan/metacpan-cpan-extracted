#!/usr/bin/perl -w
$|++;

use lib ".test/lib/";

use XML::Comma;
use File::Path;

use strict;

use Test::More tests => 17;

eval { XML::Comma::Def->_test_multi_index_bad_one };
ok( $@ );

eval { XML::Comma::Def->_test_multi_index_bad_two };
ok( $@ );

eval { XML::Comma::Def->_test_multi_index_bad_three };
ok( $@ );

ok( XML::Comma::Def->_test_multi_index_one );
ok( XML::Comma::Def->_test_multi_index_two );

my $one_doc = XML::Comma::Doc->new( type => "_test_multi_index_one" );
$one_doc->foo( "one_foo" );
$one_doc->bar( "one_bar" );
$one_doc->store( store => "one" );
$one_doc->store( store => "two" );

my $two_doc = XML::Comma::Doc->new( type => "_test_multi_index_two" );
$two_doc->foo( "two_foo" );
$two_doc->bar( "two_bar" );
$two_doc->store( store => "one" );
$two_doc->store( store => "two" );

my $one_only_one = XML::Comma::Def->_test_multi_index_one
                                  ->get_index( "only_one" );

my $one_only_two = XML::Comma::Def->_test_multi_index_one
                                  ->get_index( "only_two" );

my $one_all = XML::Comma::Def->_test_multi_index_one
                                  ->get_index( "all" );

ok( $one_only_one->count() == 1 );
ok( $one_only_two->count() == 1 );
ok( $one_all->count() == 4 );

my $one_all_iter = $one_all->iterator();
while ( ++$one_all_iter ) {
  my $doc = $one_all_iter->doc_read();
  $doc->get_lock();
  $doc->index_remove( index => "_test_multi_index_one:all" );
}

ok( $one_all->count() == 0 );
$one_all->rebuild( stores => ['_test_multi_index_two:one', 
                              '_test_multi_index_two:two' ] );

ok( $one_all->count() == 2 );

$one_all_iter->iterator_refresh();
++$one_all_iter;
ok( $one_all_iter->doc_key eq '_test_multi_index_two|one|001' );
++$one_all_iter;
ok( $one_all_iter->doc_key eq '_test_multi_index_two|two|001' );

$one_all->rebuild();
ok( $one_all->count() == 4 );

$one_all_iter->iterator_refresh();
++$one_all_iter;
ok( $one_all_iter->doc_key eq '_test_multi_index_one|one|001' );
++$one_all_iter;
ok( $one_all_iter->doc_key eq '_test_multi_index_one|two|001' );
++$one_all_iter;
ok( $one_all_iter->doc_key eq '_test_multi_index_two|one|001' );
++$one_all_iter;
ok( $one_all_iter->doc_key eq '_test_multi_index_two|two|001' );

# clean up
$one_all_iter->iterator_refresh();
while ( ++$one_all_iter ) {
  $one_all_iter->retrieve_doc()->erase();
}
