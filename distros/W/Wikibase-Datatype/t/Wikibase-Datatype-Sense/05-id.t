use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Sense;

# Test.
my $obj = Wikibase::Datatype::Sense->new;
my $ret = $obj->id;
is($ret, undef, 'No id.');

# Test.
$obj = Wikibase::Datatype::Sense->new(
	'id' => 'ID',
);
$ret = $obj->id;
is($ret, 'ID', 'Explicit id.');
