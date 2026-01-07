package Thunderhorse::AppController;
$Thunderhorse::AppController::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

extends 'Thunderhorse::Controller';

sub _run_method ($self, $method, @args)
{
	die "no such method $method"
		unless ref $self;

	if ($self->app->can($method)) {
		return $self->app->$method(@args);
	}

	return $self->SUPER::_run_method($method, @args);
}

sub _can_method ($self, $method)
{
	return $self->app->can($method)
		// $self->SUPER::_can_method($method);
}

