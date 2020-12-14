use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Wikibase::Datatype::Sense;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Sense->new;
isa_ok($obj, 'Wikibase::Datatype::Sense');

# Test.
eval {
	Wikibase::Datatype::Sense->new(
		'glosses' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'glosses' must be a array.\n",
	"Parameter 'glosses' must be a array..");
clean();

# Test.
eval {
	Wikibase::Datatype::Sense->new(
		'glosses' => ['bad'],
	);
};
is($EVAL_ERROR, "Glosse isn't 'Wikibase::Datatype::Value::Monolingual' object.\n",
	"Glosse isn't 'Wikibase::Datatype::Value::Monolingual' object.");
clean();

# Test.
eval {
	Wikibase::Datatype::Sense->new(
		'glosses' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Glosse 1',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Glosse 2',
			),
		],
	);
};
is($EVAL_ERROR, "Glosse for language 'en' has multiple values.\n",
	"Glosse for language 'en' has multiple values.");
clean();

# Test.
eval {
	Wikibase::Datatype::Sense->new(
		'statements' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'statements' must be a array.\n",
	"Parameter 'statements' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Sense->new(
		'statements' => ['bad'],
	);
};
is($EVAL_ERROR, "Statement isn't 'Wikibase::Datatype::Statement' object.\n",
	"Statement isn't 'Wikibase::Datatype::Statement' object.");
clean();
