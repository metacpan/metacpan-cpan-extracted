use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Print::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad.'),
);
my $ret = Wikibase::Datatype::Print::Value::Monolingual::print($obj);
is($ret, decode_utf8('Příklad. (cs)'), 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::Monolingual::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Monolingual'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Monolingual'.");
clean();
