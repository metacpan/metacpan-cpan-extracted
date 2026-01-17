use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether facades work correctly
################################################################################

package FacadeApp::Controller::Test::Facade {
	use Mooish::Base -standard;
	use Future::AsyncAwait;

	extends 'Thunderhorse::Context::Facade';

	async sub send_something_later ($self)
	{
		await $self->app->loop->delay_future(after => 0.5);
		await $self->res->text('Something');
	}
}

package FacadeApp::Controller::Test {
	use Mooish::Base -standard;
	use Future::AsyncAwait;

	extends 'Thunderhorse::Controller';

	sub make_facade ($self, $ctx)
	{
		return FacadeApp::Controller::Test::Facade->new(context => $ctx);
	}

	sub build ($self)
	{
		my $router = $self->router;

		# this is good, because it does await - $ctx will no longer have
		# references
		$router->add(
			'/good' => {
				to => async sub ($self, $ctx) {
					await $ctx->send_something_later;
					return;
				}
			}
		);

		# this is bad, because it consumes the context explicitly but does not
		# await. This behavior is wrong on PAGI level, which forces fully
		# rendered response before server finishes handling the app
		$router->add(
			'/consumed' => {
				to => async sub ($self, $ctx) {
					$ctx->consume;
					$ctx->send_something_later;
				}
			}
		);

		# this is bad, because it does not await - $ctx will have references
		# and Thunderhorse will raise an exception
		$router->add(
			'/bad' => {
				to => async sub ($self, $ctx) {
					$ctx->send_something_later;
					return;
				}
			}
		);
	}
}

package FacadeApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_controller('Test');
	}
}

my $app = FacadeApp->new;

subtest 'should render /good' => sub {
	http $app, GET '/good';
	http_status_is 200;
	http_header_is 'Content-Type', 'text/plain; charset=utf-8';
	http_text_is 'Something';
};

subtest 'should not render /consumed' => sub {
	like dies {
		http $app, GET '/consumed';
	}, qr/\QDid you forget to 'await'\E/, 'exception ok';
};

subtest 'should not render /bad' => sub {
	http $app, GET '/bad';
	http_status_is 500;
	like http->text, qr/\Qforgot await?\E/, 'exception ok';
};

done_testing;

