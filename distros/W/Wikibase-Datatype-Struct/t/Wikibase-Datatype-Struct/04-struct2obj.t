use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 30;
use Test::NoWarnings;
use Wikibase::Datatype::Struct;

# Test.
my $struct_hr = {
	'ns' => 0,
	'type' => 'item',
};
my $ret = Wikibase::Datatype::Struct::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Item');
is($ret->id, undef, 'Method id() in item.');
is($ret->lastrevid, undef, 'Method lastrevid() in item.');
is($ret->modified, undef, 'Method modified() in item.');
is($ret->ns, 0, 'Method ns() in item.');
is($ret->page_id, undef, 'Method page_id() in item.');
is($ret->title, undef, 'Method title() in item.');

# Test.
$struct_hr = {
	'type' => 'lexeme',
};
$ret = Wikibase::Datatype::Struct::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Lexeme');
is($ret->lastrevid, undef, 'Method lastrevid() in lexeme.');
is($ret->modified, undef, 'Method modified() in lexeme.');
is($ret->ns, 146, 'Method ns() in lexeme.');
is($ret->title, undef, 'Method title() in lexeme.');

# Test.
$struct_hr = {
	'ns' => 6,
	'type' => 'mediainfo',
};
$ret = Wikibase::Datatype::Struct::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Mediainfo');
is($ret->id, undef, 'Method id() in mediainfo.');
is($ret->lastrevid, undef, 'Method lastrevid() in mediainfo.');
is($ret->modified, undef, 'Method modified() in mediainfo.');
is($ret->ns, 6, 'Method ns() in mediainfo.');
is($ret->page_id, undef, 'Method page_id() in mediainfo.');
is($ret->title, undef, 'Method title() in mediainfo.');

# Test.
$struct_hr = {
	'datatype' => 'external-id',
	'ns' => 1200,
	'type' => 'property',
};
$ret = Wikibase::Datatype::Struct::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Property');
is($ret->datatype, 'external-id', 'Method datatype() in property.');
is($ret->id, undef, 'Method id() in property.');
is($ret->lastrevid, undef, 'Method lastrevid() in property.');
is($ret->modified, undef, 'Method modified() in property.');
is($ret->ns, 1200, 'Method ns() in property.');
is($ret->page_id, undef, 'Method page_id() in property.');
is($ret->title, undef, 'Method title() in property.');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure doesn't supported. No type.\n",
	"Structure doesn't supported. No type.");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Unsupported 'bad' type,\n",
	"Unsupported 'bad' type,");
clean();
