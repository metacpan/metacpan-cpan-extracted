use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Form->new;
my $ret_ar = $obj->grammatical_features;
is_deeply($ret_ar, [], 'No grammatical features.');

# Test.
$obj = Wikibase::Datatype::Form->new(
	'grammatical_features' => [
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q123',
		),
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q321',
		),
	],
);
my @ret = map { $_->value } @{$obj->grammatical_features};
is_deeply(
	\@ret,
	[
		'Q123',
		'Q321',
	],
	'Get grammatical features list.',
);

