package Thunderhorse::Context::Facade;
$Thunderhorse::Context::Facade::VERSION = '0.102';
use v5.40;

use Mooish::Base -standard;

use Devel::StrictMode;

# use handles for fast access (autoloading is kind of slow)
has param 'context' => (
	(STRICT ? (isa => InstanceOf ['Thunderhorse::Context']) : ()),
	handles => [
		qw(
			app
			req
			res
		)
	],
);

with qw(Thunderhorse::Autoloadable);

sub _run_method ($self, $method, @args)
{
	die "no such method $method"
		unless ref $self;
	return $self->context->$method(@args);
}

sub _can_method ($self, $method)
{
	return $self->context->can($method);
}

