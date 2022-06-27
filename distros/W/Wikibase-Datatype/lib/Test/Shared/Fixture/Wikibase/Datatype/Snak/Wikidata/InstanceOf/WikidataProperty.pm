package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::WikidataProperty;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::WikidataEntity;

our $VERSION = 0.16;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::WikidataEntity->new,
		'property' => 'P31',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
