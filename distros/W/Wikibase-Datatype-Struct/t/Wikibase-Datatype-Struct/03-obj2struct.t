use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Lexeme;
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::Property;
use Wikibase::Datatype::Struct;

# Test.
my $obj = Wikibase::Datatype::Item->new;
my $ret_hr = Wikibase::Datatype::Struct::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'ns' => 0,
		'type' => 'item',
	},
	'Output of obj2struct() subroutine. Empty item structure.',
);

# Test.
$obj = Wikibase::Datatype::Lexeme->new;
$ret_hr = Wikibase::Datatype::Struct::Lexeme::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'ns' => 146,
		'type' => 'lexeme',
	},
	'Output of obj2struct() subroutine. Empty lexeme structure.',
);

# Test.
$obj = Wikibase::Datatype::Mediainfo->new;
$ret_hr = Wikibase::Datatype::Struct::Mediainfo::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'descriptions' => {},
		'ns' => 6,
		'type' => 'mediainfo',
	},
	'Output of obj2struct() subroutine. Empty mediainfo structure.',
);

# Test.
$obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
$ret_hr = Wikibase::Datatype::Struct::Property::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'datatype' => 'external-id',
		'ns' => 120,
		'type' => 'property',
	},
	'Output of obj2struct() subroutine. Empty property structure (external-id).',
);

# Test.
eval {
	Wikibase::Datatype::Struct::obj2struct('bad');
};
is($EVAL_ERROR, "Base URI is required.\n",
	"Base URI is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
$obj = Wikibase::Datatype::Item->new;
eval {
	Wikibase::Datatype::Struct::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();
