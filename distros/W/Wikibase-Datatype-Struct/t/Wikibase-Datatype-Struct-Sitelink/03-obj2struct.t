use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Struct::Sitelink;
use Wikibase::Datatype::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Sitelink->new(
	'badges' => [
		Wikibase::Datatype::Value::Item->new('value' => 'Q1'),
		Wikibase::Datatype::Value::Item->new('value' => 'Q2'),
	],
	'site' => 'cswiki',
	'title' => decode_utf8('Hlavní strana'),
);
my $ret_hr = Wikibase::Datatype::Struct::Sitelink::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'badges' => ['Q1', 'Q2'],
		'site' => 'cswiki',
		'title' => decode_utf8('Hlavní strana'),
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Sitelink::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Sitelink'.\n",
	"Object isn't 'Wikibase::Datatype::Sitelink'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Sitelink::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
