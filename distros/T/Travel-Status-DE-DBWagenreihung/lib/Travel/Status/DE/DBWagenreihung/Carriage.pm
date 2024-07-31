package Travel::Status::DE::DBWagenreihung::Carriage;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';
use Carp qw(cluck);

our $VERSION = '0.15';
Travel::Status::DE::DBWagenreihung::Carriage->mk_ro_accessors(
	qw(class_type is_closed is_dosto is_locomotive is_powercar
	  number model section uic_id type
	  start_meters end_meters length_meters start_percent end_percent length_percent
	)
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
	  = ( $pos->{start} - $platform->{start} ) * 100 / $platform_length,
	  $ref->{end_percent}
	  = ( $pos->{end} - $platform->{start} ) * 100 / $platform_length,
	  $ref->{length_meters} = $pos->{start} - $pos->{end};
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
