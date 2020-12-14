use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Property;

# Test.
my $obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P123',
);
my $ret = $obj->type;
is($ret, 'property', 'Get type().');
