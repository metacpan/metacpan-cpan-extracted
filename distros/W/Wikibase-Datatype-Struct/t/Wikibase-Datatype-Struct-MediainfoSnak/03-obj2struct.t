use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Struct::MediainfoSnak;

# Test.
my $obj = Wikibase::Datatype::MediainfoSnak->new(
	'datavalue' => Wikibase::Datatype::Value::String->new(
		'value' => '1.1',
	),
	'property' => 'P11',
);
my $ret_hr = Wikibase::Datatype::Struct::MediainfoSnak::obj2struct($obj,
	'https://test.wikidata.org/entity');
is_deeply(
	$ret_hr,
	{
		'datavalue' => {
			'type' => 'string',
			'value' => '1.1',
		},
		'property' => 'P11',
		'snaktype' => 'value',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::MediainfoSnak::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::MediainfoSnak'.\n",
	"Object isn't 'Wikibase::Datatype::MediainfoSnak'.");
clean();

# Test.
$obj = Wikibase::Datatype::MediainfoSnak->new(
	'datavalue' => Wikibase::Datatype::Value::String->new(
		'value' => '1.1',
	),
	'property' => 'P11',
);
eval {
	Wikibase::Datatype::Struct::MediainfoSnak::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::MediainfoSnak::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
$obj = Wikibase::Datatype::MediainfoSnak->new(
	'property' => 'P11',
	'snaktype' => 'novalue',
);
$ret_hr = Wikibase::Datatype::Struct::MediainfoSnak::obj2struct($obj,
	'https://test.wikidata.org/entity');
is_deeply(
	$ret_hr,
	{
		'property' => 'P11',
		'snaktype' => 'novalue',
	},
	'Output of obj2struct() subroutine with snaktype novalue.',
);

# Test.
$obj = Wikibase::Datatype::MediainfoSnak->new(
	'property' => 'P11',
	'snaktype' => 'somevalue',
);
$ret_hr = Wikibase::Datatype::Struct::MediainfoSnak::obj2struct($obj,
	'https://test.wikidata.org/entity');
is_deeply(
	$ret_hr,
	{
		'property' => 'P11',
		'snaktype' => 'somevalue',
	},
	'Output of obj2struct() subroutine with snaktype somevalue.',
);
