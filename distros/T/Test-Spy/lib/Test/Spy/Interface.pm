package Test::Spy::Interface;
$Test::Spy::Interface::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo::Role;
use Mooish::AttributeBuilder;

requires qw(
	call_history
	_clear_call_history
);

has field '_call_iterator' => (
	writer => 1,
	clearer => 1,
	predicate => 1,
	lazy => sub { 0 },
);

sub _increment_call_iterator
{
	my ($self, $count) = @_;
	$count //= 1;

	$self->_set_call_iterator($self->_call_iterator + $count);

	return;
}

sub called_times
{
	my ($self) = @_;

	return scalar @{$self->call_history};
}

sub called_with
{
	my ($self) = @_;

	return $self->call_history->[$self->_call_iterator];
}

sub first_called_with
{
	my ($self) = @_;

	$self->_set_call_iterator(0);
	return $self->called_with;
}

sub next_called_with
{
	my ($self) = @_;

	$self->_increment_call_iterator
		if $self->_has_call_iterator;

	return $self->called_with;
}

sub last_called_with
{
	my ($self) = @_;

	$self->_set_call_iterator($self->called_times - 1);
	return $self->called_with;
}

sub was_called
{
	my ($self, $times) = @_;

	return $self->called_times == $times if defined $times;
	return $self->called_times > 0;
}

sub wasnt_called
{
	my ($self) = @_;

	return $self->was_called(0);
}

sub was_called_once
{
	my ($self) = @_;

	return $self->was_called(1);
}

sub clear
{
	my ($self) = @_;

	$self->_clear_call_history;
	$self->_clear_call_iterator;

	return $self;
}

1;

