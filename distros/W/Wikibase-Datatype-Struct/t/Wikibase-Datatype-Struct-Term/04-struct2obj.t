use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Term;

# Test.
my $struct_hr = {
	'language' => 'en',
	'value' => 'English text',
};
my $ret = Wikibase::Datatype::Struct::Term::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Term');
is($ret->language, 'en', 'Method language().');
is($ret->value, 'English text', 'Method value().');
