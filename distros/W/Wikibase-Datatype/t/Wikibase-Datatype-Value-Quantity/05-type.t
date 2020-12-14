use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;

# Test.
my $obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => '10',
);
my $ret = $obj->type;
is($ret, 'quantity', 'Get type().');
