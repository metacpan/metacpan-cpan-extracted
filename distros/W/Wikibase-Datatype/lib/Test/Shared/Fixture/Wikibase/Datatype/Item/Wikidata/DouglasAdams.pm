package Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::DouglasAdams;

use base qw(Wikibase::Datatype::Item);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GivenName::Douglas;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.25;

sub new {
	my $class = shift;

	my @params = (
		'aliases' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Douglas Noel Adams',
			),
		],
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'English writer and humorist (1952-2001)',
			),
		],
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Douglas Adams',
			),
		],
		'lastrevid' => 1645190860,
		'modified' => '2022-06-24T13:34:10Z',
		'ns' => 0,
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GivenName::Douglas->new,
		],
		'title' => 'Q42',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
