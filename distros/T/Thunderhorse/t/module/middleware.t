use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use Future::AsyncAwait;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse Middleware module works
################################################################################

my @execution_order;

package TestMiddleware::First {
	use Mooish::Base -standard;

	has param 'marker' => (
		isa => Str,
		default => 'first',
	);

	sub wrap ($self, $app)
	{
		return async sub ($scope, $receive, $send) {
			push @execution_order, $self->marker . '-before';
			my $result = await $app->($scope, $receive, $send);
			push @execution_order, $self->marker . '-after';
			return $result;
		};
	}
}

package TestMiddleware::Second {
	use Mooish::Base -standard;

	has param 'marker' => (
		isa => Str,
		default => 'second',
	);

	sub wrap ($self, $app)
	{
		return async sub ($scope, $receive, $send) {
			push @execution_order, $self->marker . '-before';
			my $result = await $app->($scope, $receive, $send);
			push @execution_order, $self->marker . '-after';
			return $result;
		};
	}
}

package TestMiddleware::Third {
	use Mooish::Base -standard;

	has param 'marker' => (
		isa => Str,
		default => 'third',
	);

	sub wrap ($self, $app)
	{
		return async sub ($scope, $receive, $send) {
			push @execution_order, $self->marker . '-before';
			my $result = await $app->($scope, $receive, $send);
			push @execution_order, $self->marker . '-after';
			return $result;
		};
	}
}

package MiddlewareModuleApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_module(
			'Middleware' => {
				'^TestMiddleware::First' => {
					_order => 10,
					marker => 'mw1',
				},
				'^TestMiddleware::Second' => {
					_order => 20,
					marker => 'mw2',
				},
				'^TestMiddleware::Third' => {
					_order => 5,
					marker => 'mw3',
				},
			}
		);

		$self->router->add(
			'/test' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		push @execution_order, 'handler';
		return 'success';
	}
}

package AlphabeticalMiddlewareApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_module(
			'Middleware' => {
				'^TestMiddleware::Third' => {
					marker => 'c-third',
				},
				'^TestMiddleware::First' => {
					marker => 'a-first',
				},
				'^TestMiddleware::Second' => {
					marker => 'b-second',
				},
			}
		);

		$self->router->add(
			'/test' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		push @execution_order, 'handler';
		return 'alphabetical';
	}
}

package MixedOrderMiddlewareApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_module(
			'Middleware' => {
				'^TestMiddleware::First' => {
					_order => 100,
					marker => 'explicit-100',
				},
				'^TestMiddleware::Second' => {
					# no _order - defaults to 0
					marker => 'default-0',
				},
				'^TestMiddleware::Third' => {
					_order => 50,
					marker => 'explicit-50',
				},
			}
		);

		$self->router->add(
			'/test' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		push @execution_order, 'handler';
		return 'mixed';
	}
}

package PAGIMiddlewareApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_module(
			'Middleware' => {
				'ContentLength' => {
					_order => 10,
				},
				'^TestMiddleware::First' => {
					_order => 5,
					marker => 'custom',
				},
			}
		);

		$self->router->add(
			'/test' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		push @execution_order, 'handler';
		return 'test body';
	}
}

subtest 'should execute middleware in order based on order config' => sub {
	my $app = MiddlewareModuleApp->new;

	@execution_order = ();
	http $app, GET '/test';
	http_status_is 200;
	http_text_is 'success';

	# Order should be: mw3 (5), mw1 (10), mw2 (20), then handler, then unwinding
	is \@execution_order, [
		'mw3-before',
		'mw1-before',
		'mw2-before',
		'handler',
		'mw2-after',
		'mw1-after',
		'mw3-after',
		],
		'middleware executes in order by config, wrapping like onion';
};

subtest 'should execute middleware alphabetically when no order specified' => sub {
	my $app = AlphabeticalMiddlewareApp->new;

	@execution_order = ();
	http $app, GET '/test';
	http_status_is 200;
	http_text_is 'alphabetical';

	# Should be alphabetical by key name
	is \@execution_order, [
		'a-first-before',
		'b-second-before',
		'c-third-before',
		'handler',
		'c-third-after',
		'b-second-after',
		'a-first-after',
		],
		'middleware executes alphabetically when no order specified';
};

subtest 'should handle mixed order specifications correctly' => sub {
	my $app = MixedOrderMiddlewareApp->new;

	@execution_order = ();
	http $app, GET '/test';
	http_status_is 200;
	http_text_is 'mixed';

	# Order: default-0 (0), explicit-50 (50), explicit-100 (100)
	is \@execution_order, [
		'default-0-before',
		'explicit-50-before',
		'explicit-100-before',
		'handler',
		'explicit-100-after',
		'explicit-50-after',
		'default-0-after',
		],
		'middleware with default order (0) executes first, then by explicit order';
};

subtest 'should load PAGI::Middleware without prefix and execute in order' => sub {
	my $app = PAGIMiddlewareApp->new;

	@execution_order = ();
	http $app, GET '/test';
	http_status_is 200;
	http_header_is 'Content-Length', 9;
	http_text_is 'test body';

	# Custom middleware (order 5) should execute before ContentLength (order 10)
	is \@execution_order, [
		'custom-before',
		'handler',
		'custom-after',
		],
		'custom middleware executes in correct order';
};

done_testing;

