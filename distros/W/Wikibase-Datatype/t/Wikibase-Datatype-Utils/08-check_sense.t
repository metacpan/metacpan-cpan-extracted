use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Utils qw(check_sense);

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_sense($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must begin with 'L' and number, dash, S and number after it.\n",
	"Parameter 'key' must begin with 'L' and number, dash, S and number after it.");
clean();

# Test.
$self = {
	'key' => 'L34727-S1',
};
my $ret = check_sense($self, 'key');
is($ret, undef, 'Right object is present.');

# Test.
$self = {};
$ret = check_sense($self, 'key');
is($ret, undef, 'No key.');
