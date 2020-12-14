use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Time;

# Test.
my $obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-10-01T00:00:00Z',
);
my $ret = $obj->value;
is($ret, '+2020-10-01T00:00:00Z', 'Get value().');
