use strict;
$|++;

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

use Test::More 'no_plan';

# erase everything, so that we start fresh
my $index = XML::Comma::Def->_test_index_only->get_index ( "main" );
ok("if we didn't die, we're okay here");

my $it = $index->iterator();
while ( ++$it ) {
  my $doc = $it->retrieve_doc();
  #dbg 'id', $doc->doc_id();
  $doc->erase();
}
ok("if we didn't die, we're okay here");

my $second_index = XML::Comma::Def->_test_index_only->get_index ( "second" );

my $second_it = $second_index->iterator();
while ( ++$second_it ) {
  my $doc = $second_it->retrieve_doc();
  #dbg 'id', $doc->doc_id();
  $doc->erase();
}

my $doc = XML::Comma::Doc->new ( type => '_test_index_only' );
ok($doc);

$doc->time ( time );
$doc->string ( "foo" );
$doc->store ( store => 'main' );
ok("if we didn't die, we're okay here");

my $id = $doc->doc_id();
#dbg "id: $id\n";

undef $doc;
$doc = XML::Comma::Doc->read ( "_test_index_only|main|$id" );
ok($doc->string() eq 'foo');

$doc->get_lock();
$doc->erase();
ok("if we didn't die, we're okay here");

undef $doc;
eval {
  $doc = XML::Comma::Doc->read ( "_test_index_only|main|$id" );
};
ok($@);

# let's see how long it takes to create these things
my $how_many = 150;
my $stop_id = $id + $how_many;
my $first_time = time;

while ( $id < $stop_id ) {
  $doc = XML::Comma::Doc->new ( type => '_test_index_only' );
  $doc->time ( time );
  $doc->string ( "bar" );
  $doc->store ( store => 'main' );
  $id = $doc->doc_id();
}
ok("if we didn't die, we're okay here");

$doc = XML::Comma::Doc->read ( "_test_index_only|main|$id" );
my $last_time = $doc->time();
my $seconds = $last_time - $first_time;
ok("if we didn't die, we're okay here");

#dbg "created and stored $how_many docs in $seconds seconds";

foreach my $id ( 1 .. 10 ) {
  $doc = XML::Comma::Doc->new( type => '_test_index_only' );
  $doc->time( time );
  $doc->string( $id );
  $doc->store( store => 'second' );
  # warn $doc->doc_id();
}

