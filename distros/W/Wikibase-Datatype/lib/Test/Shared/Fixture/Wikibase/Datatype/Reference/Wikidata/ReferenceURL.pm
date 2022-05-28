package Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL;

use base qw(Wikibase::Datatype::Reference);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1;

sub new {
	my $class = shift;

	my @params = (
		'snaks' => [
			# reference URL (P854) https://skim.cz
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1->new,

			# retrieved (P813) 7 December 2013
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1->new,
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
