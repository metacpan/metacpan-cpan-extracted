use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 12;
use Test::NoWarnings;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Form->new;
isa_ok($obj, 'Wikibase::Datatype::Form');

# Test.
eval {
	Wikibase::Datatype::Form->new(
		'grammatical_features' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'grammatical_features' must be a array.\n",
	"Parameter 'grammatical_features' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Form->new(
		'grammatical_features' => ['bad'],
	);
};
is($EVAL_ERROR, "Grammatical feature isn't 'Wikibase::Datatype::Value::Item' object.\n",
	"Grammatical feature isn't 'Wikibase::Datatype::Value::Item' object.");
clean();

# Test.
$obj = Wikibase::Datatype::Form->new(
	'grammatical_features' => [
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q123',
		),
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q321',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Form', 'Two grammatical features.');

# Test.
$obj = Wikibase::Datatype::Form->new(
	'id' => 'Identifier',
);
isa_ok($obj, 'Wikibase::Datatype::Form', 'Object with identifier.');

# Test.
eval {
	Wikibase::Datatype::Form->new(
		'representations' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'representations' must be a array.\n",
	"Parameter 'representations' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Form->new(
		'representations' => ['bad'],
	);
};
is($EVAL_ERROR, "Representation isn't 'Wikibase::Datatype::Value::Monolingual' object.\n",
	"Representation isn't 'Wikibase::Datatype::Value::Monolingual' object.");
clean();

# Test.
$obj = Wikibase::Datatype::Form->new(
	'representations' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'Text',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Text',
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Form', 'Two representations.');

# Test.
eval {
	Wikibase::Datatype::Form->new(
		'statements' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'statements' must be a array.\n",
	"Parameter 'statements' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Form->new(
		'statements' => ['bad'],
	);
};
is($EVAL_ERROR, "Statement isn't 'Wikibase::Datatype::Statement' object.\n",
	"Statement isn't 'Wikibase::Datatype::Statement' object.");
clean();

# Test.
$obj = Wikibase::Datatype::Form->new(
	'statements' => [
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => 'Q1',
				),
				'property' => 'P1',
			),
		),
	],
);
isa_ok($obj, 'Wikibase::Datatype::Form', 'One statement.');
