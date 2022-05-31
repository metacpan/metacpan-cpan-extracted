package Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;

use base qw(Wikibase::Datatype::Property);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::WikidataProperty;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.12;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'that class of which this subject is a particular example and member',
			),
		],
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'instance of',
			),
		],
		'lastrevid' => 1645333097,
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::WikidataProperty->new,
		],
		'title' => 'Property:P31',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
