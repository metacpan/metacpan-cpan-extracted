use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Struct::Value::String;

# Test.
my $obj = Wikibase::Datatype::Value::String->new(
	'value' => 'Text',
);
my $ret_hr = Wikibase::Datatype::Struct::Value::String::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => 'Text',
		'type' => 'string',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::String::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::String'.\n",
	"Object isn't 'Wikibase::Datatype::Value::String'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::String::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
