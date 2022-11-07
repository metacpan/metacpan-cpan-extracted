package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Of::Poem;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem;

our $VERSION = 0.23;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-item',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem->new,
		'property' => 'P642',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
