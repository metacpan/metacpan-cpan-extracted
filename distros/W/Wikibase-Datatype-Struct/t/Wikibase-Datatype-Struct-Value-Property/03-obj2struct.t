use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Property;
use Wikibase::Datatype::Struct::Value::Property;

# Test.
my $obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P111',
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Property::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'id' => 'P111',
			'entity-type' => 'property',
			'numeric-id' => 111,
		},
		'type' => 'wikibase-entityid',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Property::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Property'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Property'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Property::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
