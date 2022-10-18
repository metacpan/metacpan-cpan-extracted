package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ItemForThisSense::Dog;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Dog;

our $VERSION = 0.21;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Dog->new,
		'property' => 'P5137',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
