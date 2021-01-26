use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;

# Test.
my $obj = Wikibase::Datatype::Mediainfo->new;
my $ret = $obj->id;
is($ret, undef, 'Default id.');

# Test.
$obj = Wikibase::Datatype::Mediainfo->new(
	'id' => 'M42',
);
$ret = $obj->id;
is($ret, 'M42', 'Explicit id.');
