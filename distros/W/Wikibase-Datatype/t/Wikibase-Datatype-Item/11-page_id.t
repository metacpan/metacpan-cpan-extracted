use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Item;

# Test.
my $obj = Wikibase::Datatype::Item->new;
my $ret = $obj->page_id;
is($ret, undef, 'Default page id.');

# Test.
$obj = Wikibase::Datatype::Item->new(
	'page_id' => 123,
);
$ret = $obj->page_id;
is($ret, 123, 'Explicit page id.');
