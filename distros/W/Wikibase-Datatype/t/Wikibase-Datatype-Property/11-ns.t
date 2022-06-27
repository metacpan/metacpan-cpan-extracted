use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Property;

# Test.
my $obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
my $ret = $obj->ns;
is($ret, 120, 'Default namespace (120).');
