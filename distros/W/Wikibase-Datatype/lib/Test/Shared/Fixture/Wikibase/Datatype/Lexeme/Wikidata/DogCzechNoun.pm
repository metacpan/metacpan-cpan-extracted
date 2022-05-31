package Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;

use base qw(Wikibase::Datatype::Lexeme);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;
use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.12;

sub new {
	my $class = shift;

	my @params = (
		'forms' => [
			Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new,
		],
		'language' => 'Q9056',
		'lastrevid' => 1428556087,
		'lexical_category' => 'Q1084',
		'lemmas' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => 'pes',
			),
		],
		'senses' => [
			Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new,
		],
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male->new,
		],
		'title' => 'Lexeme:L469',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
