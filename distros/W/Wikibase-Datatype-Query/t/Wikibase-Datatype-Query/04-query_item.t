use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Wikibase::Datatype::Query;

# Common.
my $item = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

# Test.
my $obj = Wikibase::Datatype::Query->new;
eval {
	$obj->query_item;
};
is($EVAL_ERROR, "Item is required.\n", "Item is required.");
clean();

# Test.
$obj = Wikibase::Datatype::Query->new;
eval {
	$obj->query_item('bad');
};
is($EVAL_ERROR, "Item must be a 'Wikibase::Datatype::Item' or 'Wikibase::Datatype::Mediainfo' object.\n",
	"Item must be a 'Wikibase::Datatype::Item' or 'Wikibase::Datatype::Mediainfo' object. (bad).");
clean();

# Test.
$obj = Wikibase::Datatype::Query->new;
eval {
	$obj->query_item(Test::MockObject->new);
};
is($EVAL_ERROR, "Item must be a 'Wikibase::Datatype::Item' or 'Wikibase::Datatype::Mediainfo' object.\n",
	"Item must be a 'Wikibase::Datatype::Item' or 'Wikibase::Datatype::Mediainfo' object. (Test::MockObject).");
clean();

# Test.
$obj = Wikibase::Datatype::Query->new;
eval {
	$obj->query_item($item, 'bad');
};
is($EVAL_ERROR, "Unsupported query string 'bad'.\n", "Unsupported query string 'bad'.");
clean();
