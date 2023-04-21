use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Utils qw(print_references);
use Wikibase::Datatype::Print::Reference;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human->new;
my @ret = print_references($obj, {},
	\&Wikibase::Datatype::Print::Reference::print);
is_deeply(
	\@ret,
	[
		'References:',
                '  {',
		'    P248: Q53919',
		'    P214: 113230702',
		'    P813: 7 December 2013 (Q1985727)',
                '  }',
	],
	'Print referneces test.',
);
