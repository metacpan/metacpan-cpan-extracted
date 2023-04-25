use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Sense;
use Wikibase::Datatype::Struct::Value::Sense;

# Test.
my $obj = Wikibase::Datatype::Value::Sense->new(
	'value' => 'L34727-S1',
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Sense::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'id' => 'L34727-S1',
			'entity-type' => 'sense',
		},
		'type' => 'wikibase-entityid',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Sense::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Sense'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Sense'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Sense::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
