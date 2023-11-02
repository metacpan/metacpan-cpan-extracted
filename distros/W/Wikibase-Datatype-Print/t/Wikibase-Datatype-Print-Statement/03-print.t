use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Test.
my $obj = Wikibase::Datatype::Statement->new(
	'entity' => 'Q42',
	'snak' => Wikibase::Datatype::Snak->new(
		'datatype' => 'string',
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => '1.1',
		),
		'property' => 'P11',
	),
	'rank' => 'normal',
);
my @ret = Wikibase::Datatype::Print::Statement::print($obj);
is_deeply(
	\@ret,
	[
		'P11: 1.1 (normal)',
	],
	'Get printed value.',
);

# Test.
eval {
	Wikibase::Datatype::Print::Statement::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Statement'.\n",
	"Object isn't 'Wikibase::Datatype::Statement'.");
clean();

# Test.
$obj = Wikibase::Datatype::Statement->new(
	'entity' => 'Q42',
	'property_snaks' => [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'wikibase-item',
			'datavalue' => Wikibase::Datatype::Value::Item->new(
				'value' => 'Q474741',
			),
			'property' => 'P642',
		),
	],
	'snak' => Wikibase::Datatype::Snak->new(
		'datatype' => 'string',
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => '1.1',
		),
		'property' => 'P11',
	),
	'rank' => 'normal',
	'references' => [
		 Wikibase::Datatype::Reference->new(
			 'snaks' => [
				 # stated in (P248) Virtual International Authority File (Q53919)
				 Wikibase::Datatype::Snak->new(
					  'datatype' => 'wikibase-item',
					  'datavalue' => Wikibase::Datatype::Value::Item->new(
						  'value' => 'Q53919',
					  ),
					  'property' => 'P248',
				 ),

				 # VIAF ID (P214) 113230702
				 Wikibase::Datatype::Snak->new(
					  'datatype' => 'external-id',
					  'datavalue' => Wikibase::Datatype::Value::String->new(
						  'value' => '113230702',
					  ),
					  'property' => 'P214',
				 ),

				 # retrieved (P813) 7 December 2013
				 Wikibase::Datatype::Snak->new(
					  'datatype' => 'time',
					  'datavalue' => Wikibase::Datatype::Value::Time->new(
						  'value' => '+2013-12-07T00:00:00Z',
					  ),
					  'property' => 'P813',
				 ),
			 ],
		 ),
	],
);
@ret = Wikibase::Datatype::Print::Statement::print($obj);
is_deeply(
	\@ret,
	[
		'P11: 1.1 (normal)',
		' P642: Q474741',
		'References:',
		'  {',
		'    P248: Q53919',
		'    P214: 113230702',
		'    P813: 7 December 2013 (Q1985727)',
		'  }',
	],
	'Get printed value.',
);

# Test.
@ret = Wikibase::Datatype::Print::Statement::print($obj, {
	'no_print_references' => 1,
});
is_deeply(
	\@ret,
	[
		'P11: 1.1 (normal)',
		' P642: Q474741',
	],
	'Get printed value (without references).',
);
