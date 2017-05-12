use strict;
use File::Path;

use Test::More 'no_plan';

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

###########
## make def
my $def = XML::Comma::Def->read ( name => '_test_doc_read_blob_validation' );
ok($def);

## create the doc, then write some data to the blob_element
my ( $doc, $doc_key, $doc_location );
eval {
  $doc = XML::Comma::Doc->new ( type=> '_test_doc_read_blob_validation' );
  $doc->element( 'data_blob' )->set( 'test' );
  $doc->store( store=> 'main' );
  $doc_key = $doc->doc_key();
  $doc_location = $doc->doc_location();
};
ok(!$@);

# now try to read and retrieve it to make sure it validates the blob_element successfully
my $read_doc = XML::Comma::Doc->read( $doc_key, validate=> 1 );
ok($read_doc);

my $retrieved_doc = XML::Comma::Doc->retrieve( $doc_key, validate=> 1 );
ok($retrieved_doc);

# i guess it should also work without validation?
undef $read_doc;
$read_doc = XML::Comma::Doc->read( $doc_key, validate=> 0 );
ok($read_doc);

undef $retrieved_doc;
$retrieved_doc = XML::Comma::Doc->retrieve( $doc_key, validate=> 0 );
ok($retrieved_doc);

# it should fail if we try to create a blob_element-containing doc by reading in a file
eval { my $doc = XML::Comma::Doc->new ( file=> $doc_location ); };
ok($@);
