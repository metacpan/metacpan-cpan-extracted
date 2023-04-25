use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Sense;
use Wikibase::Datatype::Print::Value::Sense;

# Test.
my $obj = Wikibase::Datatype::Value::Sense->new(
	'value' => 'L34727-S1',
);
my $ret = Wikibase::Datatype::Print::Value::Sense::print($obj);
is($ret, 'L34727-S1', 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::Sense::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Sense'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Sense'.");
clean();
