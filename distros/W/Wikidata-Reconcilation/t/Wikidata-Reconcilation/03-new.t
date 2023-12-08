use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikidata::Reconcilation;

# Test.
my $obj = Wikidata::Reconcilation->new;
isa_ok($obj, 'Wikidata::Reconcilation');

# Test.
eval {
	Wikidata::Reconcilation->new(
		'lwp_user_agent' => Test::MockObject->new,
	);
};
is($EVAL_ERROR, "Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.\n",
	"Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.");
