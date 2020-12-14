use strict;
use warnings;

use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Language;

# Test.
my $struct_hr = {
	'language' => 'en',
	'value' => 'English text',
};
my $ret = Wikibase::Datatype::Struct::Language::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Monolingual');
is($ret->language, 'en', 'Method language().');
is($ret->type, 'monolingualtext', 'Method type().');
is($ret->value, 'English text', 'Method value().');
