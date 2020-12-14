use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Property;

# Test.
my $struct_hr = {
	'value' => {
		'numeric-id' => 111,
		'id' => 'P111',
		'entity-type' => 'property',
	},
	'type' => 'wikibase-entityid',
};
my $ret = Wikibase::Datatype::Struct::Value::Property::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Property');
is($ret->value, 'P111', 'Method value().');
is($ret->type, 'property', 'Method type().');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Value::Property::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'property' datatype.\n",
	"Structure isn't for 'property' datatype (no type).");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Value::Property::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'property' datatype.\n",
	"Structure isn't for 'property' datatype (bad type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
};
eval {
	Wikibase::Datatype::Struct::Value::Property::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'property' datatype.\n",
	"Structure isn't for 'property' datatype (no value/entity-type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {
		'entity-type' => 'bad',
	},
};
eval {
	Wikibase::Datatype::Struct::Value::Property::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'property' datatype.\n",
	"Structure isn't for 'property' datatype (bad value/entity-type).");
clean();
