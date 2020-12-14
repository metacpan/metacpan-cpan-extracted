use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Reference;

# Test.
my $obj = Wikibase::Datatype::Reference->new(
	'snaks' => [],
);
isa_ok($obj, 'Wikibase::Datatype::Reference');

# Test.
eval {
	Wikibase::Datatype::Reference->new;
};
is($EVAL_ERROR, "Parameter 'snaks' is required.\n",
	"Parameter 'snaks' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Reference->new(
		'snaks' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'snaks' must be a array.\n",
	"Parameter 'snaks' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Reference->new(
		'snaks' => ['bad'],
	);
};
is($EVAL_ERROR, "Snak isn't 'Wikibase::Datatype::Snak' object.\n",
	"Snak isn't 'Wikibase::Datatype::Snak' object.");
clean();
