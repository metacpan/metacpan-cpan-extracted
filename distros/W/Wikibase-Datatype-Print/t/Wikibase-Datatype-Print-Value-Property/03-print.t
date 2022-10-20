use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;
use Wikibase::Datatype::Value::Property;
use Wikibase::Datatype::Print::Value::Property;

# Test.
my $obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P123',
);
my $ret = Wikibase::Datatype::Print::Value::Property::print($obj);
is($ret, 'P123', 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::Property::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Property'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Property'.");
clean();

# Test.
my $cache = Wikibase::Cache::Backend::Basic->new;
$obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P31',
);
$ret = Wikibase::Datatype::Print::Value::Property::print($obj, {
	'cb' => $cache,
});
is($ret, 'instance of', 'Get printed value (translated).');
