use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::API::Resolve;

# Test.
my $obj = Wikibase::API::Resolve->new;
isa_ok($obj, 'Wikibase::API::Resolve');

# Test.
eval {
	Wikibase::API::Resolve->new(
		'bad' => 'bar',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad'.\n",
	"Unknown parameter 'bad'.");
clean();
