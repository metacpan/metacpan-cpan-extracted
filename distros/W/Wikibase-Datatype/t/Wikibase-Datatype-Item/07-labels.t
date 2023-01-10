use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Item->new;
my $ret_ar = $obj->labels;
is_deeply(
	$ret_ar,
	[],
	'Without labels.',
);

# Test.
my $abc = join '', ('a' .. 'z');
my $input_value = $abc x 10;
$obj = Wikibase::Datatype::Item->new(
	'labels' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => $input_value,
		),
	],
);
$ret_ar = $obj->labels;
is(@{$ret_ar}, 1, 'One label.');
my $expected_value = substr $input_value, 0, 250;
is($ret_ar->[0]->value, $expected_value, 'Strip value to 250 characters.');
