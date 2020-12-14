use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Form->new;
my $ret_ar = $obj->representations;
is_deeply($ret_ar, [], 'No representations.');

# Test.
$obj = Wikibase::Datatype::Form->new(
	'representations' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'Text',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Text',
		),
	],
);
my @ret = map { $_->language } @{$obj->representations};
is_deeply(
	\@ret,
	[
		'cs',
		'en',
	],
	'Two representations.'
);
