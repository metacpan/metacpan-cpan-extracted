use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Item;

# Test.
my $obj = Wikibase::Datatype::Item->new;
my $ret = $obj->id;
is($ret, undef, 'Default id.');

# Test.
$obj = Wikibase::Datatype::Item->new(
	'id' => 'Q42',
);
$ret = $obj->id;
is($ret, 'Q42', 'Explicit id.');
