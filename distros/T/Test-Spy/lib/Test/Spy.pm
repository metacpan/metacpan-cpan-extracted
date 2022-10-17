package Test::Spy;
$Test::Spy::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder;
use Util::H2O;
use Carp qw(croak);

use Test::Spy::Method;

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

	for my $method_name (keys %methods) {
		my $method = $methods{$method_name};
		$init_hash{$method_name} = sub {
			return $method->_called(@_);
		};
	}

	my $interface = $self->interface;
	if ($interface ne 'strict') {
		$init_hash{AUTOLOAD} = sub {
			our $AUTOLOAD;
			my $method = $AUTOLOAD;
			$method =~ m/(\w+)$/;

			warn "method '$1' was called on Test::Spy->object"
				if $interface eq 'warn';

			return undef;
		};
	}

	return h2o -meth, \%init_hash;
}

sub add_method
{
	my ($self, $method_name, @returns) = @_;

	$self->_clear_object;
	my $method = $self->_mocked_subs->{$method_name} = Test::Spy::Method->new(method_name => $method_name);

	if (@returns) {
		$method->should_return(@returns);
	}

	return $method;
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

