use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Struct::Value::Monolingual;

# Test.
my $struct_hr = {
	'value' => {
		'language' => 'cs',
		'text' => decode_utf8('Příklad.'),
	},
	'type' => 'monolingualtext',
};
my $ret = Wikibase::Datatype::Struct::Value::Monolingual::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Monolingual');
is($ret->value, decode_utf8('Příklad.'), 'Method value().');
is($ret->language, 'cs', 'Method language().');
is($ret->type, 'monolingualtext', 'Method type().');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Value::Monolingual::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'monolingualtext' datatype.\n",
	"Structure isn't for 'monolingualtext' datatype (no type).");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Value::Monolingual::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'monolingualtext' datatype.\n",
	"Structure isn't for 'monolingualtext' datatype (bad type).");
clean();
