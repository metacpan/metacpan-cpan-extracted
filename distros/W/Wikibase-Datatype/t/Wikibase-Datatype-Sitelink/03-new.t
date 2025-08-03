use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Sitelink->new(
	'badges' => [
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q123',
		),
	],
	'site' => 'enwiki',
	'title' => 'Title',
);
isa_ok($obj, 'Wikibase::Datatype::Sitelink');

# Test.
eval {
	Wikibase::Datatype::Sitelink->new(
		'title' => 'Title',
	);
};
is($EVAL_ERROR, "Parameter 'site' is required.\n",
	"Parameter 'site' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Sitelink->new(
		'site' => 'enwiki',
	);
};
is($EVAL_ERROR, "Parameter 'title' is required.\n",
	"Parameter 'title' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Sitelink->new(
		'badges' => 'bad',
		'site' => 'enwiki',
		'title' => 'Main page',
	);
};
is($EVAL_ERROR, "Parameter 'badges' must be a array.\n",
	"Parameter 'badges' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Sitelink->new(
		'badges' => ['bad'],
		'site' => 'enwiki',
		'title' => 'Main page',
	);
};
is($EVAL_ERROR, "Parameter 'badges' with array must contain 'Wikibase::Datatype::Value::Item' objects.\n",
	"Parameter 'badges' with array must contain 'Wikibase::Datatype::Value::Item' objects (bad).");
clean();
