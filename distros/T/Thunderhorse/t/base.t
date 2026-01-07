use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;
use Path::Tiny qw(cwd);

use Future::AsyncAwait;

################################################################################
# This tests whether Thunderhorse basic app works
################################################################################

package BasicApp {
	use Mooish::Base -standard;

	use Gears::X::HTTP;

	extends 'Thunderhorse::App';

	has field 'events' => (
		default => sub { {} },
	);

	sub build ($self)
	{
		my $router = $self->router;

		$router->add(
			'/foundation/:ph' => {
				to => sub ($self, $ctx, $ph) {
					my $self_class = ref $self;
					my $ctx_class = ref $ctx;

					return "$self_class;$ctx_class;$ph";
				}
			}
		);

		$router->add(
			'/send' => {
				to => sub ($self, $ctx) {
					$ctx->res->text('this gets rendered');
					return 'this does not get rendered';
				}
			}
		);

		$router->add(
			'/preset_headers/?ex_code' => {
				to => sub ($self, $ctx, $code) {
					$ctx->res->status(201)->content_type('application/xml');
					Gears::X::HTTP->raise($code, 'test')
						if $code;

					return 'this gets rendered as xml';
				}
			}
		);

		my $bridge = $router->add(
			'/bridge/:must_be_zero' => {
				to => sub ($self, $ctx, $must_be_zero) {
					Gears::X::HTTP->raise(403 => 'this exception renders 403, but this message is private')
						unless $must_be_zero eq '0';

					return undef;
				}
			}
		);

		$bridge->add(
			'/success' => {
				to => sub ($self, $ctx, $) {
					return 'bridge passed';
				},
			}
		);

		my $bridge_unimplemented = $router->add('/bridge2');

		$bridge_unimplemented->add(
			'/success' => {
				to => sub ($self, $ctx) {
					return 'bridge passed';
				},
			},
		);
	}

	async sub on_startup ($self, $state)
	{
		$self->events->{startup} = true;
		$state->{th_started} = true;
	}

	async sub on_shutdown ($self, $state)
	{
		$self->events->{shutdown} = true;
		$state->{th_stopped} = true;
	}
};

my $app = BasicApp->new;

is $app->path->stringify, cwd->child('t')->stringify, 'application path ok';

subtest 'should handle lifespan events' => sub {
	my $state = pagi_run $app, sub { };

	ok $app->events->{startup}, 'startup ok';
	ok $app->events->{shutdown}, 'shutdown ok';

	# TODO: PAGI::Middleware uses wrong state
	# ok $state->{th_started}, 'startup hook ok';
	# ok $state->{th_stopped}, 'shutdown hook ok';
};

subtest 'should route to a valid location' => sub {
	http $app, GET '/foundation/placeholder';
	http_status_is 200;
	http_header_is 'content-type', 'text/html; charset=utf-8';
	http_text_is 'Thunderhorse::AppController;Thunderhorse::Context::Facade;placeholder';
};

subtest 'should route to 404' => sub {
	http $app, GET '/foundation';
	http_status_is 404;
	http_header_is 'Content-Type', 'text/plain; charset=utf-8';
	http_text_is 'Not Found';
};

subtest 'should render text set by res->text' => sub {
	http $app, GET '/send';
	http_status_is 200;
	http_header_is 'Content-Type', 'text/plain; charset=utf-8';
	http_text_is 'this gets rendered';
};

subtest 'should render without overriding set headers' => sub {
	http $app, GET '/preset_headers';
	http_status_is 201;
	http_header_is 'content-type', 'application/xml; charset=utf-8';
	http_text_is 'this gets rendered as xml';
};

subtest 'should override headers when an exception is thrown' => sub {
	http $app, GET '/preset_headers/403';
	http_status_is 403;
	http_header_is 'content-type', 'text/plain; charset=utf-8';
	http_text_is 'Forbidden';
};

subtest 'should pass bridge and reach success route' => sub {
	http $app, GET '/bridge/0/success';
	http_status_is 200;
	http_header_is 'Content-Type', 'text/html; charset=utf-8';
	http_text_is 'bridge passed';
};

subtest 'should fail bridge and return 403' => sub {
	http $app, GET '/bridge/1/success';
	http_status_is 403;
	http_header_is 'Content-Type', 'text/plain; charset=utf-8';
	http_text_is('Forbidden');
};

subtest 'should pass unimplemented bridge' => sub {
	http $app, GET '/bridge2/success';
	http_status_is 200;
	http_header_is 'Content-Type', 'text/html; charset=utf-8';
	http_text_is 'bridge passed';
};

done_testing;

