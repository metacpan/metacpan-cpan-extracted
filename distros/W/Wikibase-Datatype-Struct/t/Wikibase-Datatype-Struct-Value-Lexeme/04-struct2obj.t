use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 11;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Lexeme;

# Test.
my $struct_hr = {
	'value' => {
		'numeric-id' => 42284,
		'id' => 'L42284',
		'entity-type' => 'lexeme',
	},
	'type' => 'wikibase-entityid',
};
my $ret = Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Lexeme');
is($ret->value, 'L42284', 'Method value().');
is($ret->type, 'lexeme', 'Method type().');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' datatype.\n",
	"Structure isn't for 'lexeme' datatype (blank structure).");
clean();

# Test.
$struct_hr = {
	'type' => undef,
};
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' datatype.\n",
	"Structure isn't for 'lexeme' datatype (type is undefined).");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' datatype.\n",
	"Structure isn't for 'lexeme' datatype (bad type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
};
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' datatype.\n",
	"Structure isn't for 'lexeme' datatype (only filled type).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {},
};
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' datatype.\n",
	"Structure isn't for 'lexeme' datatype (value is blank).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {
		'entity-type' => undef,
	},
};
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' datatype.\n",
	"Structure isn't for 'lexeme' datatype (value has only entity-type with null).");
clean();

# Test.
$struct_hr = {
	'type' => 'wikibase-entityid',
	'value' => {
		'entity-type' => 'bad',
	},
};
eval {
	Wikibase::Datatype::Struct::Value::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' datatype.\n",
	"Structure isn't for 'lexeme' datatype (value has only entity-type with bad value).");
clean();
