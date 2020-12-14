use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Form->new;
my $ret_ar = $obj->statements;
is_deeply($ret_ar, [], 'No statements.');

# Test.
my $statement = Wikibase::Datatype::Statement->new(
	# instance of (P31) human (Q5)
	'snak' => Wikibase::Datatype::Snak->new(
		'datatype' => 'wikibase-item',
		'datavalue' => Wikibase::Datatype::Value::Item->new(
			'value' => 'Q5',
		),
		'property' => 'P31',
	),
);
$obj = Wikibase::Datatype::Form->new(
	'statements' => [$statement],
);
$ret_ar = $obj->statements;
is(scalar @{$ret_ar}, 1, 'One statement.');
