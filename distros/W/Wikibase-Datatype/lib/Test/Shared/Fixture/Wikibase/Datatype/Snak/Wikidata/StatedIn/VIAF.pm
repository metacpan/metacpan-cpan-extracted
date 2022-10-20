package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VIAF;

our $VERSION = 0.22;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VIAF->new,
		'property' => 'P248',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
