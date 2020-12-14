use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Form;

# Test.
my $obj = Wikibase::Datatype::Form->new;
my $ret = $obj->id;
is($ret, undef, 'No id.');

# Test.
$obj = Wikibase::Datatype::Form->new(
	'id' => 'ID',
);
$ret = $obj->id;
is($ret, 'ID', 'Explicit id.');
