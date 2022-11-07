package Test::Spy::Method;
$Test::Spy::Method::VERSION = '0.005';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Carp qw(croak);

has field '_throws' => (
	writer => 1,
	clearer => 1,
);

has field '_calls' => (
	writer => 1,
	clearer => 1,
);

has field '_returns' => (
	writer => 1,
	clearer => 1,
);

has field '_returns_list' => (
	writer => 1,
	clearer => 1,
);

extends 'Test::Spy::Observer';

sub _forget
{
	my ($self) = @_;

	$self->_clear_returns;
	$self->_clear_returns_list;
	$self->_clear_calls;
	$self->_clear_throws;

	return;
}

sub should_return
{
	my ($self, @values) = @_;

	$self->_forget;

	if (@values == 1) {
		$self->_set_returns($values[0]);
	}
	else {
		$self->_set_returns_list([@values]);
	}

	return $self->clear;
}

sub should_call
{
	my ($self, $sub) = @_;

	croak 'should_call expects a coderef'
		unless ref $sub eq 'CODE';

	$self->_forget;

	$self->_set_calls($sub);

	return $self->clear;
}

sub should_throw
{
	my ($self, $exception) = @_;

	$self->_forget;

	$self->_set_throws($exception);

	return $self->clear;
}

sub _called
{
	my ($self, $inner_self, @params) = @_;

	$self->SUPER::_called($inner_self, @params);

	die $self->_throws
		if defined $self->_throws;

	return $self->_calls->($inner_self, @params)
		if $self->_calls;

	return @{$self->_returns_list}
		if $self->_returns_list;

	return $self->_returns;
}

1;

