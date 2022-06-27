package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Wikibase::Datatype::Value::Time;

our $VERSION = 0.16;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'time',
		'datavalue' => Wikibase::Datatype::Value::Time->new(
			'value' => '+2013-12-07T00:00:00Z',
		),
		'property' => 'P813',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
