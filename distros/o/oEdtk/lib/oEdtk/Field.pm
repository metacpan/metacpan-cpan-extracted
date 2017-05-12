package oEdtk::Field;

use strict;
use warnings;
our $VERSION		= 0.01;

sub new {
	my ($class, $name, $len) = @_;
	my $field = {
		name	=> $name,
		len	=> $len,
	};

	bless $field, $class;
	return $field;
}

sub process {
	my ($self, $data) = @_;

	return $data;
}

sub get_name {
	my ($self) = @_;

	return $self->{'name'};
}

sub set_name {
	my ($self, $name) = @_;

	$self->{'name'} = $name;
}

sub get_len {
	my ($self) = @_;

	return $self->{'len'};
}

1;
