package Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;

use base qw(Wikibase::Datatype::Statement);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::Human;

our $VERSION = 0.21;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::Human->new,
		'references' => [
			Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF->new,
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
