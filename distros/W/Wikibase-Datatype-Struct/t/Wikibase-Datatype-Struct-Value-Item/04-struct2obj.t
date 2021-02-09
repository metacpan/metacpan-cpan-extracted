use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 11;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Item;

# Test.
my $struct_hr = {
	'value' => {
		'numeric-id' => 497,
		'id' => 'Q497',
		'entity-type' => 'item',
	},
	'type' => 'wikibase-entityid',
};
my $ret = Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Item');
is($ret->value, 'Q497', 'Method value().');
is($ret->type, 'item', 'Method type().');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'item' datatype.\n",
	"Structure isn't for 'item' datatype (blank structure).");
clean();

# Test.
$struct_hr = {
	'type' => undef,
};
eval {
	Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'item' datatype.\n",
	"Structure isn't for 'item' datatype (type is undefined).");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'item' datatype.\n",
	"Structure isn't for 'item' datatype (bad type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
};
eval {
	Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'item' datatype.\n",
	"Structure isn't for 'item' datatype (only filled type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {},
};
eval {
	Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'item' datatype.\n",
	"Structure isn't for 'item' datatype (value is blank).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {
		'entity-type' => undef,
	},
};
eval {
	Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'item' datatype.\n",
	"Structure isn't for 'item' datatype (value has only entity-type with null).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {
		'entity-type' => 'bad',
	},
};
eval {
	Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'item' datatype.\n",
	"Structure isn't for 'item' datatype (value has only entity-type with bad value).");
clean();
