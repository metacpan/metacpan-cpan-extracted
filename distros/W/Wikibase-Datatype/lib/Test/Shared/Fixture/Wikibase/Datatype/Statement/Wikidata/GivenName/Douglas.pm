package Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GivenName::Douglas;

use base qw(Wikibase::Datatype::Statement);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Douglas;

our $VERSION = 0.23;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Douglas->new,
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
