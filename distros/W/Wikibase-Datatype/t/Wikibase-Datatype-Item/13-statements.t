use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Item;

# Test.
my $obj = Wikibase::Datatype::Item->new;
my $ret_ar = $obj->statements;
is_deeply(
	$ret_ar,
	[],
	'Without statements.',
);
