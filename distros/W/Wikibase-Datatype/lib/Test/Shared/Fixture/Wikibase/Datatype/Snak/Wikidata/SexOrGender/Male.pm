package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SexOrGender::Male;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Male;

our $VERSION = 0.23;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Male->new,
		'property' => 'P21',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
