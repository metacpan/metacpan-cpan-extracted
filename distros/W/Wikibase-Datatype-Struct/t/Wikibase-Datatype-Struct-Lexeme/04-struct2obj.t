use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 13;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Lexeme;

# Test.
my $struct_hr = {
	'ns' => 0,
	'type' => 'lexeme',
};
my $ret = Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Lexeme');
is($ret->lastrevid, undef, 'Method lastrevid().');
is($ret->modified, undef, 'Method modified().');
is($ret->ns, 0, 'Method ns().');
is($ret->title, undef, 'Method title().');

# Test.
# TODO Complex structure

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' type.\n",
	"Structure isn't for 'lexeme' type.");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' type.\n",
	"Structure isn't for 'lexeme' type.");
clean();

# Test.
$struct_hr = {
	'type' => 'lexeme',
};
$ret = Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Lexeme');
is($ret->lastrevid, undef, 'Method lastrevid().');
is($ret->modified, undef, 'Method modified().');
# XXX Is it right?
is($ret->ns, 0, 'Method ns() (undefined).');
is($ret->title, undef, 'Method title().');
