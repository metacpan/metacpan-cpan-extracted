use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Sense;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Sense->new;
my $ret_ar = $obj->glosses;
is_deeply($ret_ar, [], 'No glosses.');

# Test.
$obj = Wikibase::Datatype::Sense->new(
	'glosses' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Glosse en',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'Glosse cs',
		),
	],
);
my @ret = map { $_->value } @{$obj->glosses};
is_deeply(
	\@ret,
	[
		'Glosse en',
		'Glosse cs',
	],
	'Get glosses value.',
);

