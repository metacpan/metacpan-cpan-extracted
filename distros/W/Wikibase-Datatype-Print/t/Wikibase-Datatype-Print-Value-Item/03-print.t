use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Print::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Value::Item->new(
	'value' => 'Q497',
);
my $ret = Wikibase::Datatype::Print::Value::Item::print($obj);
is($ret, 'Q497', 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::Item::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Item'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Item'.");
clean();

# Test.
my $cache = Wikibase::Cache::Backend::Basic->new;
$obj = Wikibase::Datatype::Value::Item->new(
	'value' => 'Q11573',
);
$ret = Wikibase::Datatype::Print::Value::Item::print($obj, {
	'cb' => $cache,
});
is($ret, 'metre', 'Get printed value (translated).');
