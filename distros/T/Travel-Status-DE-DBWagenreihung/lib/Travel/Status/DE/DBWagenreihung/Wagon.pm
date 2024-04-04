package Travel::Status::DE::DBWagenreihung::Wagon;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';
use Carp qw(cluck);

our $VERSION = '0.12';
Travel::Status::DE::DBWagenreihung::Wagon->mk_ro_accessors(
	qw(attributes class_type group_index has_ac has_accessibility
	  has_bahn_comfort has_bike_storage has_bistro has_compartments
	  has_family_area has_phone_area has_quiet_area is_closed is_dosto
	  is_interregio is_locomotive is_powercar number model multipurpose section
	  train_no train_subtype type uic_id)
);

our %type_attributes = (
	'ICE 1' => [
		undef, ['has_quiet_area'],  undef, ['has_quiet_area'],     # 1 2 3 4
		['has_family_area'], undef, ['has_bahn_comfort'],          # 5 6 7
		undef,               undef, undef, ['has_bahn_comfort'],   # 8 9 (10) 11
		['has_quiet_area'],  undef, undef                          # 12 (13) 14
	],
	'ICE 2' => [
		undef, ['has_quiet_area'], ['has_bahn_comfort'],
		['has_family_area'],                                       # 1 2 3 4
		undef, ['has_bahn_comfort'],
		[ 'has_quiet_area', 'has_phone_area' ]                     # 5 6 7
	],
	'ICE 3' => [
		['has_quiet_area'],  undef, undef, undef,                  # 1 2 3 (4)
		['has_family_area'], undef, ['has_bahn_comfort'],          # 5 6 7
		[ 'has_quiet_area', 'has_phone_area', 'has_bahn_comfort' ], undef  # 8 9
	],
	'ICE 3 Velaro' => [
		['has_quiet_area'],   undef, undef, ['has_family_area'],    # 1 2 3 4
		['has_bahn_comfort'], ['has_bahn_comfort'], undef, undef,    # 5 6 (7) 8
		[ 'has_quiet_area', 'has_phone_area' ]                       # 9
	],
	'ICE 4' => [
		['has_bike_storage'], undef, ['has_quiet_area'], undef,
		undef,                                                       # 1 2 3 4 5
		undef, ['has_bahn_comfort'], undef, ['has_family_area'],     # 6 7 (8) 9
		undef, ['has_bahn_comfort'], undef, undef,
		['has_quiet_area']    # 10 11 12 (13) 14
	],
	'ICE T 411' => [
		['has_quiet_area'], ['has_quiet_area'], undef,
		['has_family_area'],                        # 1 2 3 4
		undef, undef, ['has_bahn_comfort'],
		[ 'has_quiet_area', 'has_bahn_comfort' ]    # (5) 6 7 8
	],
	'ICE T 415' => [
		['has_quiet_area'], ['has_quiet_area'], ['has_bahn_comfort'],
		undef,                                      # 1 2 3 (4)
		undef, undef, ['has_family_area'],
		[ 'has_quiet_area', 'has_bahn_comfort' ]    # (5) (6) 7 8
	],
	'IC2 Twindexx' => [
		[ 'has_family_area', 'has_bike_storage' ], ['has_bike_storage'],   # 1 2
		['has_bike_storage'], [ 'has_bike_storage', 'has_bahn_comfort' ],  # 3 4
		[ 'has_bahn_comfort', 'has_quiet_area', 'has_phone_area' ]         # 5
	],
);

sub new {
	my ( $obj, %opt ) = @_;
	my $ref = {};

	$ref->{class_type}    = 0;
	$ref->{has_bistro}    = 0;
	$ref->{is_locomotive} = 0;
	$ref->{is_powercar}   = 0;
	$ref->{is_closed}     = 0;
	$ref->{train_no}      = $opt{train_no};
	$ref->{number}        = $opt{wagenordnungsnummer};
	$ref->{model}         = $opt{fahrzeugnummer};
	$ref->{uic_id}        = $opt{fahrzeugnummer};
	$ref->{section}       = $opt{fahrzeugsektor};
	$ref->{type}          = $opt{fahrzeugtyp};

	$ref->{model} =~ s{^.....(...)....$}{$1} or $ref->{model} = undef;

	my $self = bless( $ref, $obj );

	$self->parse_type;

	if ( $opt{status} and $opt{status} eq 'GESCHLOSSEN' ) {
		$ref->{is_closed} = 1;
	}

	if ( $opt{kategorie} =~ m{SPEISEWAGEN} ) {
		$ref->{has_bistro} = 1;
	}
	elsif ( $opt{kategorie} eq 'LOK' ) {
		$ref->{is_locomotive} = 1;
	}
	elsif ( $opt{kategorie} eq 'TRIEBKOPF' ) {
		$ref->{is_powercar} = 1;
	}

	if ( $opt{fahrzeugtyp} =~ m{AB} ) {
		$ref->{class_type} = 12;
	}
	elsif ( $opt{fahrzeugtyp} =~ m{A} ) {
		$ref->{class_type} = 1;
	}
	elsif ( $opt{fahrzeugtyp} =~ m{B|WR} ) {
		$ref->{class_type} = 2;
	}

	my $pos = $opt{positionamhalt};

	$ref->{position}{start_percent} = $pos->{startprozent};
	$ref->{position}{end_percent}   = $pos->{endeprozent};
	$ref->{position}{start_meters}  = $pos->{startmeter};
	$ref->{position}{end_meters}    = $pos->{endemeter};

	if (   $pos->{startprozent} eq ''
		or $pos->{endeprozent} eq ''
		or $pos->{startmeter} eq ''
		or $pos->{endemeter} eq '' )
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
		$self->{is_interregio} = 1;
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

sub set_traintype {
	my ( $self, $group_index, $tt ) = @_;

	$self->{group_index}   = $group_index;
	$self->{train_subtype} = $tt;

	if ( not $self->{number} or not exists( $type_attributes{$tt} ) ) {
		return;
	}

	if ( $self->{number} !~ m{^\d+$} ) {
		return;
	}

	my $index = $self->{number} - 1;

	if ( $index >= 30 ) {
		$index -= 30;
	}
	elsif ( $index >= 20 ) {
		$index -= 20;
	}

	if ( not $type_attributes{$tt}[$index] ) {
		return;
	}

	for my $attr ( @{ $type_attributes{$tt}[$index] } ) {
		$self->{$attr} = 1;
	}
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
