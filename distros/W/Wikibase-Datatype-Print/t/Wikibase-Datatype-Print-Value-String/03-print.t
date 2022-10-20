use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Print::Value::String;

# Test.
my $obj = Wikibase::Datatype::Value::String->new(
	'value' => 'Text',
);
my $ret = Wikibase::Datatype::Print::Value::String::print($obj);
is($ret, 'Text', 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::String::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::String'.\n",
	"Object isn't 'Wikibase::Datatype::Value::String'.");
clean();
