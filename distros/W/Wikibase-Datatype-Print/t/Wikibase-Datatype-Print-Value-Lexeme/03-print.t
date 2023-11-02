use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
use Wikibase::Datatype::Value::Lexeme;
use Wikibase::Datatype::Print::Value::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Value::Lexeme->new(
	'value' => 'L42284',
);
my $ret = Wikibase::Datatype::Print::Value::Lexeme::print($obj);
is($ret, 'L42284', 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::Lexeme::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Lexeme'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Lexeme'.");
clean();

# Test.
SKIP: {
	skip 'No translation', 1;
	my $cache = Wikibase::Cache->new(
		'backend' => 'Basic',
	);
	$obj = Wikibase::Datatype::Value::Lexeme->new(
		'value' => 'L42284',
	);
	$ret = Wikibase::Datatype::Print::Value::Lexeme::print($obj, {
		'cb' => $cache,
	});
	is($ret, 'metre', 'Get printed value (translated).');
}

# Test.
my $cache = Wikibase::Cache->new(
	'backend' => 'Basic',
);
$obj = Wikibase::Datatype::Value::Lexeme->new(
	'value' => 'L42284',
);
$ret = Wikibase::Datatype::Print::Value::Lexeme::print($obj, {
	'cb' => $cache,
});
is($ret, 'L42284', 'Get printed value (not translated).');

# Test.
$obj = Wikibase::Datatype::Value::Lexeme->new(
	'value' => 'L42284',
);
eval {
	Wikibase::Datatype::Print::Value::Lexeme::print($obj, {
		'cb' => 'bad_callback',
	});
};
is($EVAL_ERROR, "Option 'cb' must be a instance of Wikibase::Cache.\n",
	"Option 'cb' must be a instance of Wikibase::Cache.");
clean();
