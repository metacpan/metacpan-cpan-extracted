use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Utils qw(check_lexeme);

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_lexeme($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must begin with 'L' and number after it.\n",
	"Parameter 'key' must begin with 'L' and number after it.");
clean();

# Test.
$self = {
	'key' => 'L123',
};
my $ret = check_lexeme($self, 'key');
is($ret, undef, 'Right object is present.');
