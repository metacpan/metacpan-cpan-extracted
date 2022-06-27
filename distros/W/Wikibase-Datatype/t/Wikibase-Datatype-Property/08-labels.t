use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Property;

# Test.
my $obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
my $ret_ar = $obj->labels;
is_deeply(
	$ret_ar,
	[],
	'Without labels.',
);
