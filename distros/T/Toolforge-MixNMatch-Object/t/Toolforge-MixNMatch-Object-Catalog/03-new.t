use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::Catalog;

# Test.
my $obj = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 1,
	'type' => 'Q5',
);
isa_ok($obj, 'Toolforge::MixNMatch::Object::Catalog');

# Test.
eval {
	Toolforge::MixNMatch::Object::Catalog->new(
		'type' => 'Q5',
	);
};
is($EVAL_ERROR, "Parameter 'count' is required.\n",
	"Parameter 'count' is required.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Object::Catalog->new(
		'count' => 1,
	);
};
is($EVAL_ERROR, "Parameter 'type' is required.\n",
	"Parameter 'type' is required.");
clean();
