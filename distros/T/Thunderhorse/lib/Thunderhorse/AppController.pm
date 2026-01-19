package Thunderhorse::AppController;
$Thunderhorse::AppController::VERSION = '0.102';
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
	# this returns app's can on purpose, to achieve app method being run by
	# controller object.
	return $self->app->can($method)
		// $self->SUPER::_can_method($method);
}

__END__

=head1 NAME

Thunderhorse::AppController - Controller for no controller scenarios

=head1 SYNOPSIS

	package MyApp;

	use v5.40;
	use Mooish::Base;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->router->add('/home' => {
			to => sub ($self, $ctx) {
				# $self is Thunderhorse::AppController
			}
		});
	}

=head1 DESCRIPTION

This is a subclass of L<Thunderhorse::Controller>, used when you declare
locations using router in the app class (not in a controller). It behaves the
same as regular controller, but also autoloads methods from your app instance.

While Thunderhorse can be used this way and completely skip declaring
controllers, it is recommended to set up a controller structure and keep all
routing in the controllers.

