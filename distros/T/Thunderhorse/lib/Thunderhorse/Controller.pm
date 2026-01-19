package Thunderhorse::Controller;
$Thunderhorse::Controller::VERSION = '0.102';
use v5.40;
use Mooish::Base -standard;

use Thunderhorse::Context::Facade;
use URI;

extends 'Gears::Controller';
with 'Thunderhorse::Autoloadable';

has extended 'app' => (
	handles => [
		qw(
			loop
			config
		)
	],
);

sub make_facade ($self, $ctx)
{
	return Thunderhorse::Context::Facade->new(context => $ctx);
}

sub router ($self)
{
	my $router = $self->app->router;
	$router->set_controller($self);
	return $router;
}

sub _run_method ($self, $method, @args)
{
	die "no such method $method"
		unless ref $self;

	my $module_method = $self->app->extra_methods->{controller}{$method};

	die "no such method $method"
		unless $module_method;

	return $module_method->($self, @args);
}

sub _can_method ($self, $method)
{
	return $self->app->extra_methods->{controller}{$method};
}

sub url_for ($self, $name, @args)
{
	my $loc = $self->router->find($name);
	Gears::X::Thunderhorse->raise("no such route '$name'")
		unless defined $loc;

	return $loc->build(@args);
}

sub abs_url ($self, $url = '')
{
	return URI->new_abs(
		$url,
		$self->config->get('app_url', 'http://localhost:5000'),
	)->as_string;
}

sub abs_url_for ($self, $name, @args)
{
	return $self->abs_url($self->url_for($name, @args));
}

sub render_error ($self, $ctx, $code, $message = undef)
{
	$self->app->render_error($self, $ctx, $code, $message);
}

sub render_response ($self, $ctx, $result)
{
	$self->app->render_response($self, $ctx, $result);
}

#####################
### HOOKS SECTION ###
#####################

sub _on_error ($self, @args)
{
	$self->app->_fire_hooks(error => $self, @args);
	return $self->on_error(@args);
}

sub on_error ($self, $ctx, $error)
{
	return $self->app->on_error($self, $ctx, $error);
}

__END__

=head1 NAME

Thunderhorse::Controller - Base controller class for Thunderhorse

=head1 SYNOPSIS

	package MyApp::Controller::User;

	use v5.40;
	use Mooish::Base;

	extends 'Thunderhorse::Controller';

	sub build ($self)
	{
		$self->router->add('/user/:id' => { to => 'show' });
	}

	async sub show ($self, $ctx, $id)
	{
		await $ctx->res->text("User ID: $id");
	}

=head1 DESCRIPTION

Thunderhorse::Controller is the base controller class for Thunderhorse
applications. It extends L<Gears::Controller> and provides core functionality
for handling web requests, including routing, URL generation, and error
handling.

Controllers are automatically loaded by the application when defined in
configuration or loaded explicitly with L<Thunderhorse::App/load_controller>.

=head1 INTERFACE

Inherits all interface from L<Gears::Controller> and L<Gears::Component>, and
adds the interface documented below.

=head2 Attributes

No special attributes.

=head2 Methods

=head3 new

	$object = $class->new(%args)

Standard Mooish constructor. Consult L</Attributes> section for available
constructor arguments.

=head3 loop

Delegated method for L<Thunderhorse::App/loop>

=head3 config

Delegated method for L<Gears::App/config>

=head3 router

	$router = $self->router()

Returns the application router configured for this controller.

=head3 url_for

	$url = $self->url_for($name, @args)

Generates a URL for a route named C<$name>. C<@args> (usually a list of
key/value pairts) are passed to the route builder. Throws an exception if the
route does not exist.

=head3 abs_url

	$url = $self->abs_url($path = '')

Converts a relative path to an absolute URL using the C<app_url> configuration
value (C<https://localhost:5000> by default). C<$path> can be omitted and will
be treated as an empty string, returning the base absolute url of the
application.

=head3 abs_url_for

	$url = $self->abs_url_for($name, @args)

Convenience method which combines L</url_for> and L</abs_url> to generate an
absolute URL for a named route.

=head3 render_error

	$self->render_error($ctx, $code, $message = undef)

Renders an error response with the given HTTP status code. By default, it
delegates to the application's L<Thunderhorse::App/render_error> method.

=head3 render_response

	$self->render_response($ctx, $result)

Renders a response from C<$result>, which contains what was returned by the
handler. By default, it delegates to the application's
L<Thunderhorse::App/render_response> method.

=head3 on_error

	async sub on_error ($self, $ctx, $error) { ... }

Error hook called when an exception occurs during request processing. Can be
overridden to customize error handling.

=head1 SEE ALSO

L<Thunderhorse>, L<Gears::Controller>, L<Thunderhorse::App>

