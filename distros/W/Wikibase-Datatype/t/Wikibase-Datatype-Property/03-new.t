use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 13;
use Test::NoWarnings;
use Wikibase::Datatype::Property;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
isa_ok($obj, 'Wikibase::Datatype::Property');

# Test.
eval {
	Wikibase::Datatype::Property->new;
};
is($EVAL_ERROR, "Parameter 'datatype' is required.\n",
	"Parameter 'datatype' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Property->new(
		'datatype' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'datatype' = 'foo' isn't supported.\n",
	"Parameter 'datatype' = 'foo' isn't supported.");
clean();

# Test.
eval {
	Wikibase::Datatype::Property->new(
		'aliases' => ['foo'],
		'datatype' => 'external-id',
	);
};
is($EVAL_ERROR, "Alias isn't 'Wikibase::Datatype::Value::Monolingual' object.\n",
	"Alias isn't 'Wikibase::Datatype::Value::Monolingual' object.");
clean();

# Test.
eval {
	Wikibase::Datatype::Property->new(
		'datatype' => 'external-id',
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
$obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
	'descriptions' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Description 1',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Property', 'One en description.');

# Test.
eval {
	Wikibase::Datatype::Property->new(
		'datatype' => 'external-id',
		'descriptions' => ['foo'],
	);
};
is($EVAL_ERROR, "Description isn't 'Wikibase::Datatype::Value::Monolingual' object.\n",
	"Description isn't 'Wikibase::Datatype::Value::Monolingual' object.");
clean();

# Test.
eval {
	Wikibase::Datatype::Property->new(
		'datatype' => 'external-id',
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
	Wikibase::Datatype::Property->new(
		'datatype' => 'external-id',
		'labels' => ['foo'],
	);
};
is($EVAL_ERROR, "Label isn't 'Wikibase::Datatype::Value::Monolingual' object.\n",
	"Label isn't 'Wikibase::Datatype::Value::Monolingual' object.");
clean();

# Test.
$obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
	'labels' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Label 1',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Property', 'One en label.');

# Test.
eval {
	Wikibase::Datatype::Property->new(
		'datatype' => 'external-id',
		'statements' => ['foo'],
	);
};
is($EVAL_ERROR, "Statement isn't 'Wikibase::Datatype::Statement' object.\n",
	"Statement isn't 'Wikibase::Datatype::Statement' object.");
clean();

# Test.
eval {
	Wikibase::Datatype::Property->new(
		'datatype' => 'external-id',
		'page_id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'page_id' must be a number.\n",
	"Parameter 'page_id' must be a number.");
clean();
