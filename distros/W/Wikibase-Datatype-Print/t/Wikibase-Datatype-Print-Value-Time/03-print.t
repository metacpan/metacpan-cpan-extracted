use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
use Wikibase::Datatype::Value::Time;
use Wikibase::Datatype::Print::Value::Time;

# Test.
my $obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
my $ret = Wikibase::Datatype::Print::Value::Time::print($obj);
is($ret, '01 September 2020 (Q1985727)', 'Get printed value. Default printing.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::Time::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Time'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Time'.");
clean();

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
$ret = Wikibase::Datatype::Print::Value::Time::print($obj, {});
is($ret, '01 September 2020 (Q1985727)', 'Get printed value. Only QID.');

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
my $cache = Wikibase::Cache->new(
	'backend' => 'Basic',
);
$ret = Wikibase::Datatype::Print::Value::Time::print($obj, {
	'cb' => $cache,
	'print_name' => 1,
});
is($ret, '01 September 2020 (proleptic Gregorian calendar)', 'Get printed value. Explicit mapping.');

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
eval {
	Wikibase::Datatype::Print::Value::Time::print($obj, {
		'cb' => 'bad_callback',
	});
};
is($EVAL_ERROR, "Option 'cb' must be a instance of Wikibase::Cache.\n",
	"Option 'cb' must be a instance of Wikibase::Cache.");
clean();
