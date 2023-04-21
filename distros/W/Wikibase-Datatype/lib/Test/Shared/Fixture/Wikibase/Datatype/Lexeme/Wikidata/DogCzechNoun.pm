package Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;

use base qw(Wikibase::Datatype::Lexeme);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;
use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.26;

sub new {
	my $class = shift;

	my @params = (
		'forms' => [
			Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new,
		],
		'id' => 'L469',
		'language' => 'Q9056',
		'lastrevid' => 1428556087,
		'lexical_category' => 'Q1084',
		'lemmas' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => 'pes',
			),
		],
		'modified' => '2022-06-24T12:42:10Z',
		'ns' => 146,
		'page_id' => 54393954,
		'senses' => [
			Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new,
		],
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine->new,
		],
		'title' => 'Lexeme:L469',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
