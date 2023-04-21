use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Time;

# Test.
my $obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Time');

# Test.
eval {
	Wikibase::Datatype::Value::Time->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Time->new(
		'calendarmodel' => 'foo',
		'value' => '+2020-09-01T00:00:00Z',
	);
};
is($EVAL_ERROR, "Parameter 'calendarmodel' must begin with 'Q' and number after it.\n",
	"Parameter 'calendarmodel' must begin with 'Q' and number after it.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Time->new(
		'value' => '+2020-09-01T01:00:00Z',
	);
};
is($EVAL_ERROR, "Parameter 'value' has bad date time hour value.\n",
	"Parameter 'value' has bad date time hour value.");
clean();
