use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Struct::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad.'),
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Monolingual::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'language' => 'cs',
			'text' => decode_utf8('Příklad.'),
		},
		'type' => 'monolingualtext',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Monolingual::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Monolingual'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Monolingual'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Monolingual::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
