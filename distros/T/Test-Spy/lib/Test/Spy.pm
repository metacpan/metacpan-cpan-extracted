package Test::Spy;
$Test::Spy::VERSION = '0.005';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Carp qw(croak);

use Test::Spy::Method;
use Test::Spy::Observer;
use Test::Spy::Object;

has param 'interface' => (
	isa => sub {
		my @allowed = qw(strict lax warn);
		croak "interface can be any of: @allowed"
			unless grep { $_[0] eq $_ } @allowed;
	},
	default => sub { 'strict' }
);

has field '_mocked_subs' => (
	default => sub { {} },
);

has field 'object' => (
	lazy => 1,
	clearer => -hidden
);

has option 'context' => (
	writer => 1,
	clearer => 1,
);

has option 'base' => (
	writer => 1,
	trigger => '_clear_object',
);

has option 'imitates' => (
	writer => 1,
	trigger => '_clear_object',
);

with qw(Test::Spy::Interface);

sub _no_method
{
	my ($self, $method_name) = @_;

	croak "method $method_name was not mocked!";
}

sub _build_object
{
	my ($self) = @_;

	my %methods = %{$self->_mocked_subs};
	my %init_hash;

	my $base = $self->has_base
		? ref $self->base ? $self->base : $self->base->new
		: undef;

	return Test::Spy::Object->__new(
		%{$base // {}},
		__base => $base,
		__spy => $self,
	);
}

sub add_method
{
	my ($self, $method_name, @returns) = @_;

	my $method = $self->_mocked_subs->{$method_name} = Test::Spy::Method->new(method_name => $method_name);

	if (@returns) {
		$method->should_return(@returns);
	}

	return $method;
}

sub add_observer
{
	my ($self, $method_name) = @_;

	return $self->_mocked_subs->{$method_name} = Test::Spy::Observer->new(method_name => $method_name);
}

sub method
{
	my ($self, $method_name) = @_;

	return $self->_mocked_subs->{$method_name}
		// $self->_no_method($method_name);
}

sub clear_all
{
	my ($self) = @_;

	$self->clear_context;

	my %methods = %{$self->_mocked_subs};
	for my $method_name (keys %methods) {
		$methods{$method_name}->clear;
	}

	return;
}

sub call_history
{
	my ($self) = @_;

	my $context = $self->context;
	croak 'no context was set in ' . ref $self
		unless $self->has_context && $context;

	return $self->_mocked_subs->{$context}->call_history
		// $self->_no_method($context);
}

sub _clear_call_history
{
	my ($self) = @_;

	return $self->_mocked_subs->{$self->context}->_clear_call_history;
}

1;

# ABSTRACT: build mocked interfaces and examine call data easily

