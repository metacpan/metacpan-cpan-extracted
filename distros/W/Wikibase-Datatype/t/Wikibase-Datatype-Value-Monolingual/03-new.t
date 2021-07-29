use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad'),
);
isa_ok($obj, 'Wikibase::Datatype::Value::Monolingual');

# Test.
eval {
	Wikibase::Datatype::Value::Monolingual->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
$obj = Wikibase::Datatype::Value::Monolingual->new(
	'value' => 'foo',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Monolingual');

# Test.
eval {
	Wikibase::Datatype::Value::Monolingual->new(
		'language' => 'xx',
		'value' => 'foo',
	);
};
is($EVAL_ERROR, "Language with ISO 639-1 code 'xx' doesn't exist.\n",
	"Language with ISO 639-1 code 'xx' doesn't exist.");

# Test.
eval {
	Wikibase::Datatype::Value::Monolingual->new(
		'language' => 'ger',
		'value' => 'foo',
	);
};
is($EVAL_ERROR, "Language code 'ger' isn't ISO 639-1 code.\n",
	"Language code 'ger' isn't ISO 639-1 code.");
