use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Property;

# Test.
my $obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
my $ret = $obj->page_id;
is($ret, undef, 'Default page id.');

# Test.
$obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
	'page_id' => 123,
);
$ret = $obj->page_id;
is($ret, 123, 'Explicit page id.');
