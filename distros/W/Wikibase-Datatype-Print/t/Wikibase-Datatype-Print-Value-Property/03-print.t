use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Wikibase::Cache;
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
my $cache = Wikibase::Cache->new(
	'backend' => 'Basic',
);
$obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P31',
);
$ret = Wikibase::Datatype::Print::Value::Property::print($obj, {
	'cb' => $cache,
});
is($ret, 'instance of', 'Get printed value (translated).');

# Test.
$cache = Wikibase::Cache->new(
	'backend' => 'Basic',
);
$obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P1963',
);
$ret = Wikibase::Datatype::Print::Value::Property::print($obj, {
	'cb' => $cache,
});
is($ret, 'P1963', 'Get printed value (not translated).');

# Test.
$obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P31',
);
eval {
	Wikibase::Datatype::Print::Value::Property::print($obj, {
		'cb' => 'bad_callback',
	});
};
is($EVAL_ERROR, "Option 'cb' must be a instance of Wikibase::Cache.\n",
	"Option 'cb' must be a instance of Wikibase::Cache.");
clean();
