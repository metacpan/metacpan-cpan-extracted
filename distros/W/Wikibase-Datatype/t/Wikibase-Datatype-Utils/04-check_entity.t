use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Utils qw(check_entity);

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_entity($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must begin with 'Q' and number after it.\n",
	"Parameter 'key' must begin with 'Q' and number after it.");
clean();

# Test.
$self = {
	'key' => 'Q123',
};
my $ret = check_entity($self, 'key');
is($ret, undef, 'Right object is present.');
