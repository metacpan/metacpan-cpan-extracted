package Travel::Status::DE::DBRIS::Formation::Carriage;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';
use Carp qw(cluck);

our $VERSION = '0.19';
Travel::Status::DE::DBRIS::Formation::Carriage->mk_ro_accessors(
	qw(class_type is_closed is_dosto is_locomotive is_powercar
	  number model section uic_id type
	  start_meters end_meters length_meters start_percent end_percent length_percent
	  has_priority_seats has_ac has_quiet_zone has_bahn_comfort has_wheelchair_space
	  has_wheelchair_toilet has_family_zone has_infant_cabin has_info has_bistro
	  has_first_class has_second_class
	)
);

my %type_map = (
	SEATS_SEVERELY_DISABLE => 'priority_seats',
	AIR_CONDITION          => 'ac',
	ZONE_QUIET             => 'quiet_zone',
	SEATS_BAHN_COMFORT     => 'bahn_comfort',
	INFO                   => 'info',
	TOILET_WHEELCHAIR      => 'wheelchair_toilet',
	WHEELCHAIR_SPACE       => 'wheelchair_space',
	ZONE_FAMILY            => 'family_zone',
	CABIN_INFANT           => 'infant_cabin',
);

sub new {
	my ( $obj, %opt ) = @_;
	my $ref = {};

	my %json     = %{ $opt{json} };
	my $platform = $opt{platform};

	$ref->{class_type}    = 0;
	$ref->{has_bistro}    = 0;
	$ref->{is_locomotive} = 0;
	$ref->{is_powercar}   = 0;
	$ref->{is_closed}     = 0;
	$ref->{number}        = $json{wagonIdentificationNumber};
	$ref->{model}         = $json{vehicleID};
	$ref->{uic_id}        = $json{vehicleID};
	$ref->{section}       = $json{platformPosition}{sector};
	$ref->{type}          = $json{type}{constructionType};

	$ref->{model} =~ s{^.....(...)....(?:-.)?$}{$1} or $ref->{model} = undef;

	my $self = bless( $ref, $obj );

	$self->parse_type;

	for my $amenity ( @{ $json{amenities} // [] } ) {
		my $type = $amenity->{type};
		if ( $type_map{$type} ) {
			my $key = 'has_' . $type_map{$type};
			$self->{$key} = 1;
		}
	}

	if ( $json{status} and $json{status} eq 'CLOSED' ) {
		$ref->{is_closed} = 1;
	}

	if ( $json{type}{category} =~ m{DININGCAR} ) {
		$ref->{has_bistro} = 1;
	}
	elsif ( $json{type}{category} eq 'LOCOMOTIVE' ) {
		$ref->{is_locomotive} = 1;
	}
	elsif ( $json{type}{category} eq 'POWERCAR' ) {
		$ref->{is_powercar} = 1;
	}

	$ref->{has_first_class}  = $json{type}{hasFirstClass};
	$ref->{has_second_class} = $json{type}{hasEconomyClass};

	if ( $ref->{type} =~ m{AB} ) {
		$ref->{class_type} = 12;
	}
	elsif ( $ref->{type} =~ m{A} ) {
		$ref->{class_type} = 1;
	}
	elsif ( $ref->{type} =~ m{B|WR} ) {
		$ref->{class_type} = 2;
	}

	my $pos             = $json{platformPosition};
	my $platform_length = $platform->{end} - $platform->{start};

	$ref->{start_meters} = $pos->{start};
	$ref->{end_meters}   = $pos->{end};
	$ref->{start_percent}
	  = ( $pos->{start} - $platform->{start} ) * 100 / $platform_length;
	$ref->{end_percent}
	  = ( $pos->{end} - $platform->{start} ) * 100 / $platform_length;
	if ( defined $pos->{start} and defined $pos->{end} ) {
		$ref->{length_meters} = $pos->{start} - $pos->{end};
	}
	$ref->{length_percent} = $ref->{end_percent} - $ref->{start_percent};

	if (   $pos->{start} eq ''
		or $pos->{end} eq '' )
	{
		$ref->{position}{valid} = 0;
	}
	else {
		$ref->{position}{valid} = 1;
	}

	return $self;
}

sub attributes {
	my ($self) = @_;

	return @{ $self->{attributes} // [] };
}

# See also:
# https://de.wikipedia.org/wiki/UIC-Bauart-Bezeichnungssystem_f%C3%BCr_Reisezugwagen#Kennbuchstaben
# https://www.deutsche-reisezugwagen.de/lexikon/erklarung-der-gattungszeichen/
sub parse_type {
	my ($self) = @_;

	my $type = $self->{type};
	my @desc;

	if ( $type =~ m{^D} ) {
		$self->{is_dosto} = 1;
		push( @desc, 'Doppelstock' );
	}

	if ( $type =~ m{b} ) {
		$self->{has_accessibility} = 1;
		push( @desc, 'Behindertengerechte Ausstattung' );
	}

	if ( $type =~ m{d} ) {
		$self->{multipurpose} = 1;
		push( @desc, 'Mehrzweck' );
	}

	if ( $type =~ m{f} ) {
		push( @desc, 'Steuerabteil' );
	}

	if ( $type =~ m{i} ) {
		push( @desc, 'Interregio' );
	}

	if ( $type =~ m{mm} ) {
		push( @desc, 'modernisiert' );
	}

	if ( $type =~ m{p} ) {
		$self->{has_ac} = 1;
		push( @desc, 'Großraum' );
	}

	if ( $type =~ m{s} ) {
		push( @desc, 'Sonderabteil' );
	}

	if ( $type =~ m{v} ) {
		$self->{has_ac}           = 1;
		$self->{has_compartments} = 1;
		push( @desc, 'Abteil' );
	}

	if ( $type =~ m{w} ) {
		$self->{has_ac}           = 1;
		$self->{has_compartments} = 1;
		push( @desc, 'Abteil' );
	}

	$self->{attributes} = \@desc;
}

sub is_first_class {
	my ($self) = @_;

	if ( $self->{type} =~ m{^D?A} ) {
		return 1;
	}
	return 0;
}

sub is_second_class {
	my ($self) = @_;

	if ( $self->{type} =~ m{^D?A?B} ) {
		return 1;
	}
	return 0;
}

sub sections {
	my ($self) = @_;

	return @{ $self->{sections} };
}

sub TO_JSON {
	my ($self) = @_;

	my %copy = %{$self};

	return {%copy};
}

1;

