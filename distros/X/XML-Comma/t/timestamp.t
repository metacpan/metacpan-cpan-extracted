use strict;
use File::Path;

use Test::More 'no_plan';

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

####
my $def = XML::Comma::Def->read ( name => '_test_timestamp' );
rmtree $def->get_store('one')->base_directory, 0;
rmtree $def->get_store('two')->base_directory, 0;
rmtree $def->get_store('other')->base_directory, 0;
####

my $doc = XML::Comma::Doc->new ( type => '_test_timestamp' );
$doc->store ( store => 'one', keep_open => 1 );
my $doc_key = $doc->doc_key();
my $created = $doc->created();
my $last_modified = $doc->last_modified();

sleep 1;

$doc->store ( keep_open => 1 );
ok($doc->created eq $created);
ok($doc->last_modified > $last_modified);
$last_modified = $doc->last_modified;

sleep 1;

$doc->store ( keep_open => 1, no_mtime => 1 );
ok($doc->last_modified == $last_modified);

$created = $doc->created();
$last_modified = $doc->last_modified();

sleep 1;

#TODO: better document this case, it's confusing
$doc->store ( store => 'two', keep_open => 1 );
ok($doc->created eq $created);
ok($doc->last_modified > $last_modified);

$created = $doc->created();
$last_modified = $doc->last_modified();

sleep 1;

# shouldn't change, for 'other' store
$doc->store ( store => 'other' );
ok($doc->created eq $created);
ok($doc->last_modified eq $last_modified);

undef $doc;
$doc = XML::Comma::Doc->read ( $doc_key );
ok($doc->created()); #created defined and non-zero
ok($doc->last_modified()); #last_modified defined and non-zero

# test whether simple output of a non-writable doc causes problems
ok($doc->to_string());
