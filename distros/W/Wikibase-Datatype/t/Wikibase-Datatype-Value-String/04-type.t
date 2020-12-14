use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Value::String->new(
	'value' => 'string',
);
my $ret = $obj->type;
is($ret, 'string', 'Get type().');
