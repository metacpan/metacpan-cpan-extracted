use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

use Future::AsyncAwait;

################################################################################
# This tests whether middleware can be applied to routes
################################################################################

my @order;

sub wrap_order_mw ($app, $name)
{
	return async sub (@args) {
		push @order, $name;
		return $app->(@args);
	};
}

package MiddlewareApp {
	use Mooish::Base -standard;
	use PAGI::Middleware::Builder;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		# Bridge with order middleware
		my $bridge = $router->add(
			'/with-middleware' => {
				to => sub ($self, $ctx) {
					push @order, 'bridge-handler';
					return;
				},
				pagi_middleware => sub ($app) {
					return main::wrap_order_mw($app, 'bridge-mw');
				},
			}
		);

		# Route under bridge with additional middleware
		$bridge->add(
			'/nested' => {
				to => sub ($self, $ctx) {
					push @order, 'nested-route';
					return 'nested route';
				},
				pagi_middleware => sub ($app) {
					return main::wrap_order_mw($app, 'nested-mw');
				},
			}
		);

		# Route under bridge with no extra middleware
		$bridge->add(
			'/inherited' => {
				to => sub ($self, $ctx) {
					push @order, 'inherited-route';
					return 'inherited route';
				},
			}
		);

		# Route outside bridge with no middleware
		$router->add(
			'/no-middleware' => {
				to => sub ($self, $ctx) {
					push @order, 'plain-route';
					return 'plain route';
				},
			}
		);

		# Route with ContentLength middleware using PAGI app
		$router->add(
			'/content-length' => {
				to => async sub ($scope, $receive, $send) {
					await $send->(
						{
							type => 'http.response.start',
							status => 200,
							headers => [['content-type', 'text/plain']],
						}
					);

					await $send->(
						{
							type => 'http.response.body',
							body => 'content length test',
						}
					);
				},
				pagi => true,
				pagi_middleware => sub ($app) {
					return builder {
						enable 'ContentLength';
						$app;
					};
				},
			}
		);
	}
};

my $app = MiddlewareApp->new;

subtest 'should execute bridge middleware before nested middleware and route' => sub {
	@order = ();
	http $app, GET '/with-middleware/nested';
	http_status_is 200;
	http_text_is 'nested route';

	is \@order, ['bridge-mw', 'bridge-handler', 'nested-mw', 'nested-route'],
		'middlewares execute in correct order';
};

subtest 'should execute bridge middleware before inherited route' => sub {
	@order = ();
	http $app, GET '/with-middleware/inherited';
	http_status_is 200;
	http_text_is 'inherited route';

	is \@order, ['bridge-mw', 'bridge-handler', 'inherited-route'],
		'bridge middleware executes before inherited route';
};

subtest 'should execute route with no middleware' => sub {
	@order = ();
	http $app, GET '/no-middleware';
	http_status_is 200;
	http_text_is 'plain route';

	is \@order, ['plain-route'], 'no middleware executed';
};

subtest 'should have ContentLength header' => sub {
	@order = ();
	http $app, GET '/content-length';
	http_status_is 200;
	http_header_is 'Content-Length', 19;
	http_text_is 'content length test';
};

done_testing;

