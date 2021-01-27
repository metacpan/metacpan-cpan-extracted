use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 15;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::MediainfoSnak;

# Test.
my $struct_hr = {
	'datavalue' => {
		'type' => 'string',
		'value' => '1.1',
	},
	'property' => 'P11',
	'snaktype' => 'value',
};
my $ret = Wikibase::Datatype::Struct::MediainfoSnak::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::MediainfoSnak');
isa_ok($ret->datavalue, 'Wikibase::Datatype::Value::String');
is($ret->property, 'P11', 'Method property().');
is($ret->snaktype, 'value', 'Method snaktype().');

# Test.
$struct_hr = {
	'property' => 'P11',
	'snaktype' => 'novalue',
};
$ret = Wikibase::Datatype::Struct::MediainfoSnak::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::MediainfoSnak');
is($ret->datavalue, undef, 'No value.');
is($ret->property, 'P11', 'Method property().');
is($ret->snaktype, 'novalue', 'Method snaktype().');

# Test.
$struct_hr = {
	'property' => 'P11',
	'snaktype' => 'novalue',
};
$ret = Wikibase::Datatype::Struct::MediainfoSnak::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::MediainfoSnak');
is($ret->property, 'P11', 'Method property().');
is($ret->snaktype, 'novalue', 'Method snaktype().');

# Test.
$struct_hr = {
	'property' => 'P11',
	'snaktype' => 'somevalue',
};
$ret = Wikibase::Datatype::Struct::MediainfoSnak::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::MediainfoSnak');
is($ret->property, 'P11', 'Method property().');
is($ret->snaktype, 'somevalue', 'Method snaktype().');
