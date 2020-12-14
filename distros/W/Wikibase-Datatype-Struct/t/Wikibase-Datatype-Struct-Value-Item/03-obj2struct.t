use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Struct::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Value::Item->new(
	'value' => 'Q497',
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Item::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'entity-type' => 'item',
			'id' => 'Q497',
			'numeric-id' => 497,
		},
		'type' => 'wikibase-entityid',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Item::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Item'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Item'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Item::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
