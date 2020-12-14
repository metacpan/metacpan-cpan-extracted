use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Time;
use Wikibase::Datatype::Struct::Value::Time;

# Test.
my $obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Time::obj2struct($obj,
	'http://www.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'after' => 0,
			'before' => 0,
			'calendarmodel' => 'http://www.wikidata.org/entity/Q1985727',
			'precision' => 11,
			'time' => '+2020-09-01T00:00:00Z',
			'timezone' => 0,
		},
		'type' => 'time',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Time::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Time'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Time'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Time::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
eval {
	Wikibase::Datatype::Struct::Value::Time::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();
