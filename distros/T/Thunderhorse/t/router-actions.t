use v5.40;
use Test2::V1 -ipP;

################################################################################
# This tests Router::Location action matching behavior
################################################################################

package TestApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		# Test exact scope and method match
		$router->add(
			'/exact' => {
				action => 'http.get',
			}
		);

		# Test wildcard method
		$router->add(
			'/wildcard-method' => {
				action => 'http.*',
			}
		);

		# Test wildcard scope
		$router->add(
			'/wildcard-scope' => {
				action => '*.post',
			}
		);

		# Test both wildcards
		$router->add(
			'/wildcard-both' => {
				action => '*.*',
			}
		);

		# Test scope only (implicit wildcard method)
		$router->add(
			'/scope-only' => {
				action => 'http',
			}
		);

		# Test no action (should match anything)
		$router->add(
			'/no-action' => {
			}
		);

		# Test multiple routes on same path with different actions
		$router->add(
			'/multi' => {
				action => 'HTTP.GET',
			}
		);

		$router->add(
			'/multi' => {
				action => 'http.post',
			}
		);

		$router->add(
			'/multi' => {
				action => 'ws',
			}
		);
	}
};

my $app = TestApp->new;
my $router = $app->router;

subtest 'should match exact scope and method' => sub {
	my $match = _get_match($router, '/exact', 'http.get');
	ok $match, 'route matched';

	my $no_match = _get_match($router, '/exact', 'http.post');
	is $no_match, undef, 'http.post did not match';

	$no_match = _get_match($router, '/exact', 'ws.get');
	is $no_match, undef, 'ws.get did not match';
};

subtest 'should match head with get' => sub {
	my $match = _get_match($router, '/exact', 'http.head');
	ok $match, 'route matched';
};

subtest 'should match wildcard method' => sub {
	my $match = _get_match($router, '/wildcard-method', 'http.get');
	ok $match, 'http.get matched';

	$match = _get_match($router, '/wildcard-method', 'http.post');
	ok $match, 'http.post matched';

	$match = _get_match($router, '/wildcard-method', 'http.delete');
	ok $match, 'http.delete matched';

	my $no_match = _get_match($router, '/wildcard-method', 'ws.connect');
	is $no_match, undef, 'ws.connect did not match';
};

subtest 'should match wildcard scope' => sub {
	my $match = _get_match($router, '/wildcard-scope', 'http.post');
	ok $match, 'http.post matched';

	$match = _get_match($router, '/wildcard-scope', 'ws.post');
	ok $match, 'ws.post matched';

	$match = _get_match($router, '/wildcard-scope', 'custom.post');
	ok $match, 'custom.post matched';

	my $no_match = _get_match($router, '/wildcard-scope', 'http.get');
	is $no_match, undef, 'http.get did not match';
};

subtest 'should match both wildcards' => sub {
	my $match = _get_match($router, '/wildcard-both', 'http.get');
	ok $match, 'http.get matched';

	$match = _get_match($router, '/wildcard-both', 'ws');
	ok $match, 'ws matched';

	$match = _get_match($router, '/wildcard-both', 'custom.action');
	ok $match, 'custom.action matched';
};

subtest 'should match scope only with implicit wildcard method' => sub {
	my $match = _get_match($router, '/scope-only', 'http.get');
	ok $match, 'http.get matched';

	$match = _get_match($router, '/scope-only', 'http.post');
	ok $match, 'http.post matched';

	$match = _get_match($router, '/scope-only', 'http.delete');
	ok $match, 'http.delete matched';

	my $no_match = _get_match($router, '/scope-only', 'ws.connect');
	is $no_match, undef, 'ws.connect did not match';
};

subtest 'should match no action (matches anything)' => sub {
	my $match = _get_match($router, '/no-action', 'http.get');
	ok $match, 'http.get matched';

	$match = _get_match($router, '/no-action', 'ws.connect');
	ok $match, 'ws.connect matched';

	$match = _get_match($router, '/no-action', 'anything.random');
	ok $match, 'anything.random matched';
};

subtest 'should match correct action on same path' => sub {
	my $match = _get_match($router, '/multi', 'http.get');
	is $match->location->action, 'HTTP.GET', 'http.get matched';

	$match = _get_match($router, '/multi', 'http.head');
	is $match->location->action, 'HTTP.GET', 'http.head matched';

	$match = _get_match($router, '/multi', 'http.post');
	is $match->location->action, 'http.post', 'http.post matched';

	$match = _get_match($router, '/multi', 'ws');
	is $match->location->action, 'ws', 'ws matched';

	my $no_match = _get_match($router, '/multi', 'http.delete');
	is $no_match, undef, 'http.delete did not match';
};

done_testing;

sub _get_match ($router, $path, $action)
{
	my @matches = $router->flat_match($path, $action);

	fail "multiple matches returned for $path"
		if @matches > 1;

	return $matches[0];
}

