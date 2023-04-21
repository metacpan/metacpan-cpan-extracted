package Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;

use base qw(Wikibase::Datatype::MediainfoSnak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams;

our $VERSION = 0.26;

sub new {
	my $class = shift;

	my @params = (
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams->new,
		'property' => 'P180',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
