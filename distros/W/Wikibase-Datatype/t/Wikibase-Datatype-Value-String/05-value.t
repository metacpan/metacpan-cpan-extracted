use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Value::String->new(
	'value' => 'foo',
);
my $ret = $obj->value;
is($ret, 'foo', 'Get value().');
