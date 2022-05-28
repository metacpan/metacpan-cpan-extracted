package Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;

use base qw(Wikibase::Datatype::Sense);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Value::Monolingual;

sub new {
	my $class = shift;

	my @params = (
		'glosses' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'domesticated mammal related to the wolf',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => decode_utf8('psovitá šelma chovaná jako domácí zvíře'),
			),
		],
		# https://www.wikidata.org/wiki/Lexeme:L469
		'id' => 'L469-S1',
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog->new,
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
