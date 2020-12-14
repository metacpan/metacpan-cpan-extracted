use strict;
use warnings;

use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Struct::Sitelink;

# Test.
my $struct_hr = {
	'badges' => ['Q1', 'Q2'],
	'site' => 'cswiki',
	'title' => decode_utf8('Hlavní strana'),
};
my $ret = Wikibase::Datatype::Struct::Sitelink::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Sitelink');
is($ret->badges->[0]->value, 'Q1', 'First badges.');
is($ret->badges->[1]->value, 'Q2', 'Second badges.');
is($ret->site, 'cswiki', 'Method site().');
is($ret->title, decode_utf8('Hlavní strana'), 'Method title().');
