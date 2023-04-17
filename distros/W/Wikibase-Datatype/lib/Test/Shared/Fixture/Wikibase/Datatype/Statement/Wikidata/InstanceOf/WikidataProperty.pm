package Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::WikidataProperty;

use base qw(Wikibase::Datatype::Statement);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::WikidataProperty;

our $VERSION = 0.25;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::WikidataProperty->new,
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
