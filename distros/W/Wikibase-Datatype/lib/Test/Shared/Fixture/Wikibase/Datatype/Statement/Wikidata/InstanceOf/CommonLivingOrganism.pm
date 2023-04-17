package Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism;

use base qw(Wikibase::Datatype::Statement);
use strict;
use warnings;

use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::Item;

our $VERSION = 0.25;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Wikibase::Datatype::Snak->new(
			'datatype' => 'wikibase-item',
			'datavalue' => Wikibase::Datatype::Value::Item->new(
				'value' => 'Q55983715',
			),
			'property' => 'P31',
		),
		'property_snaks' => [
			Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => 'Q20717272',
				),
				'property' => 'P642',
			),
			Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => 'Q26972265',
				),
				'property' => 'P642',
			),
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
