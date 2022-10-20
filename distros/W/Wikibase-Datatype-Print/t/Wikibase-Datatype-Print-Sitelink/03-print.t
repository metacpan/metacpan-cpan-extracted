use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Print::Sitelink;

# Test.
my $obj = Wikibase::Datatype::Sitelink->new(
	'badges' => [
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q123',
		),
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q321',
		),
	],
	'site' => 'enwiki',
	'title' => 'Title',
);
my $ret = Wikibase::Datatype::Print::Sitelink::print($obj);
is($ret, 'Title (enwiki) [Q123 Q321]', 'Print sitelink.');

# Test.
eval {
	Wikibase::Datatype::Print::Sitelink::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Sitelink'.\n",
	"Object isn't 'Wikibase::Datatype::Sitelink'.");
clean();
