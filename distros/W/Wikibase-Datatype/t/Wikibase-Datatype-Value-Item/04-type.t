use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Value::Item->new(
	'value' => 'Q123',
);
my $ret = $obj->type;
is($ret, 'item', 'Get type().');
