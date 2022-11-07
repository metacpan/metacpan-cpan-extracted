package Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::VersionEditionOrTranslation;

use base qw(Wikibase::Datatype::Statement);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::VersionEditionOrTranslation;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Of::Poem;

our $VERSION = 0.23;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::VersionEditionOrTranslation->new,
		'property_snaks' => [
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Of::Poem->new,
		],
		'references' => [
			Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF->new,
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
