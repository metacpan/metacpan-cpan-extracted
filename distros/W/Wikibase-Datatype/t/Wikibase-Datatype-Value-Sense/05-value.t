use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Sense;

# Test.
my $obj = Wikibase::Datatype::Value::Sense->new(
	'value' => 'L34727-S1',
);
my $ret = $obj->value;
is($ret, 'L34727-S1', 'Get value().');
