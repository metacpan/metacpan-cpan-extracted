package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Douglas;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Douglas;

our $VERSION = 0.12;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Douglas->new,
		'property' => 'P735',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
