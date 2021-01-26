use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;

# Test.
my $obj = Wikibase::Datatype::Mediainfo->new;
my $ret_ar = $obj->labels;
is_deeply(
	$ret_ar,
	[],
	'Without labels.',
);
