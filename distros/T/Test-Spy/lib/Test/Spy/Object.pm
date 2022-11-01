package Test::Spy::Object;
$Test::Spy::Object::VERSION = '0.004';
use v5.10;
use strict;
use warnings;

use Carp qw(croak carp);

our $AUTOLOAD;

sub can
{
	my ($self, $name) = @_;

	my $could = $self->SUPER::can($name);
	return $could if $could;

	return undef
		unless $self->{__spy}->_mocked_subs->{$name}
		|| ($self->{__base} && $self->{__base}->can($name));

	return sub { shift->$name(@_) };
}

sub isa
{
	my ($self, $name) = @_;

	return !!1
		if $self->SUPER::isa($name);

	return !!1
		if $self->{__base} && $self->{__base}->isa($name);

	return !!0;
}

sub DOES
{
	my ($self, $name) = @_;

	return !!1
		if $self->{__base} && $self->{__base}->DOES($name);

	return !!0;
}

sub AUTOLOAD
{
	my ($self, @args) = @_;

	my $method = $AUTOLOAD;
	$method =~ s/.*://;

	if (my $method = $self->{__spy}->_mocked_subs->{$method}) {
		# note: immediate return not to force any context
		if ($method->isa('Test::Spy::Method')) {
			return $method->_called($self, @args);
		}
		else {
			$method->_called($self, @args);
		}
	}

	if ($self->{__base} && (my $sref = $self->{__base}->can($method))) {
		return $sref->($self, @args);
	}

	my $interface = $self->{__spy}->interface;

	croak "No such method $method on Test::Spy->object"
		if $interface eq 'strict';

	carp "method '$1' was called on Test::Spy->object"
		if $interface eq 'warn';

	return undef;
}

sub _new
{
	my ($class, %params) = @_;
	my $self = \%params;

	return bless $self, $class;
}

sub DESTROY
{
}

1;

