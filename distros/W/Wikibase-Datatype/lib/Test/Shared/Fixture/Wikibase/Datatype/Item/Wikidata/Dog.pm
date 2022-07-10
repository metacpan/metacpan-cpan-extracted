package Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;

use base qw(Wikibase::Datatype::Item);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.19;

sub new {
	my $class = shift;

	my @params = (
		'aliases' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => 'pes',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'domestic dog',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Canis lupus familiaris',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Canis familiaris',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'dogs',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => decode_utf8('🐶'),
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => decode_utf8('🐕'),
			),
		],
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'domestic animal',
			),
		],
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'dog',
			),
		],
		'id' => 'Q144',
		'lastrevid' => 1539465460,
		'modified' => '2021-12-06T14:48:31Z',
		'ns' => 0,
		'page_id' => 280,
		'sitelinks' => [
			Wikibase::Datatype::Sitelink->new(
				'site' => 'enwiki',
				'title' => 'Dog',
			),
		],
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism->new,
		],
		'title' => 'Q144',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
