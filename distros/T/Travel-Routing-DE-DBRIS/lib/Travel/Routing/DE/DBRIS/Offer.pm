package Travel::Routing::DE::DBRIS::Offer;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

our $VERSION = '0.06';

Travel::Routing::DE::DBRIS::Offer->mk_ro_accessors(
	qw(class name price price_unit is_upsell is_cross_sell needs_context));

sub new {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json};

	my $ref = {
		class         => $json->{klasse} =~ s{KLASSE_}{}r,
		name          => $json->{name},
		price         => $json->{preis}{betrag},
		price_unit    => $json->{preis}{waehrung},
		conditions    => $json->{konditionsAnzeigen},
		is_upsell     => exists $json->{upsellInfos}    ? 1 : 0,
		is_cross_sell => exists $json->{crosssellInfos} ? 1 : 0,
	};

	for my $relation ( @{ $json->{angebotsbeziehungList} // [] } ) {
		for my $offer_ref ( @{ $relation->{referenzen} // [] } ) {
			if ( $offer_ref->{referenzAngebotsoption} eq 'PFLICHT' ) {
				$ref->{needs_context} = 1;
			}
		}
	}

	bless( $ref, $obj );

	return $ref;
}

sub conditions {
	my ($self) = @_;

	return @{ $self->{conditions} // [] };
}

1;
