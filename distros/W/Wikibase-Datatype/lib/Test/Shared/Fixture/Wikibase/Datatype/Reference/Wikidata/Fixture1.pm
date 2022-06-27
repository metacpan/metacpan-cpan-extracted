package Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::Fixture1;

use base qw(Wikibase::Datatype::Reference);
use strict;
use warnings;

use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF;

our $VERSION = 0.16;

sub new {
	my $class = shift;

	my @params = (
		'snaks' => [
			# stated in (P248) Virtual International Authority File (Q53919)
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF->new,

			# VIAF ID (P214) 113230702
			Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => '113230702',
				),
				'property' => 'P214',
			),

			# retrieved (P813) 7 December 2013
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1->new,
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
