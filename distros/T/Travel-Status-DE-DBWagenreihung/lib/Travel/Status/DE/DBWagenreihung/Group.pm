package Travel::Status::DE::DBWagenreihung::Group;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

our $VERSION = '0.14';

Travel::Status::DE::DBWagenreihung::Group->mk_ro_accessors(
	qw(id train_no type description desc_short origin destination has_sections)
);

sub new {
	my ( $obj, %opt ) = @_;
	my $ref = \%opt;

	return bless( $ref, $obj );
}

sub set_description {
	my ( $self, $desc, $short ) = @_;

	$self->{description} = $desc;
	$self->{desc_short}  = $short;
}

sub set_sections {
	my ( $self, @sections ) = @_;

	$self->{sections} = [@sections];

	$self->{has_sections} = 1;
}

sub set_traintype {
	my ( $self, $i, $tt ) = @_;
	$self->{type} = $tt;
	for my $wagon ( $self->wagons ) {
		$wagon->set_traintype( $i, $tt );
	}
}

sub sort_wagons {
	my ($self) = @_;

	@{ $self->{wagons} }
	  = sort { $a->{position}{start_percent} <=> $b->{position}{start_percent} }
	  @{ $self->{wagons} };
}

sub sections {
	my ($self) = @_;

	return @{ $self->{sections} // [] };
}

sub wagons {
	my ($self) = @_;

	return @{ $self->{wagons} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	my %copy = %{$self};

	return {%copy};
}

1;
