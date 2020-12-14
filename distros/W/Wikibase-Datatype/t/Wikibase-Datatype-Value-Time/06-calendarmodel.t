use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Time;

# Test.
my $obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-10-01T00:00:00Z',
);
my $ret = $obj->calendarmodel;
is($ret, 'Q1985727', 'Get default calendarmodel().');

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'calendarmodel' => 'Q1985786',
	'value' => '+2020-10-01T00:00:00Z',
);
$ret = $obj->calendarmodel;
is($ret, 'Q1985786', 'Get explicit calendarmodel().');
