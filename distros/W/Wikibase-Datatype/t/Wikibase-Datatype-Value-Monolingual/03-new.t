use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 10;
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
is($EVAL_ERROR, "Language code 'xx' isn't code supported by Wikibase.\n",
	"Language code 'xx' isn't code supported by Wikibase.");

# Test.
eval {
	Wikibase::Datatype::Value::Monolingual->new(
		'language' => 'ger',
		'value' => 'foo',
	);
};
is($EVAL_ERROR, "Language code 'ger' isn't code supported by Wikibase.\n",
	"Language code 'ger' isn't code supported by Wikibase.");

# Test.
$Wikibase::Datatype::Utils::SKIP_CHECK_LANG = 1;
$obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'ger',
	'value' => 'foo',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Monolingual');

# Test.
$Wikibase::Datatype::Utils::SKIP_CHECK_LANG = 0;
@Wikibase::Datatype::Utils::LANGUAGE_CODES = ('ger');
$obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'ger',
	'value' => 'foo',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Monolingual');

# Test.
$Wikibase::Datatype::Utils::SKIP_CHECK_LANG = 0;
@Wikibase::Datatype::Utils::LANGUAGE_CODES = ('yy');
eval {
	Wikibase::Datatype::Value::Monolingual->new(
		'language' => 'ger',
		'value' => 'foo',
	);
};
is($EVAL_ERROR, "Language code 'ger' isn't user defined language code.\n",
	"Language code 'ger' isn't user defined language code.");

# Test.
$Wikibase::Datatype::Utils::SKIP_CHECK_LANG = 1;
@Wikibase::Datatype::Utils::LANGUAGE_CODES = ('yy');
$obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'ger',
	'value' => 'foo',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Monolingual');
