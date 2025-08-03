use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Mediainfo->new;
isa_ok($obj, 'Wikibase::Datatype::Mediainfo');

# Test.
eval {
	Wikibase::Datatype::Mediainfo->new(
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Description 1',
			),
			Wikibase::Datatype::Value::Monolingual->new(
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
$obj = Wikibase::Datatype::Mediainfo->new(
	'descriptions' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Description 1',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Mediainfo', 'One en description.');

# Test.
eval {
	Wikibase::Datatype::Mediainfo->new(
		'descriptions' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'descriptions' with array must contain 'Wikibase::Datatype::Value::Monolingual' objects.\n",
	"Parameter 'descriptions' with array must contain 'Wikibase::Datatype::Value::Monolingual' objects (foo).");
clean();

# Test.
eval {
	Wikibase::Datatype::Mediainfo->new(
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Label 1',
			),
			Wikibase::Datatype::Value::Monolingual->new(
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
	Wikibase::Datatype::Mediainfo->new(
		'labels' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'labels' with array must contain 'Wikibase::Datatype::Value::Monolingual' objects.\n",
	"Parameter 'labels' with array must contain 'Wikibase::Datatype::Value::Monolingual' objects (foo).");
clean();

# Test.
$obj = Wikibase::Datatype::Mediainfo->new(
	'labels' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Label 1',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Mediainfo', 'One en label.');

# Test.
eval {
	Wikibase::Datatype::Mediainfo->new(
		'statements' => ['foo'],
	);
};
is($EVAL_ERROR, "Parameter 'statements' with array must contain 'Wikibase::Datatype::MediainfoStatement' objects.\n",
	"Parameter 'statements' with array must contain 'Wikibase::Datatype::MediainfoStatement' objects (foo).");
clean();
