use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

use Future::AsyncAwait;

################################################################################
# This tests whether render_error and on_error hooks work correctly
################################################################################

package HooksApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	has field 'render_error_called' => (
		writer => 1,
		default => 0,
	);

	has field 'on_error_called' => (
		writer => 1,
		default => 0,
	);

	sub build ($self)
	{
		$self->load_controller('CustomHooks')
			->load_controller('Default');

		# route that uses app-level hooks
		$self->router->add(
			'/app-hook-exception' => {
				to => sub ($self, $ctx) {
					Gears::X::HTTP->raise(403, 'forbidden by app hook');
				}
			}
		);
	}

	async sub render_error ($self, $controller, $ctx, $code, $message = undef)
	{
		$self->set_render_error_called($self->render_error_called + 1);
		$message //= "app error: $code";
		await $ctx->res->status($code)->text($message);
	}

	async sub on_error ($self, $controller, $ctx, $error)
	{
		$self->set_on_error_called($self->on_error_called + 1);
		die $error unless $error isa 'Gears::X::HTTP';
		await +($controller // $self->controller)->render_error($ctx, $error->code, "app caught: " . $error->code);
	}
};

package HooksApp::Controller::CustomHooks {
	use Mooish::Base -standard;

	extends 'Thunderhorse::Controller';

	has field 'render_error_called' => (
		writer => 1,
		default => 0,
	);

	has field 'on_error_called' => (
		writer => 1,
		default => 0,
	);

	sub build ($self)
	{
		$self->router->add(
			'/custom-exception' => {
				to => 'throw_exception',
			}
		);

		$self->router->add(
			'/custom-not-found' => {
				to => 'call_not_found',
			}
		);
	}

	sub throw_exception ($self, $ctx)
	{
		Gears::X::HTTP->raise(418, "I'm a teapot");
	}

	sub call_not_found ($self, $ctx)
	{
		return $self->render_error($ctx, 404, 'custom not found');
	}

	async sub render_error ($self, $ctx, $code, $message = undef)
	{
		$self->set_render_error_called($self->render_error_called + 1);
		$message //= "custom error: $code";
		await $ctx->res->status($code)->text($message);
	}

	async sub on_error ($self, $ctx, $error)
	{
		$self->set_on_error_called($self->on_error_called + 1);
		die $error unless $error isa 'Gears::X::HTTP';
		await $self->render_error($ctx, $error->code, "custom caught: " . $error->code);
	}
}

package HooksApp::Controller::Default {
	use Mooish::Base -standard;

	extends 'Thunderhorse::Controller';

	sub build ($self)
	{
		$self->router->add(
			'/default-exception' => {
				to => 'throw_exception',
			}
		);
	}

	sub throw_exception ($self, $ctx)
	{
		Gears::X::HTTP->raise(401, 'unauthorized');
	}
}

subtest 'should use controller custom hooks for exceptions' => sub {
	my $app = HooksApp->new;
	http $app, GET '/custom-exception';
	http_status_is 418;
	http_text_is "custom caught: 418";

	_test_hooks($app, 1, 1, 0, 0);
};

subtest 'should use controller custom hooks for render_error' => sub {
	my $app = HooksApp->new;
	http $app, GET '/custom-not-found';
	http_status_is 404;
	http_text_is "custom not found";

	_test_hooks($app, 1, 0, 0, 0);
};

subtest 'should use app hooks for controller without custom hooks' => sub {
	my $app = HooksApp->new;
	http $app, GET '/default-exception';
	http_status_is 401;
	http_text_is "app caught: 401";

	_test_hooks($app, 0, 0, 1, 1);
};

subtest 'should use app hooks for app-level routes' => sub {
	my $app = HooksApp->new;
	http $app, GET '/app-hook-exception';
	http_status_is 403;
	http_text_is "app caught: 403";

	_test_hooks($app, 0, 0, 1, 1);
};

subtest 'should use app hooks for not found routes' => sub {
	my $app = HooksApp->new;
	http $app, GET '/nonexistent';
	http_status_is 404;
	http_text_is "app error: 404";

	_test_hooks($app, 0, 0, 1, 0);
};

done_testing;

sub _find_controller ($app, $class)
{
	foreach my $c ($app->controllers->@*) {
		return $c if $c isa $class;
	}

	die "Controller of class $class not found";
}

sub _test_hooks ($app, @values)
{
	my $controller = _find_controller($app, 'HooksApp::Controller::CustomHooks');

	is $controller->render_error_called, $values[0], 'controller render_error ok';
	is $controller->on_error_called, $values[1], 'controller on_error ok';
	is $app->render_error_called, $values[2], 'app render_error ok';
	is $app->on_error_called, $values[3], 'app on_error ok';
}

