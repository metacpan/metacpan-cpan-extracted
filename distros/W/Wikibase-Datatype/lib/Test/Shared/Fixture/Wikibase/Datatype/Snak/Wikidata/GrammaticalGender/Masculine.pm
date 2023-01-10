package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GrammaticalGender::Masculine;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Masculine;

our $VERSION = 0.24;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Masculine->new,
		'property' => 'P5185',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
