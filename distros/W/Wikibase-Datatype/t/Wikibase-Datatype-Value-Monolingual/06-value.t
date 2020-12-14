use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Value::Monolingual->new(
	'value' => 'Example',
);
my $ret = $obj->value;
is($ret, 'Example', 'Get value().');
