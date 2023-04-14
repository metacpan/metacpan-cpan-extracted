package Wikibase::Cache::Backend;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::Util qw(none);
use Readonly;

Readonly::Array our @TYPES => qw(description label);

our $VERSION = 0.03;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub get {
	my ($self, $type, $key) = @_;

	# Check type.
	$self->_check_type($type);

	return $self->_get($type, $key);
}

sub save {
	my ($self, $type, $key, $value) = @_;

	# Check type.
	$self->_check_type($type);

	return $self->_save($type, $key, $value);
}

sub _check_type {
	my ($self, $type) = @_;

	if (! defined $type) {
		err 'Type must be defined.';
	}
	if (none { $type eq $_ } @TYPES) {
		err "Type '$type' isn't supported.";
	}

	return;
}

sub _get {
	my $self = shift;

	err "This is abstract class. You need to implement '_get' method.";
}

sub _save {
	my $self = shift;

	err "This is abstract class. You need to implement '_save' method.";
}

1;
