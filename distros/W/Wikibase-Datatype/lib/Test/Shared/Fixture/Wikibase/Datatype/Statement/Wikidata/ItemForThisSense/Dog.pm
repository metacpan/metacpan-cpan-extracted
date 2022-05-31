package Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog;

use base qw(Wikibase::Datatype::Statement);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ItemForThisSense::Dog;

our $VERSION = 0.12;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ItemForThisSense::Dog->new,
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
