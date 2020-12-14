use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Time;

# Test.
my $obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-10-01T00:00:00Z',
);
my $ret = $obj->precision;
is($ret, 11, 'Get default precision().');

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'precision' => 10,
	'value' => '+2020-10-01T00:00:00Z',
);
$ret = $obj->precision;
is($ret, 10, 'Get explicit precision().');
