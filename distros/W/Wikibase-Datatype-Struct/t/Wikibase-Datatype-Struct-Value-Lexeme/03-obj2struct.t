use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Lexeme;
use Wikibase::Datatype::Struct::Value::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Value::Lexeme->new(
	'value' => 'L42284',
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Lexeme::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'entity-type' => 'lexeme',
			'id' => 'L42284',
			'numeric-id' => 42284,
		},
		'type' => 'wikibase-entityid',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Lexeme'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Lexeme'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
