use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use WQS::SPARQL;

# Test.
my $obj = WQS::SPARQL->new;
isa_ok($obj, 'WQS::SPARQL');

# Test.
eval {
	WQS::SPARQL->new(
		'lwp_user_agent' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.\n",
	"Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.");
clean();

# Test.
eval {
	WQS::SPARQL->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	WQS::SPARQL->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();
