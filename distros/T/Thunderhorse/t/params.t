use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

use Future::AsyncAwait;

################################################################################
# This tests whether Thunderhorse correctly handles various parameters
################################################################################

package ParamsApp {
	use v5.40;
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		$router->add('/path1/:abc/:def' => {to => 'dump_path'});
		$router->add('/path2/:abc/:def' => {to => 'dump_path'})->add('/test');

		$router->add(
			'/get' => {
				to => sub ($self, $ctx) {
					my $get = $ctx->req->query_params;
					my @response;
					foreach my $key (sort keys $get->%*) {
						push @response, "${key}: " . join ', ', $get->get_all($key);
					}

					return join "\n", @response;
				}
			}
		);

		$router->add(
			'/post' => {
				to => async sub ($self, $ctx) {
					my $form = await $ctx->req->form;
					my @response;
					foreach my $key (sort keys $form->%*) {
						push @response, "${key}: " . join ', ', $form->get_all($key);
					}

					return join "\n", @response;
				}
			}
		);

		$router->add(
			'/headers' => {
				to => sub ($self, $ctx) {
					my $headers = $ctx->req->headers;
					my @response;
					foreach my $key (sort keys $headers->%*) {
						push @response, "${key}: " . join ', ', $headers->get_all($key);
					}

					return join "\n", @response;
				}
			}
		);
	}

	sub dump_path ($self, $ctx, @)
	{
		my $path = $ctx->req->path_params;
		my @response;
		foreach my $key (sort keys $path->%*) {
			push @response, "${key}: " . $ctx->req->path_param($key);
		}

		return join "\n", @response;
	}
};

my $app = ParamsApp->new;

subtest 'should handle path parameters' => sub {
	http $app, GET '/path1/one/two';
	http_status_is 200;
	like http->text, qr/^abc: one$/m, 'first param ok';
	like http->text, qr/^def: two$/m, 'second param ok';

	http $app, GET '/path2/three/four';
	http_status_is 200;
	like http->text, qr/^abc: three$/m, 'bridge first param ok';
	like http->text, qr/^def: four$/m, 'bridge second param ok';
};

subtest 'should handle single query parameter' => sub {
	http $app, GET '/get?foo=bar';
	http_status_is 200;
	like http->text, qr/^foo: bar$/m, 'body ok';
};

subtest 'should handle multiple query parameters' => sub {
	http $app, GET '/get?foo=bar&baz=qux';
	http_status_is 200;
	like http->text, qr/^foo: bar$/m, 'body ok';
	like http->text, qr/^baz: qux$/m, 'body ok';
};

subtest 'should handle query parameter with multiple values' => sub {
	http $app, GET '/get?foo=bar&foo=baz';
	http_status_is 200;
	like http->text, qr/^foo: bar, baz$/m, 'body ok';
};

subtest 'should handle single form parameter' => sub {
	http $app, POST '/post', [foo => 'bar'];
	http_status_is 200;
	like http->text, qr/^foo: bar$/m, 'body ok';
};

subtest 'should handle multiple form parameters' => sub {
	http $app, POST '/post', [foo => 'bar', baz => 'qux'];
	http_status_is 200;
	like http->text, qr/^foo: bar$/m, 'body ok';
	like http->text, qr/^baz: qux$/m, 'body ok';
};

subtest 'should handle form parameter with multiple values' => sub {
	http $app, POST '/post', [foo => 'bar', foo => 'baz'];
	http_status_is 200;
	like http->text, qr/^foo: bar, baz$/m, 'body ok';
};

subtest 'should handle custom headers' => sub {
	http $app, GET '/headers', 'x-custom-header' => 'test-value';
	http_status_is 200;
	like http->text, qr/^x-custom-header: test-value$/m, 'body ok';
};

subtest 'should handle multiple header values' => sub {
	http $app, GET '/headers', 'x-multi' => 'value1', 'x-multi' => 'value2';
	http_status_is 200;
	like http->text, qr/^x-multi: value1, value2$/m, 'body ok';
};

subtest 'should handle headers together with form' => sub {
	http $app, POST '/headers', [foo => 'bar'], 'x-multi' => 'value';
	http_status_is 200;
	like http->text, qr/^x-multi: value$/m, 'body ok';

	http $app, POST '/post', [foo => 'bar'], 'x-multi' => 'value';
	http_status_is 200;
	like http->text, qr/^foo: bar$/m, 'body ok';
};

done_testing;

