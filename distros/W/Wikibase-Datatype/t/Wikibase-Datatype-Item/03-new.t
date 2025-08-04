use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 14;
use Test::NoWarnings;
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Term;

# Test.
my $obj = Wikibase::Datatype::Item->new;
isa_ok($obj, 'Wikibase::Datatype::Item');

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'aliases' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'aliases' with array must contain 'Wikibase::Datatype::Term' objects.\n",
	"Parameter 'aliases' with array must contain 'Wikibase::Datatype::Term' objects (foo).");
clean();

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'descriptions' => [
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'Description 1',
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'Description 2',
			),
		],
	);
};
is($EVAL_ERROR, "Description for language 'en' has multiple values.\n",
	"Description for language 'en' has multiple values.");
clean();

# Test.
$obj = Wikibase::Datatype::Item->new(
	'descriptions' => [
		Wikibase::Datatype::Term->new(
			'language' => 'en',
			'value' => 'Description 1',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Item', 'One en description.');

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'descriptions' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'descriptions' with array must contain 'Wikibase::Datatype::Term' objects.\n",
	"Parameter 'descriptions' with array must contain 'Wikibase::Datatype::Term' objects (foo).");
clean();

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'labels' => [
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'Label 1',
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'Label 2',
			),
		],
	);
};
is($EVAL_ERROR, "Label for language 'en' has multiple values.\n",
	"Label for language 'en' has multiple values.");
clean();

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'labels' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'labels' with array must contain 'Wikibase::Datatype::Term' objects.\n",
	"Parameter 'labels' with array must contain 'Wikibase::Datatype::Term' objects (foo).");
clean();

# Test.
$obj = Wikibase::Datatype::Item->new(
	'labels' => [
		Wikibase::Datatype::Term->new(
			'language' => 'en',
			'value' => 'Label 1',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Item', 'One en label.');

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'sitelinks' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'sitelinks' with array must contain 'Wikibase::Datatype::Sitelink' objects.\n",
	"Parameter 'sitelinks' with array must contain 'Wikibase::Datatype::Sitelink' objects (foo).");
clean();

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'sitelinks' => [
			Wikibase::Datatype::Sitelink->new(
				'site' => 'enwiki',
				'title' => 'Main page',
			),
			Wikibase::Datatype::Sitelink->new(
				'site' => 'enwiki',
				'title' => 'Main page',
			),
		],
	);
};
is($EVAL_ERROR, "Sitelink for site 'enwiki' has multiple values.\n",
	"Sitelink for site 'enwiki' has multiple values.");
clean();

# Test.
$obj = Wikibase::Datatype::Item->new(
	'sitelinks' => [
		Wikibase::Datatype::Sitelink->new(
			'site' => 'enwiki',
			'title' => 'Main page',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Item', 'One enwiki sitelink.');

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'statements' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'statements' with array must contain 'Wikibase::Datatype::Statement' objects.\n",
	"Parameter 'statements' with array must contain 'Wikibase::Datatype::Statement' objects (foo).");
clean();

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'page_id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'page_id' must be a number.\n",
	"Parameter 'page_id' must be a number.");
clean();
