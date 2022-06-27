use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Property;

# Test.
my $obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
my $ret = $obj->id;
is($ret, undef, 'Default id.');

# Test.
$obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
	'id' => 'Q42',
);
$ret = $obj->id;
is($ret, 'Q42', 'Explicit id.');
