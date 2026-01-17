use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse correctly modifies path and root_path when
# integrating PAGI apps
################################################################################

package PagiPathApp {
	use Mooish::Base -standard;

	use Future::AsyncAwait;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		# PAGI app that reports path and root_path
		my $reporter = async sub ($scope, $receive, $send) {
			my $path = $scope->{path};
			my $root_path = $scope->{root_path};

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
					body => "path=$path;root_path=$root_path",
				}
			);
		};

		# Simple path without trailing slash
		$router->add(
			'/app' => {
				to => $reporter,
				pagi => true,
			}
		);

		# Path with trailing slash
		$router->add(
			'/app_slash/' => {
				to => $reporter,
				pagi => true,
			}
		);

		# Nested path
		$router->add(
			'/nested/app' => {
				to => $reporter,
				pagi => true,
			}
		);

		# Nested path with trailing slash
		$router->add(
			'/nested/app_slash/' => {
				to => $reporter,
				pagi => true,
			}
		);

		# Deeply nested path
		$router->add(
			'/very/deeply/nested/app' => {
				to => $reporter,
				pagi => true,
			}
		);

		# With optional placeholder at the end
		$router->add(
			'/with/?opt' => {
				to => $reporter,
				pagi => true,
			}
		);

		# Multiple segments with optional placeholder
		$router->add(
			'/multi/segment/?opt' => {
				to => $reporter,
				pagi => true,
			}
		);

		# Root level
		$router->add(
			'/' => {
				to => $reporter,
				pagi => true,
			}
		);

		# slurpy at the end
		$router->add(
			'/slurpy/>rest' => {
				to => $reporter,
				pagi => true,
			}
		);
	}
};

my $app = PagiPathApp->new;

subtest 'should handle simple path without optional placeholder' => sub {
	http $app, GET '/app';
	http_status_is 200;
	like http->text, qr{^path=;root_path=/app$}, 'path and root_path ok';
};

subtest 'should handle path with trailing slash' => sub {
	http $app, GET '/app_slash/';
	http_status_is 200;
	like http->text, qr{^path=/;root_path=/app_slash$}, 'path and root_path ok';
};

subtest 'should handle nested path' => sub {
	http $app, GET '/nested/app';
	http_status_is 200;
	like http->text, qr{^path=;root_path=/nested/app$}, 'path and root_path ok';
};

subtest 'should handle nested path with trailing slash' => sub {
	http $app, GET '/nested/app_slash/';
	http_status_is 200;
	like http->text, qr{^path=/;root_path=/nested/app_slash$}, 'path and root_path ok';
};

subtest 'should handle deeply nested path' => sub {
	http $app, GET '/very/deeply/nested/app';
	http_status_is 200;
	like http->text, qr{^path=;root_path=/very/deeply/nested/app$}, 'path and root_path ok';
};

subtest 'should handle optional placeholder not provided' => sub {
	http $app, GET '/with/';
	http_status_is 200;
	like http->text, qr{^path=/;root_path=/with$}, 'path and root_path ok';
};

subtest 'should handle optional placeholder provided' => sub {
	http $app, GET '/with/test';
	http_status_is 200;
	like http->text, qr{^path=/test;root_path=/with$}, 'path and root_path ok';
};

subtest 'should handle optional placeholder in nested path not provided' => sub {
	http $app, GET '/multi/segment/';
	http_status_is 200;
	like http->text, qr{^path=/;root_path=/multi/segment$}, 'path and root_path ok';
};

subtest 'should handle optional placeholder in nested path provided' => sub {
	http $app, GET '/multi/segment/value';
	http_status_is 200;
	like http->text, qr{^path=/value;root_path=/multi/segment$}, 'path and root_path ok';
};

subtest 'should handle root level path' => sub {
	http $app, GET '/';
	http_status_is 200;
	like http->text, qr{^path=/;root_path=$}, 'path and root_path ok';
};

subtest 'should handle slurpy with no path' => sub {
	http $app, GET '/slurpy';
	http_status_is 200;
	like http->text, qr{^path=;root_path=/slurpy$}, 'path and root_path ok';
};

subtest 'should handle slurpy with trailing slash' => sub {
	http $app, GET '/slurpy/';
	http_status_is 200;
	like http->text, qr{^path=/;root_path=/slurpy$}, 'path and root_path ok';
};

subtest 'should handle slurpy path' => sub {
	http $app, GET '/slurpy/some/deep/path';
	http_status_is 200;
	like http->text, qr{^path=/some/deep/path;root_path=/slurpy$}, 'path and root_path ok';
};

done_testing;

