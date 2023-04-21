package Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog;

use base qw(Wikibase::Datatype::Statement);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Image::Dog;

our $VERSION = 0.26;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Image::Dog->new,
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
