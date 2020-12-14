use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 12;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Snak;

# Test.
my $struct_hr = {
	'datatype' => 'string',
	'datavalue' => {
		'type' => 'string',
		'value' => '1.1',
	},
	'property' => 'P11',
	'snaktype' => 'value',
};
my $ret = Wikibase::Datatype::Struct::Snak::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Snak');
is($ret->datatype, 'string', 'Method datatype().');
isa_ok($ret->datavalue, 'Wikibase::Datatype::Value::String');
is($ret->property, 'P11', 'Method property().');
is($ret->snaktype, 'value', 'Method snaktype().');

# Test.
$struct_hr = {
	'datatype' => 'wikibase-item',
	'property' => 'P11',
	'snaktype' => 'novalue',
};
$ret = Wikibase::Datatype::Struct::Snak::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Snak');
is($ret->datatype, 'wikibase-item', 'Method datatype().');
is($ret->datavalue, undef, 'No value.');
is($ret->property, 'P11', 'Method property().');
is($ret->snaktype, 'novalue', 'Method snaktype().');

# Test.
$struct_hr = {
	'datatype' => 'wikibase-item',
};
eval {
	Wikibase::Datatype::Struct::Snak::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Parameter 'datavalue' is required.\n",
	"Parameter 'datavalue' is required.");
clean();
