package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Wikibase::Datatype::Value::String;

our $VERSION = 0.01;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'url',
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'https://skim.cz',
		),
		'property' => 'P854',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
