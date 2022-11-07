package Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;

use base qw(Wikibase::Datatype::Property);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::WikidataProperty;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.23;

sub new {
	my $class = shift;

	my @params = (
		'aliases' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'is a',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'is an',
			),
		],
		'datatype' => 'wikibase-item',
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'that class of which this subject is a particular example and member',
			),
		],
		'id' => 'P31',
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'instance of',
			),
		],
		'lastrevid' => 1645333097,
		'modified' => '2022-06-24T13:05:10Z',
		'page_id' => 3918489,
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
