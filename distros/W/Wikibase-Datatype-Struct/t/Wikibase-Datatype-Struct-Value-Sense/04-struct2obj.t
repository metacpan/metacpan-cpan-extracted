use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Sense;

# Test.
my $struct_hr = {
	'value' => {
		'id' => 'L34727-S1',
		'entity-type' => 'sense',
	},
	'type' => 'wikibase-entityid',
};
my $ret = Wikibase::Datatype::Struct::Value::Sense::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Sense');
is($ret->value, 'L34727-S1', 'Method value().');
is($ret->type, 'sense', 'Method type().');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Value::Sense::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'sense' datatype.\n",
	"Structure isn't for 'sense' datatype (no type).");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Value::Sense::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'sense' datatype.\n",
	"Structure isn't for 'sense' datatype (bad type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
};
eval {
	Wikibase::Datatype::Struct::Value::Sense::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'sense' datatype.\n",
	"Structure isn't for 'sense' datatype (no value/entity-type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {
		'entity-type' => 'bad',
	},
};
eval {
	Wikibase::Datatype::Struct::Value::Sense::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'sense' datatype.\n",
	"Structure isn't for 'sense' datatype (bad value/entity-type).");
clean();
